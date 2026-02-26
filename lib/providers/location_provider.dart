import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Location permission state
enum LocationPermissionState {
  unknown,
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// Provider to track location permission status
final locationPermissionProvider = NotifierProvider<LocationPermissionNotifier, LocationPermissionState>(() {
  return LocationPermissionNotifier();
});

class LocationPermissionNotifier extends Notifier<LocationPermissionState> {
  @override
  LocationPermissionState build() {
    _checkPermission();
    return LocationPermissionState.unknown;
  }

  Future<void> _checkPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = LocationPermissionState.serviceDisabled;
      return;
    }

    final permission = await Geolocator.checkPermission();
    state = _mapPermission(permission);
  }

  LocationPermissionState _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionState.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionState.deniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationPermissionState.granted;
      case LocationPermission.unableToDetermine:
        return LocationPermissionState.unknown;
    }
  }

  Future<void> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = LocationPermissionState.serviceDisabled;
      return;
    }

    final permission = await Geolocator.requestPermission();
    state = _mapPermission(permission);
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<Position?> getCurrentPosition() async {
    if (state != LocationPermissionState.granted) {
      return null;
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
