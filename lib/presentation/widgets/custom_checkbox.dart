import 'package:flutter/material.dart';
import '../../config/theme_config.dart';

class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String? label;
  final Color? activeColor;
  final bool tristate;

  const CustomCheckbox({
    Key? key,
    required this.value,
    this.onChanged,
    this.label,
    this.activeColor,
    this.tristate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final checkbox = Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? AppColors.primary,
      tristate: tristate,
    );

    if (label != null) {
      return InkWell(
        onTap: onChanged != null ? () => onChanged!(!value) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            checkbox,
            const SizedBox(width: 8),
            Text(
              label!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.blackText,
              ),
            ),
          ],
        ),
      );
    }

    return checkbox;
  }
}

