import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/update/app_updater.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class UpdateState {
  const UpdateState();
}

/// No update activity
class UpdateIdle extends UpdateState {
  const UpdateIdle();
}

/// Checking server for new version
class UpdateChecking extends UpdateState {
  const UpdateChecking();
}

/// New version found — waiting for user action
class UpdateAvailable extends UpdateState {
  final UpdateInfo info;
  const UpdateAvailable(this.info);
}

/// Downloading APK — [progress] is 0.0 → 1.0
class UpdateDownloading extends UpdateState {
  final double progress;
  const UpdateDownloading(this.progress);
}

/// APK downloaded and ready to install
class UpdateReadyToInstall extends UpdateState {
  final String apkPath;
  const UpdateReadyToInstall(this.apkPath);
}

/// Something went wrong
class UpdateError extends UpdateState {
  final String message;
  const UpdateError(this.message);
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class UpdateCubit extends Cubit<UpdateState> {
  final AppUpdater _updater;

  UpdateCubit(this._updater) : super(const UpdateIdle());

  Future<void> checkForUpdate() async {
    // ignore: avoid_print
    print('🟡 [Update] checkForUpdate START');
    emit(const UpdateChecking());
    try {
      final info = await _updater.checkForUpdate();
      if (info != null) {
        // ignore: avoid_print
        print('🟢 [Update] AVAILABLE: ${info.currentVersion} → ${info.serverVersion}');
        emit(UpdateAvailable(info));
      } else {
        // ignore: avoid_print
        print('⚪ [Update] no update (info == null)');
        emit(const UpdateIdle());
      }
    } catch (e) {
      // ignore: avoid_print
      print('🔴 [Update] checkForUpdate threw: $e');
      emit(const UpdateIdle());
    }
  }

  Future<void> startDownload(String apkPath) async {
    emit(const UpdateDownloading(0));
    String? errorMsg;
    final path = await _updater.downloadApk(
      apkPath,
      onProgress: (p) {
        if (!isClosed) emit(UpdateDownloading(p));
      },
      onError: (e) => errorMsg = e,
    );
    if (path != null) {
      emit(UpdateReadyToInstall(path));
    } else {
      emit(UpdateError(errorMsg ?? 'Download failed'));
    }
  }

  Future<void> installApk(String apkPath) async {
    final error = await _updater.installApkWithError(apkPath);
    if (error != null && !isClosed) emit(UpdateError(error));
  }

  void cancelDownload() {
    _updater.cancelDownload();
    emit(const UpdateIdle());
  }

  void dismiss() => emit(const UpdateIdle());
}
