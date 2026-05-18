import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/services/quran_audio_handler.dart';
import 'package:quran_app/services/push_notification_service.dart';

/// Initialize native-only services (desktop SQLite, audio session, notifications).
/// This file is loaded on non-web platforms.
Future<void> initNativePlatform(AudioProvider audioProvider, PushNotificationService pushNotifService) async {
  // Initialize SQLite FFI for desktop platforms (Windows, macOS, Linux)
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize push notification service
  await pushNotifService.initialize();

  // Initialize AudioSession for iOS background stability and interruption control
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  // Initialize audio_service — creates a foreground service for media notification
  final audioHandler = await AudioService.init(
    builder: () => QuranAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.quranapp.audio',
      androidNotificationChannelName: 'Quran Audio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  // Wire the handler to the audio provider
  audioProvider.attachAudioHandler(audioHandler);
}
