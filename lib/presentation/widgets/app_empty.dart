import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';

class AppEmpty extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData icon;
  final Widget? action;

  const AppEmpty({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  factory AppEmpty.list({String? message, Widget? action}) => AppEmpty(
        title: 'データがありません',
        message: message ?? '該当する項目が見つかりませんでした。',
        action: action,
      );

  factory AppEmpty.search({String? query}) => AppEmpty(
        title: '検索結果がありません',
        message: query != null && query.isNotEmpty
            ? '「$query」に一致する項目はありません。'
            : '検索条件を変えてもう一度お試しください。',
        icon: Icons.search_off,
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lighter,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.gray, size: 40),
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontFamily: AppStyles.font,
                  color: AppColors.darker,
                  fontSize: AppStyles.sizeCard,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
            ],
            if (message != null)
              Text(
                message!,
                style: const TextStyle(
                  fontFamily: AppStyles.font,
                  color: AppColors.grayTextColor,
                  fontSize: AppStyles.sizeCaption,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
