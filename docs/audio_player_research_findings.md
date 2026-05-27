# Audio Player Research Findings

Date: 2026-05-27

## Recommendation

Use a two-step path:

1. Keep the current `audioplayers_android_exo` experiment long enough to run the Android device check against Yasser al-Dosari, Surah Al-Baqarah.
2. If any drift or inaccurate seeking remains, migrate `lib/providers/audio_provider.dart` to `just_audio` on Android/iOS/web and use `just_audio_media_kit` for Windows.

The reason is specific to VBR MP3 seeking. ExoPlayer can be accurate only when it has a usable time-to-byte map. Android Media3 documents that VBR MP3 exact seeking requires scanning and indexing the whole file with `FLAG_ENABLE_INDEX_SEEKING`, and that this flag is disabled by default because it can be slower on large files. `just_audio` exposes this flag through `AndroidExtractorOptions.flagMp3EnableIndexSeeking`; `audioplayers_android_exo` uses Media3 ExoPlayer but does not expose extractor flags.

## Current State In This App

- `pubspec.yaml` already includes `audioplayers: ^6.5.1` and `audioplayers_android_exo: ^0.1.3`.
- `.flutter-plugins-dependencies` confirms Android is using `audioplayers_android_exo`.
- Windows still resolves to `audioplayers_windows`; `AudioProvider._shouldProxy` proxies only on Windows.
- `AudioProvider` already uses the right high-level playback model: load the full chapter audio once, then seek by verse timing. The weakness is decoder seek precision, not the app state model.

## Verification Attempt

I ran:

```powershell
flutter build apk --debug --dart-define-from-file=.env
```

The command used the required `.env` Dart defines. The build did not complete because Gradle could not download Flutter engine artifacts from `storage.googleapis.com`:

```text
Could not GET ... storage.googleapis.com ... No such host is known
```

This means the Android compile/runtime validation is still pending. The failure does not prove anything about `audioplayers_android_exo`; it is a network/artifact resolution failure.

## Library Comparison

| Library | Fit | Notes |
| --- | --- | --- |
| `audioplayers` + `audioplayers_android_exo` | Good short-term test | Minimal code change and already wired. Uses Media3 ExoPlayer on Android, but no exposed MP3 index-seeking flag, so VBR seek accuracy may still depend on the remote file metadata. |
| `just_audio` | Best app-level migration target | Mature state streams, speed, seeking, clips, gapless playlists, `audio_service` compatibility, and Android extractor options including MP3 index seeking. |
| `just_audio_windows` | Not ideal for this app | It uses WinRT MediaPlayer, so it may share the same Windows native networking class of problems that forced the proxy. |
| `just_audio_media_kit` | Best Windows pairing with `just_audio` | Uses `media_kit` bindings and supports Windows/Linux. Its default protocol whitelist includes `tls`, `http`, and `https`, making it a better candidate than WinRT MediaPlayer for avoiding the Windows HTTPS issue. |
| `flutter_soloud` | Interesting but not primary | Cross-platform C++ engine, low latency, gapless looping, MP3/OGG/FLAC support. It is aimed at games/immersive audio and would require custom background/media-session glue, custom state mapping, and more validation for long remote Quran chapter streams. |
| `assets_audio_player` | Reject | No Windows support on pub.dev, published 2 years ago, older architecture, and less control over VBR extractor behavior. |

## Migration Plan For `AudioProvider`

1. Dependencies:

```yaml
dependencies:
  just_audio: ^0.10.5
  just_audio_media_kit: ^2.1.0
  media_kit_libs_windows_audio: any
```

Remove `audioplayers` and `audioplayers_android_exo` after migration is complete.

2. Initialize Windows backend before audio playback is created:

```dart
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

if (Platform.isWindows || Platform.isLinux) {
  JustAudioMediaKit.ensureInitialized();
}
```

3. Replace imports and player construction in `lib/providers/audio_provider.dart`:

```dart
import 'package:just_audio/just_audio.dart' as ja;

final ja.AudioPlayer _player = ja.AudioPlayer(
  useProxyForRequestHeaders: false,
);
```

4. Load chapter URLs with Android MP3 index seeking:

```dart
final source = ja.ProgressiveAudioSource(
  Uri.parse(finalUrl),
  options: const ja.ProgressiveAudioSourceOptions(
    androidExtractorOptions: ja.AndroidExtractorOptions(
      mp3Flags: ja.AndroidExtractorOptions.flagMp3EnableIndexSeeking,
    ),
  ),
);

final duration = await _player.setAudioSource(source);
```

5. Event mapping:

| Current `audioplayers` API | `just_audio` replacement |
| --- | --- |
| `onPlayerStateChanged` | `playerStateStream` and `playingStream` |
| `onPositionChanged` | `positionStream` or `createPositionStream(...)` |
| `onDurationChanged` | `durationStream` |
| `onPlayerComplete` | `processingStateStream == ProcessingState.completed` |
| `setSourceUrl(url)` | `setAudioSource(...)` or `setUrl(url)` |
| `resume()` | `play()` |
| `pause()` | `pause()` |
| `stop()` | `stop()` |
| `seek(duration)` | `seek(duration)` |
| `setPlaybackRate(speed)` | `setSpeed(speed)` |
| `setVolume(value)` | `setVolume(value)` |
| `onSeekComplete` | `await seek(...)` plus `positionDiscontinuityStream` if needed |

6. Preserve existing app behavior:

- Keep `_generation` cancellation logic.
- Keep `_isSeeking` to avoid wrong-verse flashes.
- Keep `_audioOffsetMs`, repeat verse, repeat range, isolated verse, and bismillah correction.
- Keep Windows proxy initially as a fallback switch. After testing `just_audio_media_kit` direct HTTPS, remove the proxy only if Windows direct streaming is confirmed stable.

7. Android validation script:

- Build/run with `--dart-define-from-file=.env`.
- Select Yasser al-Dosari, Surah Al-Baqarah.
- Test verses 10, 11, 13, 14 by direct taps.
- Let playback run for at least 60 to 90 seconds and compare highlight against recitation.
- Log player position, active verse, target `firstSegmentMs`, and delta immediately after seek.

## Final Decision Rule

- If `audioplayers_android_exo` fixes the drift on physical Android, keep it for now and avoid migration churn.
- If drift remains, migrate to `just_audio` and use `AndroidExtractorOptions.flagMp3EnableIndexSeeking`.
- For Windows, prefer `just_audio_media_kit` over `just_audio_windows`; only keep the existing proxy if media_kit direct HTTPS still fails.

## Sources

- Android Media3 troubleshooting: https://developer.android.com/media/media3/exoplayer/troubleshooting
- Android Media3 `Mp3Extractor`: https://developer.android.com/reference/androidx/media3/extractor/mp3/Mp3Extractor
- `just_audio`: https://pub.dev/packages/just_audio
- `just_audio_windows`: https://pub.dev/packages/just_audio_windows
- `just_audio_media_kit`: https://pub.dev/packages/just_audio_media_kit
- `audioplayers_android_exo`: https://pub.dev/packages/audioplayers_android_exo
- `flutter_soloud`: https://pub.dev/packages/flutter_soloud
- `assets_audio_player`: https://pub.dev/packages/assets_audio_player
