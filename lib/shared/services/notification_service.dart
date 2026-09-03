import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// NotificationService managing local alarms and critical triggers (PRD Section 12)
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  /// Sends a local notification immediately
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ridecare_maintenance_channel',
      'Pengingat Perawatan RideCare',
      channelDescription: 'Notifikasi status suku cadang dan interval servis',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(id, title, body, details);
  }
}
