import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';

class ModuleTintedButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final double height;

  const ModuleTintedButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = enabled ? color : AppColors.gray;
    final borderColor = enabled ? color : AppColors.light;
    return SizedBox(
      height: height,
      child: Material(
        color: enabled ? color.withOpacity(0.08) : AppColors.lighter,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1.2),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: AppStyles.sizeBottomButtonIcon, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: AppStyles.button.copyWith(color: fg),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModuleFilledButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final double height;

  const ModuleFilledButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.lighter,
          disabledForegroundColor: AppColors.gray,
          elevation: 0,
          minimumSize: Size.fromHeight(height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(icon),
        label: Text(label, style: AppStyles.button),
      ),
    );
  }
}
