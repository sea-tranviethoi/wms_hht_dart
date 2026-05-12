import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// ─── Variants ────────────────────────────────────────────────────────
enum ButtonType { primary, secondary, danger, success, outline }

/// ─── Sizes ───────────────────────────────────────────────────────────
enum ButtonSize { small, medium, large }

/// ─── CustomButton ────────────────────────────────────────────────────
/// Button thống nhất cho HHT.
///
/// Visual:
/// • Primary  → AppColors.primary (đỏ thương hiệu)
/// • Secondary → AppColors.themeBackground (xanh đậm)
/// • Danger   → AppColors.btnRed
/// • Success  → AppColors.btnGreen
/// • Outline  → border xanh đậm, nền trong suốt
///
/// Sizes (chiều cao tối thiểu):
/// • small  → 36
/// • medium → 44
/// • large  → 52
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double? height;
  final IconData? icon;
  final EdgeInsets? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height,
    this.icon,
    this.padding,
  });

  // ── Size helpers ─────────────────────────────────────────────
  double get _minHeight {
    switch (size) {
      case ButtonSize.small:  return 36;
      case ButtonSize.medium: return 44;
      case ButtonSize.large:  return 52;
    }
  }

  double get _fontSize {
    switch (size) {
      case ButtonSize.small:  return 13;
      case ButtonSize.medium: return 14;
      case ButtonSize.large:  return 16;
    }
  }

  double get _iconSize {
    switch (size) {
      case ButtonSize.small:  return 16;
      case ButtonSize.medium: return 18;
      case ButtonSize.large:  return 20;
    }
  }

  EdgeInsets get _defaultPadding {
    switch (size) {
      case ButtonSize.small:
        return EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h);
      case ButtonSize.medium:
        return EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h);
      case ButtonSize.large:
        return EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h);
    }
  }

  // ── Color helpers ────────────────────────────────────────────
  Color get _backgroundColor {
    switch (type) {
      case ButtonType.primary:   return AppColors.primary;
      case ButtonType.secondary: return AppColors.themeBackground;
      case ButtonType.danger:    return AppColors.btnRed;
      case ButtonType.success:   return AppColors.btnGreen;
      case ButtonType.outline:   return Colors.transparent;
    }
  }

  Color get _foregroundColor {
    if (type == ButtonType.outline) return AppColors.themeBackground;
    return AppColors.white;
  }

  BorderSide? get _borderSide {
    if (type == ButtonType.outline) {
      return const BorderSide(color: AppColors.themeBackground, width: 1.4);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _backgroundColor,
        foregroundColor: _foregroundColor,
        disabledBackgroundColor: AppColors.gray.withAlpha(150),
        disabledForegroundColor: AppColors.lighter,
        elevation: type == ButtonType.outline ? 0 : 1,
        side: _borderSide,
        padding: padding ?? _defaultPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusSm),
        minimumSize: Size(width ?? 0, height ?? _minHeight.h),
        textStyle: TextStyle(
          fontFamily: 'MSPGothic',
          fontSize: _fontSize.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: _iconSize.w,
              height: _iconSize.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_foregroundColor),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: _iconSize.w),
                  SizedBox(width: 8.w),
                ],
                Flexible(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: btn);
    }
    return btn;
  }
}
