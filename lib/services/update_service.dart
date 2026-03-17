import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Information about an available update.
class UpdateInfo {
  final String version;
  final String releaseNotes;
  final String apkDownloadUrl;
  final String htmlUrl; // fallback: link to the release page

  const UpdateInfo({
    required this.version,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.htmlUrl,
  });
}

/// Service that checks GitHub Releases for app updates and handles APK
/// download + install on Android.
class UpdateService {
  static const _owner = 'khalidouhdane';
  static const _repo = 'le-quran';
  static const _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  final Dio _dio = Dio();

  /// Check the latest GitHub Release and compare with the running app version.
  /// Returns [UpdateInfo] if a newer version is available, `null` otherwise.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await _dio.get(
        _apiUrl,
        options: Options(headers: {'Accept': 'application/vnd.github.v3+json'}),
      );

      if (response.statusCode != 200) return null;

      final data = response.data as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final releaseNotes = data['body'] as String? ?? '';
      final htmlUrl = data['html_url'] as String? ?? '';

      // Parse the remote version from the tag (strip leading 'v')
      final remoteVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;

      // Get the running app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.0.0"

      if (!_isNewer(remoteVersion, currentVersion)) return null;

      // Find the first .apk asset in the release
      String apkUrl = '';
      final assets = data['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String? ?? '';
          break;
        }
      }

      return UpdateInfo(
        version: remoteVersion,
        releaseNotes: releaseNotes,
        apkDownloadUrl: apkUrl,
        htmlUrl: htmlUrl,
      );
    } catch (_) {
      // Network error, no release, etc. — silently return null.
      return null;
    }
  }

  /// Download the APK from [url] and trigger the system installer.
  /// [onProgress] reports 0.0 → 1.0 download progress.
  Future<void> downloadAndInstall(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/le_quran_update.apk';

    // Download with progress
    await _dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress?.call(received / total);
        }
      },
    );

    // Trigger the Android APK installer
    await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
  }

  /// Compare two semver strings. Returns `true` if [remote] > [current].
  bool _isNewer(String remote, String current) {
    final rParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Pad to same length
    while (rParts.length < 3) {
      rParts.add(0);
    }
    while (cParts.length < 3) {
      cParts.add(0);
    }

    for (var i = 0; i < 3; i++) {
      if (rParts[i] > cParts[i]) return true;
      if (rParts[i] < cParts[i]) return false;
    }
    return false; // equal
  }
}
