import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/app_constants.dart';
import '../network/dio_client.dart';

/// Ported from onHandleUpdateVersion + fc_CheckVersion in App.js
class AppUpdater {
  final DioClient _dioClient;
  CancelToken? _cancelToken;

  AppUpdater(this._dioClient);

  // ─── Check for new version ────────────────────────────────────
  /// Returns the new version info if an update is available, or null if already up to date
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await _dioClient.dio.get('/api/Devices');
      final devices = response.data as List?;
      if (devices == null || devices.isEmpty) return null;

      final device = devices.first as Map<String, dynamic>;
      final serverVersion = (device['currentVersionCommon'] as String? ?? '')
          .replaceAll('V', '')
          .trim();
      final apkPath = device['currentVersion'] as String? ?? '';

      if (serverVersion.isEmpty) return null;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (currentVersion != serverVersion) {
        return UpdateInfo(
          serverVersion: serverVersion,
          currentVersion: currentVersion,
          apkPath: apkPath,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Download APK ─────────────────────────────────────────────
  /// [onProgress]: callback receiving a value from 0.0 → 1.0
  Future<String?> downloadApk(
    String apkPath, {
    required void Function(double) onProgress,
  }) async {
    try {
      final dir = await getExternalStorageDirectory();
      final savePath = '${dir?.path ?? '/sdcard'}/fbt_hht.apk';

      // Delete old file if it exists
      final file = File(savePath);
      if (await file.exists()) await file.delete();

      _cancelToken = CancelToken();

      final downloadUrl = '${AppConstants.otaVersionEndpoint}?pathFile=$apkPath';

      await _dioClient.dio.download(
        downloadUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress(received / total);
        },
      );

      return savePath;
    } catch (_) {
      return null;
    }
  }

  // ─── Install APK ──────────────────────────────────────────────
  Future<bool> installApk(String apkPath) async {
    try {
      final result = await OpenFile.open(apkPath);
      return result.type == ResultType.done;
    } catch (_) {
      return false;
    }
  }

  // ─── Cancel download ──────────────────────────────────────────
  void cancelDownload() => _cancelToken?.cancel();
}

/// Update information
class UpdateInfo {
  final String serverVersion;
  final String currentVersion;
  final String apkPath;

  const UpdateInfo({
    required this.serverVersion,
    required this.currentVersion,
    required this.apkPath,
  });
}
