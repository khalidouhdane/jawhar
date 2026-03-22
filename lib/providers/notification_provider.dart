import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app/services/push_notification_service.dart';

/// Provider managing notification preferences and scheduling.
/// Stores settings in SharedPreferences (user setting, not profile data).
class NotificationProvider extends ChangeNotifier {
  static const _keyEnabled = 'notif_enabled';
  static const _keyHour = 'notif_hour';
  static const _keyMinute = 'notif_minute';

  final PushNotificationService _service;
  final SharedPreferences _prefs;

  bool _enabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 6, minute: 0);
  bool _permissionGranted = false;

  NotificationProvider(this._service, this._prefs) {
    _loadPreferences();
  }

  // ── Getters ──

  bool get isEnabled => _enabled;
  TimeOfDay get reminderTime => _reminderTime;
  bool get isSupported => _service.isSupported;
  bool get permissionGranted => _permissionGranted;

  /// Formatted time string (e.g., "6:00 AM").
  String get reminderTimeFormatted {
    final hour = _reminderTime.hourOfPeriod == 0 ? 12 : _reminderTime.hourOfPeriod;
    final minute = _reminderTime.minute.toString().padLeft(2, '0');
    final period = _reminderTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // ── Actions ──

  /// Toggle notifications on/off.
  Future<void> toggleNotifications(bool enabled) async {
    if (enabled && !_permissionGranted) {
      _permissionGranted = await _service.requestPermission();
      if (!_permissionGranted) {
        // Permission denied — can't enable
        notifyListeners();
        return;
      }
    }

    _enabled = enabled;
    await _prefs.setBool(_keyEnabled, enabled);

    if (enabled) {
      await _service.scheduleDaily(_reminderTime);
    } else {
      await _service.cancelDaily();
    }

    notifyListeners();
  }

  /// Update the daily reminder time.
  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    await _prefs.setInt(_keyHour, time.hour);
    await _prefs.setInt(_keyMinute, time.minute);

    // Reschedule if enabled
    if (_enabled) {
      await _service.scheduleDaily(time);
    }

    notifyListeners();
  }

  /// Check if today's session is completed and skip notification accordingly.
  /// Called from the session completion flow.
  Future<void> onSessionCompleted() async {
    if (_enabled) {
      // Cancel today's remaining notification since session is done
      await _service.cancelDaily();
      // Reschedule for tomorrow
      await _service.scheduleDaily(_reminderTime);
    }
  }

  /// Reschedule notifications (called on app start).
  /// If notifications are enabled and session isn't completed, ensure scheduled.
  Future<void> ensureScheduled({bool sessionCompletedToday = false}) async {
    if (!_enabled || !_service.isSupported) return;

    if (sessionCompletedToday) {
      // Smart skip: don't notify if session is already done
      await _service.cancelDaily();
    } else {
      await _service.scheduleDaily(_reminderTime);
    }
  }

  // ── Private ──

  void _loadPreferences() {
    _enabled = _prefs.getBool(_keyEnabled) ?? false;
    final hour = _prefs.getInt(_keyHour) ?? 6;
    final minute = _prefs.getInt(_keyMinute) ?? 0;
    _reminderTime = TimeOfDay(hour: hour, minute: minute);
  }
}
