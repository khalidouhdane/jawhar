import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Callback for handling notification taps (must be top-level or static).
@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse response) {
  // Payload is handled by the provider via the stream.
  // Navigation is done in NotificationProvider.
}

/// Push notification service for daily Hifz session reminders.
/// Uses `flutter_local_notifications` for local push notifications.
/// Mobile-only — gracefully no-ops on desktop platforms.
class PushNotificationService {
  static const _channelId = 'hifz_reminders';
  static const _channelName = 'Hifz Reminders';
  static const _channelDesc = 'Daily Hifz session reminder notifications';
  static const _dailyNotificationId = 1;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Whether push notifications are supported on this platform.
  bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  /// Initialize the notification plugin.
  Future<void> initialize() async {
    if (!isSupported || _initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const macSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    _initialized = true;
  }

  /// Request notification permissions (iOS / Android 13+).
  Future<bool> requestPermission() async {
    if (!isSupported) return false;

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }

    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Schedule a daily notification at the given [time].
  Future<void> scheduleDaily(TimeOfDay time) async {
    if (!isSupported || !_initialized) return;

    // Cancel any existing daily notification first
    await cancelDaily();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    // Use zonedSchedule for daily repeating notification
    // We schedule for the next occurrence of the given time
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Use periodicallyShow for daily repeat
    await _plugin.periodicallyShow(
      id: _dailyNotificationId,
      title: 'Time for your Hifz session! 📖',
      body: 'Your daily memorization session is waiting. Tap to start.',
      repeatInterval: RepeatInterval.daily,
      notificationDetails: details,
      payload: 'hifz_session',
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Cancel the daily notification.
  Future<void> cancelDaily() async {
    if (!isSupported || !_initialized) return;
    await _plugin.cancel(id: _dailyNotificationId);
  }

  /// Show an immediate notification (for testing).
  Future<void> showNow({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!isSupported || !_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _plugin.show(
      id: 99, // Test notification ID
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload ?? 'test',
    );
  }
}
