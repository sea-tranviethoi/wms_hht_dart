import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// ─── ModuleTintedButton ──────────────────────────────────────────────
/// Action button matching a module's identity color.
///
/// Renders as a soft-tinted background (8% alpha) with a 1.2px solid
/// border, icon + bold label all in [color]. Disabled state uses the
/// neutral `light`/`gray`/`lighter` palette.
///
/// Designed to fit beside `_NavArrowButton`-style controls at 44h.
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
        color: enabled
            ? color.withValues(alpha: 0.08)
            : AppColors.lighter,
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
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'MSPGothic',
                      color: fg,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
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

/// Filled solid-color primary action button matching a module color.
/// Use for the main CTA of a detail screen (e.g. スキャン / 完了 / 棚上げ完了).
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'MSPGothic',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
