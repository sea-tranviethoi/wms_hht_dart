import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ─── CustomInput ─────────────────────────────────────────────────────
/// Thin wrapper around `TextFormField` that defers styling to the
/// app-wide `InputDecorationTheme` (see `AppTheme.lightTheme`).
///
/// Override `borderColor` only when a screen needs an exceptional
/// emphasis (e.g. error/scan-target). Otherwise let the theme handle
/// borders, fill, focus & error states.
class CustomInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool enabled;
  final TextInputType keyboardType;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final Color? borderColor;
  final String? initialValue;

  const CustomInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.borderColor,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    // When borderColor is explicitly given, override the theme's enabledBorder
    // for that one field; otherwise inherit everything from InputDecorationTheme.
    final enabledBorder = borderColor != null
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor!, width: 1.4),
          )
        : null;

    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      focusNode: focusNode,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      onTap: onTap,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        enabledBorder: enabledBorder,
      ),
    );
  }
}
