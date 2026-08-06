import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';

/// Handles OTA update: version check, APK download, and install trigger.
/// Uses its own Dio instance pointing to [AppConstants.otaHost],
/// separate from the main WMS API client.
class AppUpdater {
  late final Dio _dio;
  CancelToken? _cancelToken;

  AppUpdater() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.otaHost,
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 60),
    ));
  }

  // ─── Check for new version ────────────────────────────────────
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      // ignore: avoid_print
      print('🟡 [Updater] GET ${AppConstants.otaHost}/api/Devices');
      final response = await _dio.get('/api/Devices');
      // ignore: avoid_print
      print('🟡 [Updater] response: ${response.data}');
      final devices = response.data as List?;
      if (devices == null || devices.isEmpty) {
        // ignore: avoid_print
        print('🔴 [Updater] devices empty/null');
        return null;
      }

      final device = devices.first as Map<String, dynamic>;
      final serverVersion = (device['currentVersionCommon'] as String? ?? '')
          .replaceAll('V', '')
          .trim();
      final apkPath = device['currentVersion'] as String? ?? '';

      if (serverVersion.isEmpty) {
        // ignore: avoid_print
        print('🔴 [Updater] serverVersion empty');
        return null;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      // ignore: avoid_print
      print('🟡 [Updater] current=$currentVersion server=$serverVersion');

      if (currentVersion != serverVersion) {
        return UpdateInfo(
          serverVersion: serverVersion,
          currentVersion: currentVersion,
          apkPath: apkPath,
        );
      }
      // ignore: avoid_print
      print('⚪ [Updater] versions equal — no update');
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('🔴 [Updater] GET failed: $e');
      return null;
    }
  }

  // ─── Download APK ─────────────────────────────────────────────
  Future<String?> downloadApk(
    String apkPath, {
    required void Function(double) onProgress,
    void Function(String)? onError,
  }) async {
    try {
      // getExternalStorageDirectory() returns app-specific path — no permission
      // needed on API 29+; manifest WRITE_EXTERNAL_STORAGE covers API 28 and below.
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        onError?.call('External storage not available');
        return null;
      }
      final savePath = '${dir.path}/fbt_hht.apk';

      final file = File(savePath);
      if (await file.exists()) await file.delete();

      _cancelToken = CancelToken();

      final sw = Stopwatch()..start();
      await _dio.download(
        '${AppConstants.otaVersionEndpoint}?pathFile=$apkPath',
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress(received / total);
        },
      );
      sw.stop();
      final mb = (await file.length()) / 1024 / 1024;
      final secs = sw.elapsedMilliseconds / 1000;
      // ignore: avoid_print
      print('🟢 [Updater] downloaded ${mb.toStringAsFixed(1)} MB in '
          '${secs.toStringAsFixed(1)}s = ${(mb / secs).toStringAsFixed(2)} MB/s');

      return savePath;
    } catch (e) {
      onError?.call(e.toString());
      return null;
    }
  }

  // ─── Install APK ──────────────────────────────────────────────
  Future<String?> installApkWithError(String apkPath) async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.status;
        if (!status.isGranted) {
          await Permission.requestInstallPackages.request();
          final after = await Permission.requestInstallPackages.status;
          if (!after.isGranted) {
            return 'インストール元不明アプリの許可が必要です。\n設定 → アプリ → 不明なアプリのインストール';
          }
        }
      }

      final result = await OpenFile.open(
        apkPath,
        type: 'application/vnd.android.package-archive',
      );
      if (result.type == ResultType.done) return null;
      return '${result.type.name}: ${result.message}';
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> installApk(String apkPath) async {
    return (await installApkWithError(apkPath)) == null;
  }

  // ─── Cancel download ──────────────────────────────────────────
  void cancelDownload() => _cancelToken?.cancel();
}

/// Version info returned by [AppUpdater.checkForUpdate]
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
