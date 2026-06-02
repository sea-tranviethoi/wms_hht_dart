import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';

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

  factory AppError.network({VoidCallback? onRetry}) => AppError(
        title: '接続エラー',
        message: 'WMSサーバーに接続できません。\nネットワーク状態を確認してください。',
        icon: Icons.wifi_off_outlined,
        onRetry: onRetry,
      );

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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.btnRed.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.btnRed, size: 36),
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontFamily: AppStyles.font,
                  color: AppColors.blackTextColor,
                  fontSize: AppStyles.sizeBodyText,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
            ],
            Text(
              message,
              style: const TextStyle(
                fontFamily: AppStyles.font,
                color: AppColors.grayTextColor,
                fontSize: AppStyles.sizeBodyText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  retryLabel,
                  style: const TextStyle(fontFamily: AppStyles.font),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
