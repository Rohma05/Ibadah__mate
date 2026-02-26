import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Provider for prayer notifications enabled state
final prayerNotificationEnabledProvider = NotifierProvider<PrayerNotificationNotifier, bool>(() {
  return PrayerNotificationNotifier();
});

// Provider for adhan notifications enabled state
final adhanNotificationEnabledProvider = NotifierProvider<AdhanNotificationNotifier, bool>(() {
  return AdhanNotificationNotifier();
});

class PrayerNotificationNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadNotificationState();
    return true;
  }

  Future<void> _loadNotificationState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('prayerNotificationEnabled') ?? true;
  }

  Future<void> togglePrayerNotification() async {
    final prefs = await SharedPreferences.getInstance();
    state = !state;
    await prefs.setBool('prayerNotificationEnabled', state);
    
    final notificationService = ref.read(notificationServiceProvider);
    if (state) {
      await notificationService.subscribeToPrayerAlerts();
    } else {
      await notificationService.unsubscribeFromPrayerAlerts();
    }
  }

  Future<void> setPrayerNotification(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    state = enabled;
    await prefs.setBool('prayerNotificationEnabled', enabled);
    
    final notificationService = ref.read(notificationServiceProvider);
    if (enabled) {
      await notificationService.subscribeToPrayerAlerts();
    } else {
      await notificationService.unsubscribeFromPrayerAlerts();
    }
  }
}

class AdhanNotificationNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadAdhanState();
    return false;
  }

  Future<void> _loadAdhanState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('adhanNotificationEnabled') ?? false;
  }

  Future<void> toggleAdhanNotification() async {
    final prefs = await SharedPreferences.getInstance();
    state = !state;
    await prefs.setBool('adhanNotificationEnabled', state);
  }

  Future<void> setAdhanNotification(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    state = enabled;
    await prefs.setBool('adhanNotificationEnabled', enabled);
  }
}
