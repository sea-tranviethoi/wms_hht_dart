import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_radius.dart';
import 'custom_button.dart';

/// ─── AppError ────────────────────────────────────────────────────────
/// State error chuẩn cho mọi screen (network/parse/repo errors).
///
/// • Icon cảnh báo
/// • Title + body Japanese
/// • Optional retry button
class AppError extends StatelessWidget {
  final String? title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String retryLabel;

  const AppError({
    super.key,
    this.title,
    required this.message,
    this.icon = Icons.error_outline,
    this.onRetry,
    this.retryLabel = '再試行',
  });

  /// Lỗi network — preset.
  factory AppError.network({VoidCallback? onRetry}) => AppError(
        title: '接続エラー',
        message: 'WMSサーバーに接続できません。\nネットワーク状態を確認してください。',
        icon: Icons.wifi_off_outlined,
        onRetry: onRetry,
      );

  /// Lỗi chung — preset.
  factory AppError.generic({VoidCallback? onRetry, String? message}) =>
      AppError(
        title: 'エラーが発生しました',
        message: message ?? '処理中にエラーが発生しました。もう一度お試しください。',
        onRetry: onRetry,
      );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.btnRed.withAlpha(20),
                borderRadius: AppRadius.borderRadiusFull,
              ),
              child: Icon(icon, color: AppColors.btnRed, size: 36.sp),
            ),
            SizedBox(height: 16.h),
            if (title != null) ...[
              Text(
                title!,
                style: TextStyle(
                  fontFamily: 'MSPGothic',
                  color: AppColors.blackTextColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6.h),
            ],
            Text(
              message,
              style: TextStyle(
                fontFamily: 'MSPGothic',
                color: AppColors.grayTextColor,
                fontSize: 13.sp,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: 20.h),
              CustomButton(
                text: retryLabel,
                icon: Icons.refresh,
                onPressed: onRetry,
                type: ButtonType.outline,
                size: ButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
