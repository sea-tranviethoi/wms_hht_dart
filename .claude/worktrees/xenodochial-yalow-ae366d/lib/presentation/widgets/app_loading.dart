import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';

/// ─── AppLoading ──────────────────────────────────────────────────────
/// Loading indicator gọn cho list/section.
///
/// Variants:
/// • compact   → 24x24 spinner inline
/// • centered  → spinner ở giữa screen, kèm label optional
/// • overlay   → black54 backdrop + spinner trắng
class AppLoading extends StatelessWidget {
  final double size;
  final String? message;
  final Color? color;

  const AppLoading({
    super.key,
    this.size = 32,
    this.message,
    this.color,
  });

  /// Spinner nhỏ inline.
  factory AppLoading.compact({Color? color}) =>
      AppLoading(size: 24, color: color);

  /// Spinner ở giữa với optional label.
  factory AppLoading.centered({String? message}) =>
      AppLoading(size: 36, message: message);

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size.w,
            height: size.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(c),
            ),
          ),
          if (message != null) ...[
            SizedBox(height: 12.h),
            Text(
              message!,
              style: TextStyle(
                fontFamily: 'MSPGothic',
                color: AppColors.grayTextColor,
                fontSize: 12.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Backdrop loading dùng cho action submit.
class AppLoadingOverlay extends StatelessWidget {
  final String? message;

  const AppLoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.shadowMedium,
      child: Center(
        child: Card(
          color: AppColors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: AppLoading.centered(message: message),
          ),
        ),
      ),
    );
  }
}
