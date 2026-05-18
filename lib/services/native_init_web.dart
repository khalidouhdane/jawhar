import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/services/push_notification_service.dart';

/// Web stub — native services (AudioSession, AudioService, sqflite_ffi,
/// PushNotifications) are not available on the web platform.
/// This is a no-op so the app can boot in the browser.
Future<void> initNativePlatform(AudioProvider audioProvider, PushNotificationService pushNotifService) async {
  // No-op on web — native audio service and push notifications are not supported.
}
