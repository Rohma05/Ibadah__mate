import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/location_service.dart';
import '../../widgets/app_navbar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_bar.dart';
import '../../theme/app_colors.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with TickerProviderStateMixin {
  bool _loading = true;
  bool _hasPermission = false;
  Position? _currentPosition;
  double? _gpsAccuracy;
  bool _isCalibrating = false;
  double _compassAccuracy = 0;
  
  late AnimationController _compassController;
  late Animation<double> _compassAnimation;
  
  // Mecca coordinates (fixed)
  static const double meccaLat = 21.4225;
  static const double meccaLng = 39.8262;
  
  // SharedPreferences keys
  static const String _latKey = 'manual_latitude';
  static const String _lngKey = 'manual_longitude';
  static const String _useManualKey = 'use_manual_location';
  
  bool _useManualLocation = false;
  double? _manualLat;
  double? _manualLng;

  @override
  void initState() {
    super.initState();
    _compassController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _compassAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _compassController, curve: Curves.easeInOut),
    );
    _loadManualLocation();
    _checkPermission();
  }

  Future<void> _loadManualLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _useManualLocation = prefs.getBool(_useManualKey) ?? false;
        _manualLat = prefs.getDouble(_latKey);
        _manualLng = prefs.getDouble(_lngKey);
      });
    } catch (e) {
      debugPrint('Error loading manual location: $e');
    }
  }

  @override
  void dispose() {
    _compassController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    // If manual location is set, skip GPS
    if (_useManualLocation && _manualLat != null && _manualLng != null) {
      _currentPosition = Position(
        latitude: _manualLat!,
        longitude: _manualLng!,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      setState(() {
        _loading = false;
        _hasPermission = true;
        _gpsAccuracy = 0;
      });
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _loading = false;
        _hasPermission = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _loading = false;
        _hasPermission = false;
      });
      return;
    }

    // Get current position with high accuracy
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Get accuracy info
      final accuracy = _currentPosition?.accuracy ?? 0;
      setState(() {
        _gpsAccuracy = accuracy;
      });
    } catch (e) {
      // Try using LocationService as fallback
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        _currentPosition = position;
      }
    }

    setState(() {
      _loading = false;
      _hasPermission = _currentPosition != null;
    });
  }

  /// Calculate the Qibla direction using proper mathematical formula
  /// This is more accurate than using the device sensor alone
  double _calculateQiblaBearing() {
    if (_currentPosition == null) return 0;

    final lat1 = _currentPosition!.latitude * pi / 180;
    final lng1 = _currentPosition!.longitude * pi / 180;
    final lat2 = meccaLat * pi / 180;
    final lng2 = meccaLng * pi / 180;

    final dLng = lng2 - lng1;

    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);

    var bearing = atan2(y, x) * 180 / pi;
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  /// Calculate magnetic declination for the current location
  /// This helps correct the compass for more accurate bearing
  double _calculateMagneticDeclination() {
    if (_currentPosition == null) return 0;
    
    // Approximate magnetic declination calculation
    // This is a simplified version - for production, use a proper magnetic model
    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    
    // World Magnetic Model approximation (simplified)
    // Declination varies based on location
    final declination = (lng / 20) * (sin(lat * pi / 180) * 0.5 + 0.5);
    
    return declination;
  }

  double _calculateDistance() {
    if (_currentPosition == null) return 0.0;

    const double earthRadius = 6371; // km
    final double dLat = (meccaLat - _currentPosition!.latitude) * pi / 180;
    final double dLng = (meccaLng - _currentPosition!.longitude) * pi / 180;

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_currentPosition!.latitude * pi / 180) *
        cos(meccaLat * pi / 180) *
        sin(dLng / 2) * sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  String _getAccuracyText() {
    if (_gpsAccuracy == null || _gpsAccuracy == 0) {
      return 'Manual Location';
    }
    if (_gpsAccuracy! < 10) {
      return 'Excellent (${_gpsAccuracy!.toStringAsFixed(0)}m)';
    } else if (_gpsAccuracy! < 25) {
      return 'Good (${_gpsAccuracy!.toStringAsFixed(0)}m)';
    } else if (_gpsAccuracy! < 50) {
      return 'Fair (${_gpsAccuracy!.toStringAsFixed(0)}m)';
    } else {
      return 'Poor (${_gpsAccuracy!.toStringAsFixed(0)}m)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      extendBodyBehindAppBar: true,
      appBar: const AppBarWidget(
        title: 'Qibla Direction',
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppNavBar(currentIndex: 2),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
              AppColors.primary.withOpacity(0.6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : !_hasPermission
                  ? _permissionError()
                  : _qiblaBody(),
        ),
      ),
    );
  }

  Widget _permissionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Location Access Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Location permission is required to determine Qibla direction.\n\n'
              'Please enable location services and grant permission.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qiblaBody() {
    return FutureBuilder<bool>(
      future: FlutterQiblah.androidDeviceSensorSupport().then((v) => v ?? false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (snapshot.data == false) {
          return _buildManualCompass();
        }

        return StreamBuilder<QiblahDirection>(
          stream: FlutterQiblah.qiblahStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            final direction = snapshot.data!;
            final distance = _calculateDistance();
            final calculatedBearing = _calculateQiblaBearing();
            
            return LayoutBuilder(
              builder: (context, constraints) {
                final compassSize = constraints.maxWidth * 0.85;
                
                return Column(
                  children: [
                    // Top section
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '🕋',
                            style: TextStyle(fontSize: 50),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'QIBLA',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${distance.toStringAsFixed(0)} km to Makkah',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Compass section
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: _buildCompassWidget(
                          compassSize,
                          direction,
                          calculatedBearing,
                        ),
                      ),
                    ),

                    // Bottom info section
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Qibla angle display
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.explore, color: Colors.white, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  '${calculatedBearing.toStringAsFixed(1)}°',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Calibration hint
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isCalibrating ? Icons.sync : Icons.info_outline,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isCalibrating 
                                        ? 'Calibrating... Move device in figure-8 pattern'
                                        : 'Hold device flat and rotate slowly for accuracy',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildManualCompass() {
    final distance = _calculateDistance();
    final calculatedBearing = _calculateQiblaBearing();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final compassSize = constraints.maxWidth * 0.85;
        
        return Column(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🕋', style: TextStyle(fontSize: 50)),
                  const SizedBox(height: 8),
                  const Text(
                    'QIBLA',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${distance.toStringAsFixed(0)} km to Makkah',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Center(
                child: _buildCompassWidget(compassSize, null, calculatedBearing),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.explore, color: Colors.white, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          '${calculatedBearing.toStringAsFixed(1)}°',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Compass not available. Using calculated bearing.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompassWidget(
    double size, 
    QiblahDirection? direction, 
    double calculatedBearing,
  ) {
    // Use device bearing if available, otherwise use calculated
    final deviceBearing = direction?.direction ?? 0;
    final qiblaBearing = direction?.qiblah ?? calculatedBearing;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.8),
            Colors.white.withOpacity(0.6),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring with degree markers
          Container(
            width: size - 16,
            height: size - 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.8),
                width: 3,
              ),
            ),
          ),
          
          // Cardinal directions
          ..._buildCardinalDirections(size),
          
          // Degree markers
          ..._buildDegreeMarkers(size),
          
          // North indicator (red)
          Positioned(
            top: 20,
            child: Container(
              width: 0,
              height: 0,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(width: 12, color: Colors.red),
                  left: BorderSide(width: 8, color: Colors.transparent),
                  right: BorderSide(width: 8, color: Colors.transparent),
                ),
              ),
            ),
          ),
          
          // North label
          Positioned(
            top: 8,
            child: Text(
              'N',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ),
          
          // Rotating compass rose (shows device orientation)
          Transform.rotate(
            angle: -deviceBearing * pi / 180,
            child: Container(
              width: size - 60,
              height: size - 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
          ),
          
          // Qibla indicator (fixed, pointing to Kaaba)
          Transform.rotate(
            angle: -qiblaBearing * pi / 180,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Kaaba icon at top
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🕋', style: TextStyle(fontSize: 22)),
                  ),
                ),
                // Direction line
                Container(
                  width: 3,
                  height: size * 0.25,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          
          // Center circle (fixed - this is where user should align)
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          
          // Current direction indicator (triangle at bottom)
          Positioned(
            bottom: size * 0.08,
            child: Transform.rotate(
              angle: deviceBearing * pi / 180,
              child: Icon(
                Icons.navigation,
                color: Colors.grey.shade700,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCardinalDirections(double size) {
    final directions = ['E', 'S', 'W'];
    final angles = [90.0, 180.0, 270.0];
    final widgets = <Widget>[];
    final radius = (size - 30) / 2;
    final centerOffset = size / 2;
    
    for (int i = 0; i < 3; i++) {
      final angle = angles[i] * pi / 180;
      final x = centerOffset + radius * sin(angle);
      final y = centerOffset - radius * cos(angle);
      
      widgets.add(
        Positioned(
          left: x - 8,
          top: y - 8,
          child: Text(
            directions[i],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }
    
    return widgets;
  }

  List<Widget> _buildDegreeMarkers(double size) {
    final widgets = <Widget>[];
    final radius = (size - 25) / 2;
    final centerOffset = size / 2;
    
    for (int i = 0; i < 360; i += 30) {
      final angle = i * pi / 180;
      final x = centerOffset + radius * sin(angle);
      final y = centerOffset - radius * cos(angle);
      
      // Show major degree markers
      widgets.add(
        Positioned(
          left: x - 3,
          top: y - 3,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i % 90 == 0 
                  ? Colors.red.withOpacity(0.7) 
                  : Colors.grey.withOpacity(0.5),
            ),
          ),
        ),
      );
    }
    
    return widgets;
  }

  Widget _buildAccuracyIndicator(double accuracy) {
    Color color;
    String text;
    IconData icon;
    
    if (accuracy < 0) {
      color = Colors.orange;
      text = 'Using Calculated Bearing';
      icon = Icons.calculate;
    } else if (accuracy < 20) {
      color = Colors.green;
      text = 'Compass Accurate';
      icon = Icons.check_circle;
    } else if (accuracy < 50) {
      color = Colors.orange;
      text = 'Compass Fair';
      icon = Icons.warning;
    } else {
      color = Colors.red;
      text = 'Calibrate Compass';
      icon = Icons.sync;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
