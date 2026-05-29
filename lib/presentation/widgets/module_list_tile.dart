import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';

class ModuleListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailingText;
  final double? progress;
  final Color statusColor;
  final String statusLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const ModuleListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingText,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
    this.progress,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: isSelected ? AppColors.lighter : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 2, right: 12),
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontFamily: AppStyles.font,
                            fontSize: AppStyles.sizeListTitle,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blackTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontFamily: AppStyles.font,
                          fontSize: AppStyles.sizeSub,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: AppStyles.font,
                        fontSize: AppStyles.sizeInfo,
                        color: AppColors.grayTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (trailingText != null && trailingText!.isNotEmpty)
                  Text(
                    trailingText!,
                    style: TextStyle(
                      fontFamily: AppStyles.font,
                      fontSize: AppStyles.sizeInput,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                if (progress != null) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      width: 48,
                      height: 3,
                      child: LinearProgressIndicator(
                        value: progress!.clamp(0.0, 1.0),
                        backgroundColor: AppColors.lighter,
                        valueColor: AlwaysStoppedAnimation(statusColor),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ModuleListDivider extends StatelessWidget {
  const ModuleListDivider({super.key});

  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        thickness: 0.6,
        indent: 16,
        endIndent: 16,
        color: AppColors.light,
      );
}
