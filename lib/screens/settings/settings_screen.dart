import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../../providers/location_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_navbar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final locationState = ref.watch(locationPermissionProvider);

    return Scaffold(
      appBar: const AppBarWidget(title: 'Settings'),
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppNavBar(currentIndex: 4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.settings,
                    size: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IbadahMate Settings',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Customize your spiritual journey',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Theme Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Appearance',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Dark Mode',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text('Switch between light and dark themes'),
                        value: isDarkMode,
                        onChanged: (value) {
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Location & Permissions Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Location & Permissions',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Location Permission Status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getLocationStatusColor(locationState).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getLocationStatusColor(locationState).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getLocationStatusIcon(locationState),
                                color: _getLocationStatusColor(locationState),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getLocationStatusTitle(locationState),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _getLocationStatusColor(locationState),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getLocationStatusSubtitle(locationState),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildLocationActions(context, ref, locationState),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Info about why location is needed
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Location is needed for accurate prayer times and Qibla direction',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Prayer Settings Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Prayer Settings',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSettingTile(
                      context,
                      icon: Icons.notifications,
                      title: 'Prayer Notifications',
                      subtitle: 'Get reminded for prayer times',
                      value: true,
                      onChanged: (value) {
                        // TODO: Implement notification toggle
                      },
                    ),
                    const Divider(),
                    _buildSettingTile(
                      context,
                      icon: Icons.volume_up,
                      title: 'Adhan Notifications',
                      subtitle: 'Play Adhan for prayer times',
                      value: false,
                      onChanged: (value) {
                        // TODO: Implement Adhan toggle
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // About Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'About IbadahMate',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInfoTile(
                      context,
                      icon: Icons.verified,
                      title: 'Version',
                      value: '1.0.0',
                    ),
                    const Divider(),
                    _buildInfoTile(
                      context,
                      icon: Icons.email,
                      title: 'Contact',
                      value: 'support@ibadahmate.com',
                    ),
                    const Divider(),
                    _buildInfoTile(
                      context,
                      icon: Icons.favorite,
                      title: 'Made with',
                      value: 'Love for the Ummah',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationActions(BuildContext context, WidgetRef ref, LocationPermissionState state) {
    switch (state) {
      case LocationPermissionState.granted:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final position = await ref.read(locationPermissionProvider.notifier).getCurrentPosition();
                  if (context.mounted && position != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.my_location),
                label: const Text('Get Current Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
      
      case LocationPermissionState.denied:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(locationPermissionProvider.notifier).requestPermission();
                },
                icon: const Icon(Icons.location_searching),
                label: const Text('Grant Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
      
      case LocationPermissionState.deniedForever:
      case LocationPermissionState.serviceDisabled:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(locationPermissionProvider.notifier).openLocationSettings();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(locationPermissionProvider.notifier).openAppSettings();
                },
                icon: const Icon(Icons.app_settings_alt),
                label: const Text('App Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
          ],
        );
      
      case LocationPermissionState.unknown:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(locationPermissionProvider.notifier).requestPermission();
                },
                icon: const Icon(Icons.location_searching),
                label: const Text('Check Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
    }
  }

  Color _getLocationStatusColor(LocationPermissionState state) {
    switch (state) {
      case LocationPermissionState.granted:
        return Colors.green;
      case LocationPermissionState.denied:
        return Colors.orange;
      case LocationPermissionState.deniedForever:
      case LocationPermissionState.serviceDisabled:
        return Colors.red;
      case LocationPermissionState.unknown:
        return Colors.grey;
    }
  }

  IconData _getLocationStatusIcon(LocationPermissionState state) {
    switch (state) {
      case LocationPermissionState.granted:
        return Icons.location_on;
      case LocationPermissionState.denied:
        return Icons.location_disabled;
      case LocationPermissionState.deniedForever:
      case LocationPermissionState.serviceDisabled:
        return Icons.location_off;
      case LocationPermissionState.unknown:
        return Icons.location_searching;
    }
  }

  String _getLocationStatusTitle(LocationPermissionState state) {
    switch (state) {
      case LocationPermissionState.granted:
        return 'Location Enabled';
      case LocationPermissionState.denied:
        return 'Permission Denied';
      case LocationPermissionState.deniedForever:
        return 'Permission Blocked';
      case LocationPermissionState.serviceDisabled:
        return 'Location Services Off';
      case LocationPermissionState.unknown:
        return 'Location Status Unknown';
    }
  }

  String _getLocationStatusSubtitle(LocationPermissionState state) {
    switch (state) {
      case LocationPermissionState.granted:
        return 'Your location is available for prayer times and Qibla';
      case LocationPermissionState.denied:
        return 'Location permission was denied. Tap to grant.';
      case LocationPermissionState.deniedForever:
        return 'Permission is permanently denied. Open settings to enable.';
      case LocationPermissionState.serviceDisabled:
        return 'Location services are disabled. Enable in settings.';
      case LocationPermissionState.unknown:
        return 'Tap to check location permission status.';
    }
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.accent,
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
