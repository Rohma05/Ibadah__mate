import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Notification channels for Android
  static const String prayerChannelId = 'prayer_notifications';
  static const String prayerChannelName = 'Prayer Notifications';
  static const String prayerChannelDesc = 'Notifications for prayer times';

  static const String adhanChannelId = 'adhan_notifications';
  static const String adhanChannelName = 'Adhan Notifications';
  static const String adhanChannelDesc = 'Play Adhan for prayer times';

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Request notification permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Initialize Firebase Messaging
    await _initializeFirebaseMessaging();

    _isInitialized = true;
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    // Request notification permission
    final status = await Permission.notification.request();
    
    if (status.isGranted) {
      // Also request precise location for prayer times (if not already granted)
      await Permission.locationWhenInUse.request();
      return true;
    }
    
    return false;
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Prayer notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          prayerChannelId,
          prayerChannelName,
          description: prayerChannelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Adhan notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          adhanChannelId,
          adhanChannelName,
          description: adhanChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  /// Initialize Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      // Log token for debugging
      print('FCM Token: $token');
      // TODO: Send token to server for push notifications
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Check if app was opened from terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleInitialMessage(initialMessage);
    }

    // Subscribe to prayer topics
    await subscribeToPrayerAlerts();
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? 'IbadahMate',
        body: notification.body ?? 'You have a new notification',
        channelId: prayerChannelId,
        channelName: prayerChannelName,
      );
    }
  }

  /// Handle initial message (when app is launched from notification)
  void _handleInitialMessage(RemoteMessage message) {
    // Handle the notification data
    print('Initial message: ${message.data}');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to appropriate screen
    print('Notification tapped: ${response.payload}');
  }

  /// Handle when app is opened from notification
  void _onMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.data}');
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// Subscribe to prayer alerts topic
  Future<void> subscribeToPrayerAlerts() async {
    await _firebaseMessaging.subscribeToTopic('prayer_alerts');
  }

  /// Unsubscribe from prayer alerts topic
  Future<void> unsubscribeFromPrayerAlerts() async {
    await _firebaseMessaging.unsubscribeFromTopic('prayer_alerts');
  }

  /// Schedule a prayer time notification
  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required int hour,
    required int minute,
  }) async {
    // Cancel existing notification with same ID
    await _localNotifications.cancel(id);

    // Create notification details
    final androidDetails = AndroidNotificationDetails(
      prayerChannelId,
      prayerChannelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule daily notification
    await _localNotifications.zonedSchedule(
      id,
      'Time for $prayerName',
      'It is time to perform $prayerName prayer',
      _nextInstanceOfTime(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Calculate next instance of specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Get FCM token
  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Open notification settings
  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }
}
