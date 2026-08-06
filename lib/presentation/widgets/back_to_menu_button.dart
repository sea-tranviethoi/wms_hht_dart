import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';

class BackToMenuButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color? color;

  const BackToMenuButton({
    super.key,
    required this.onPressed,
    this.label = '戻る',
    this.icon = Icons.arrow_back,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.light)),
        ),
        child: Material(
          color: color ?? AppColors.settingsColor7,
          borderRadius: BorderRadius.circular(12),
          elevation: 1,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: AppStyles.heightBottomButton,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.white, size: AppStyles.sizeBottomButtonIcon),
                  const SizedBox(width: 12),
                  Text(label, style: AppStyles.button),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
