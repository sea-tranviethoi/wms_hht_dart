import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';

/// ─── AppDetailRow ─────────────────────────────────────────────────────
/// Standard label/value row used in detail screens (stocktake, picking,
/// bundle, wr_detail, ...). Replaces the recurring `_row(label, value)`
/// helper sprinkled across screens.
///
/// Layout:
///   ┌────────────────────────────────────────┐
///   │ Label (bold, fixed width)  Value       │
///   └────────────────────────────────────────┘
class AppDetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? trailing;
  final double labelWidth;
  final Color? valueColor;
  final FontWeight? valueWeight;

  const AppDetailRow({
    super.key,
    required this.label,
    this.value,
    this.trailing,
    this.labelWidth = 140,
    this.valueColor,
    this.valueWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth.w,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'MSPGothic',
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
                color: AppColors.grayTextColor,
              ),
            ),
          ),
          Expanded(
            child: trailing ??
                Text(
                  value ?? '-',
                  style: TextStyle(
                    fontFamily: 'MSPGothic',
                    fontSize: 13.sp,
                    color: valueColor ?? AppColors.blackTextColor,
                    fontWeight: valueWeight ?? FontWeight.w500,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
