import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

/// Service for managing daily check-in reminders via local notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Callback for when a notification is tapped.
  /// Set this from main.dart to handle navigation.
  VoidCallback? onNotificationTapped;

  /// Initialize the notification plugin and configure channels.
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationTapped?.call();
      },
    );

    // Request notification permission on Android 13+
    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Schedule a daily repeating notification (every 24 hours).
  Future<void> scheduleDailyNoonReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_checkin',
      'Daily Check-In',
      channelDescription: 'Reminder for your daily journal check-in',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    // Cancel existing before re-scheduling
    await _notifications.cancel(id: 0);

    // Use periodicallyShowWithDuration for daily notifications
    await _notifications.periodicallyShowWithDuration(
      id: 0,
      title: 'Daily Check-In',
      body: 'Time for your daily journal check-in',
      repeatDurationInterval: const Duration(hours: 24),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    debugPrint('NotificationService: Scheduled daily noon reminder');
  }

  /// Cancel the daily reminder.
  Future<void> cancelReminder() async {
    await _notifications.cancel(id: 0);
  }
}
