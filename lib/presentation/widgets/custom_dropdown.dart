import 'package:flutter/material.dart';
import '../../config/theme_config.dart';

class DropdownItem<T> {
  final T value;
  final String label;
  final String? subtitle;

  DropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
  });
}

class CustomDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final Color? borderColor;
  final Widget? prefixIcon;

  const CustomDropdown({
    Key? key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.borderColor,
    this.prefixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (FormFieldState<T> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) ...[
              Text(
                label!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.blackText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
            ],
            InputDecorator(
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: prefixIcon,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: borderColor ?? AppColors.lighter,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: state.hasError
                        ? AppColors.textError
                        : (borderColor ?? AppColors.lighter),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.textError,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: enabled ? AppColors.white : AppColors.lighter,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                errorText: state.hasError ? state.errorText : null,
              ),
              isEmpty: value == null,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: value,
                  isDense: true,
                  isExpanded: true,
                  items: items.map((item) {
                    return DropdownMenuItem<T>(
                      value: item.value,
                      child: item.subtitle != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.label,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  item.subtitle!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textPlaceholder,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              item.label,
                              style: const TextStyle(fontSize: 14),
                            ),
                    );
                  }).toList(),
                  onChanged: enabled ? onChanged : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

