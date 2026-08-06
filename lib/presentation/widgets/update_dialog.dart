import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../blocs/update/update_cubit.dart';

/// Dialog shown when a new update is available.
///
/// - [UpdateAvailable]        → version info + Update / Skip buttons
/// - [UpdateDownloading]      → progress bar, cannot be dismissed
/// - [UpdateReadyToInstall]   → Install button
/// - [UpdateError]            → error message + Close button
class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key});

  /// Shows the dialog and auto-closes when the state returns to [UpdateIdle]
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<UpdateCubit>(),
        child: const UpdateDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UpdateCubit, UpdateState>(
      listener: (context, state) {
        // Close the dialog when the state returns to idle (skip or cancel)
        if (state is UpdateIdle) Navigator.of(context, rootNavigator: true).pop();
      },
      builder: (context, state) {
        return PopScope(
          // Block the back button while downloading
          canPop: state is! UpdateDownloading,
          child: AlertDialog(
            backgroundColor: AppColors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: _buildTitle(state),
            content: _buildContent(state),
            actions: _buildActions(context, state),
          ),
        );
      },
    );
  }

  // ─── Title ──────────────────────────────────────────────────────

  Widget _buildTitle(UpdateState state) {
    if (state is UpdateError) {
      return Row(children: [
        const Icon(Icons.error_outline, color: AppColors.btnRed, size: 20),
        const SizedBox(width: 8),
        const Text('エラー', style: AppStyles.bodyBold),
      ]);
    }
    return Row(children: [
      const Icon(Icons.system_update_alt, color: AppColors.primary, size: 20),
      const SizedBox(width: 8),
      const Text('アップデート', style: AppStyles.bodyBold),
    ]);
  }

  // ─── Content ────────────────────────────────────────────────────

  Widget _buildContent(UpdateState state) {
    if (state is UpdateAvailable) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('新しいバージョンが利用可能です。', style: AppStyles.body),
          const SizedBox(height: 12),
          _versionRow('現在', state.info.currentVersion),
          const SizedBox(height: 4),
          _versionRow('最新', state.info.serverVersion, highlight: true),
        ],
      );
    }

    if (state is UpdateDownloading) {
      final percent = (state.progress * 100).toStringAsFixed(0);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('ダウンロード中... $percent%', style: AppStyles.body),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: state.progress,
            backgroundColor: AppColors.light,
            color: AppColors.primary,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }

    if (state is UpdateReadyToInstall) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.btnGreen, size: 36),
          const SizedBox(height: 8),
          Text('ダウンロード完了。\nインストールしてください。',
              style: AppStyles.body, textAlign: TextAlign.center),
        ],
      );
    }

    if (state is UpdateError) {
      return Text(state.message, style: AppStyles.body);
    }

    return const SizedBox.shrink();
  }

  // ─── Actions ────────────────────────────────────────────────────

  List<Widget> _buildActions(BuildContext context, UpdateState state) {
    final cubit = context.read<UpdateCubit>();

    if (state is UpdateAvailable) {
      return [
        TextButton(
          onPressed: cubit.dismiss,
          child: Text('スキップ',
              style: AppStyles.body.copyWith(color: AppColors.grayTextColor)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () => cubit.startDownload(state.info.apkPath),
          child: Text('アップデート', style: AppStyles.button),
        ),
      ];
    }

    if (state is UpdateDownloading) {
      return [
        TextButton(
          onPressed: cubit.cancelDownload,
          child: Text('キャンセル',
              style: AppStyles.body.copyWith(color: AppColors.btnRed)),
        ),
      ];
    }

    if (state is UpdateReadyToInstall) {
      return [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.btnGreen),
          onPressed: () => cubit.installApk(state.apkPath),
          child: Text('インストール', style: AppStyles.button),
        ),
      ];
    }

    if (state is UpdateError) {
      return [
        TextButton(
          onPressed: cubit.dismiss,
          child: Text('閉じる',
              style: AppStyles.body.copyWith(color: AppColors.grayTextColor)),
        ),
      ];
    }

    return [];
  }

  // ─── Helpers ────────────────────────────────────────────────────

  Widget _versionRow(String label, String version, {bool highlight = false}) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label,
              style: AppStyles.sub.copyWith(color: AppColors.grayTextColor)),
        ),
        Text(
          version,
          style: highlight
              ? AppStyles.bodyBold.copyWith(color: AppColors.primary)
              : AppStyles.body,
        ),
      ],
    );
  }
}
