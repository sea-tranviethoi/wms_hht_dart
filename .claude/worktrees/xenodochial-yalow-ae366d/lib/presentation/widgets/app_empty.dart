import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// ─── AppEmpty ────────────────────────────────────────────────────────
/// Empty state cho list không có dữ liệu.
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

  /// Empty list mặc định.
  factory AppEmpty.list({String? message, Widget? action}) => AppEmpty(
        title: 'データがありません',
        message: message ?? '該当する項目が見つかりませんでした。',
        action: action,
      );

  /// Search không có kết quả.
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
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.lighter,
                borderRadius: AppRadius.borderRadiusFull,
              ),
              child: Icon(icon, color: AppColors.gray, size: 40.sp),
            ),
            SizedBox(height: 16.h),
            if (title != null) ...[
              Text(
                title!,
                style: TextStyle(
                  fontFamily: 'MSPGothic',
                  color: AppColors.darker,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6.h),
            ],
            if (message != null)
              Text(
                message!,
                style: TextStyle(
                  fontFamily: 'MSPGothic',
                  color: AppColors.grayTextColor,
                  fontSize: 12.sp,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            if (action != null) ...[
              SizedBox(height: 20.h),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
