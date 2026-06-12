import 'package:flutter/foundation.dart';
import 'package:quran_app/services/update_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Status of the update flow.
enum UpdateStatus {
  idle,
  checking,
  available,
  downloading,
  readyToInstall,
  error,
}

/// Manages app update state: checking, downloading, and installing.
class UpdateProvider extends ChangeNotifier {
  final UpdateService _service = UpdateService();

  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  UpdateStatus _status = UpdateStatus.idle;
  UpdateStatus get status => _status;

  UpdateInfo? _updateInfo;
  UpdateInfo? get updateInfo => _updateInfo;

  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Check GitHub Releases for a new version.
  /// Returns `true` if an update is available.
  Future<bool> checkForUpdate() async {
    _status = UpdateStatus.checking;
    _safeNotify();

    try {
      _updateInfo = await _service.checkForUpdate();
      if (_updateInfo != null) {
        final isDownloaded = await _service.isUpdateDownloaded(
          _updateInfo!.version,
        );
        if (isDownloaded) {
          _status = UpdateStatus.readyToInstall;
        } else {
          _status = UpdateStatus.available;
        }
        _safeNotify();
        return true;
      } else {
        _status = UpdateStatus.idle;
        _safeNotify();
        return false;
      }
    } catch (e) {
      _status = UpdateStatus.error;
      _errorMessage = e.toString();
      _safeNotify();
      return false;
    }
  }

  /// Download and install the update APK.
  Future<void> downloadAndInstall() async {
    if (_updateInfo == null || _updateInfo!.apkDownloadUrl.isEmpty) return;

    final isDownloaded = await _service.isUpdateDownloaded(
      _updateInfo!.version,
    );
    if (!isDownloaded) {
      _status = UpdateStatus.downloading;
      _downloadProgress = 0.0;
      _safeNotify();
    }

    try {
      await _service.downloadAndInstall(
        _updateInfo!.apkDownloadUrl,
        _updateInfo!.version,
        onProgress: (progress) {
          _downloadProgress = progress;
          _safeNotify();
        },
      );
      _status = UpdateStatus.readyToInstall;
      _safeNotify();
    } catch (e) {
      // Direct install can fail (no REQUEST_INSTALL_PACKAGES in store
      // builds) — fall back to the release page in the browser.
      final fallback = _updateInfo?.htmlUrl;
      if (fallback != null && fallback.isNotEmpty) {
        try {
          if (await launchUrl(
            Uri.parse(fallback),
            mode: LaunchMode.externalApplication,
          )) {
            dismiss();
            return;
          }
        } catch (_) {}
      }
      _status = UpdateStatus.error;
      _errorMessage = e.toString();
      _safeNotify();
    }
  }

  /// Dismiss the update dialog.
  void dismiss() {
    _status = UpdateStatus.idle;
    _updateInfo = null;
    _safeNotify();
  }
}
