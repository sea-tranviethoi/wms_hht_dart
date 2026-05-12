import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// ─── AppListTile ─────────────────────────────────────────────────────
/// Tile thống nhất cho mọi list screen (warehouse_receipt, putaway,
/// picking, bundle, bin_movement, bin_audit, stocktake).
///
/// Layout:
///   ┌─────────────────────────────────────────┐
///   │ [LeadingBadge]  Title         [Trailing]│
///   │                 Subtitle                │
///   │                 Metadata · ·            │
///   └─────────────────────────────────────────┘
class AppListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> metadata;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? statusColor;
  final bool isSelected;
  final bool isCompleted;

  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.metadata = const [],
    this.leading,
    this.trailing,
    this.onTap,
    this.statusColor,
    this.isSelected = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isSelected
        ? AppColors.headerColor
        : isCompleted
            ? AppColors.rowCompleted
            : AppColors.white;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppRadius.borderRadiusMd,
        border: isSelected
            ? Border.all(color: AppColors.themeBackground, width: 1.4)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.borderRadiusMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderRadiusMd,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status bar (vertical strip on left)
                if (statusColor != null)
                  Container(
                    width: 4.w,
                    height: 44.h,
                    margin: EdgeInsets.only(right: 10.w),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                // Leading
                if (leading != null) ...[
                  leading!,
                  SizedBox(width: 12.w),
                ],

                // Body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'MSPGothic',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blackTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontFamily: 'MSPGothic',
                            fontSize: 12.sp,
                            color: AppColors.grayTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (metadata.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 2.h,
                          children: metadata
                              .map((m) => _MetaChip(text: m))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Trailing
                if (trailing != null) ...[
                  SizedBox(width: 8.w),
                  trailing!,
                ] else if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.gray,
                    size: 20.sp,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String text;
  const _MetaChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'MSPGothic',
        fontSize: 11.sp,
        color: AppColors.grayTextColor,
      ),
    );
  }
}

/// Badge tròn hiển thị số/icon ở vị trí leading.
class AppListBadge extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final Color color;
  final Color? foreground;
  final double size;

  const AppListBadge({
    super.key,
    this.text,
    this.icon,
    this.color = AppColors.themeBackground,
    this.foreground,
    this.size = 36,
  })  : assert(text != null || icon != null, 'text or icon required');

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? AppColors.white;
    return Container(
      width: size.w,
      height: size.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.borderRadiusSm,
      ),
      child: icon != null
          ? Icon(icon, color: fg, size: size.w * 0.5)
          : Text(
              text!,
              style: TextStyle(
                fontFamily: 'MSPGothic',
                color: fg,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
