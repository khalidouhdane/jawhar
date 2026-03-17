import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:quran_app/services/update_service.dart';

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
    // Only check on mobile (Android). On desktop, updates are manual.
    if (!Platform.isAndroid) return false;

    _status = UpdateStatus.checking;
    notifyListeners();

    try {
      _updateInfo = await _service.checkForUpdate();
      if (_updateInfo != null) {
        _status = UpdateStatus.available;
        notifyListeners();
        return true;
      } else {
        _status = UpdateStatus.idle;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = UpdateStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Download and install the update APK.
  Future<void> downloadAndInstall() async {
    if (_updateInfo == null || _updateInfo!.apkDownloadUrl.isEmpty) return;

    _status = UpdateStatus.downloading;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      await _service.downloadAndInstall(
        _updateInfo!.apkDownloadUrl,
        onProgress: (progress) {
          _downloadProgress = progress;
          notifyListeners();
        },
      );
      _status = UpdateStatus.readyToInstall;
      notifyListeners();
    } catch (e) {
      _status = UpdateStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Dismiss the update dialog.
  void dismiss() {
    _status = UpdateStatus.idle;
    _updateInfo = null;
    notifyListeners();
  }
}
