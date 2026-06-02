import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared form widgets for HHT detail screens (design width 360 px).
//
// Usage:
//   import 'package:wms_hht_dart/presentation/widgets/form_widgets.dart';
//
// Widgets:
//   FormLabel          — section label above a field
//   FormReadOnlyField  — container-based read-only value display
//   FormScanField      — TextField + optional QR scan button
//   FormDateField      — read-only TextField with calendar icon, tap to pick
//   FormDropdownField  — DropdownButtonFormField with standard decoration
//   BottomActionBar    — SafeArea bottom bar that holds action buttons
//   ActionButton       — standard ElevatedButton / ElevatedButton.icon for bars
//   TopBanner          — floating notification bar (place in a Stack)
// ─────────────────────────────────────────────────────────────────────────────

// ─── Internal constants ───────────────────────────────────────────────────────

const String _kFont = AppStyles.font;
const double _kFieldFontSize = AppStyles.sizeBodyText;
const double _kLabelFontSize = AppStyles.sizeBodyText;
const double _kButtonFontSize = AppStyles.sizeButtonLabel;
const double _kFieldRadius = 6;
const double _kButtonRadius = 12;
const double _kButtonHeight = AppStyles.heightBottomButton;
const EdgeInsets _kContentPadding =
    EdgeInsets.symmetric(horizontal: 12, vertical: 12);

// ─────────────────────────────────────────────────────────────────────────────
// 1. FormLabel
// ─────────────────────────────────────────────────────────────────────────────

/// A text label displayed above a form field.
///
/// ```dart
/// FormLabel(label: '棚番号')
/// FormLabel(label: '棚番号', color: AppColors.blackTextColor)
/// ```
class FormLabel extends StatelessWidget {
  const FormLabel({
    super.key,
    required this.label,
    this.color = AppColors.grayTextColor,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: _kLabelFontSize,
        fontFamily: _kFont,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. FormReadOnlyField
// ─────────────────────────────────────────────────────────────────────────────

/// A container-based read-only value display (not an editable TextField).
///
/// Lighter fill, light border (width 1), borderRadius 6,
/// content padding h:12 v:12, optional leading icon.
///
/// ```dart
/// FormReadOnlyField(value: 'WHP002074', icon: Icons.assignment)
/// FormReadOnlyField(value: '26', icon: Icons.inventory_2)
/// ```
class FormReadOnlyField extends StatelessWidget {
  const FormReadOnlyField({
    super.key,
    required this.value,
    this.icon,
  });

  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: _kContentPadding,
      decoration: BoxDecoration(
        color: AppColors.lighter,
        border: Border.all(color: AppColors.light, width: 1),
        borderRadius: BorderRadius.circular(_kFieldRadius),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppStyles.sizeBottomButtonIcon, color: AppColors.blackTextColor),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: _kFieldFontSize,
                fontFamily: _kFont,
                fontWeight: FontWeight.w500,
                color: AppColors.blackTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. FormScanField
// ─────────────────────────────────────────────────────────────────────────────

/// TextField with an optional 48×48 QR scan button.
///
/// - `focusedColor`: border color when field is focused (pass module color).
/// - `showScanButton`: set to `false` to render the TextField alone.
///
/// ```dart
/// FormScanField(
///   controller: _ctrl,
///   focusNode: _focus,
///   focusedColor: AppColors.settingsColor2,
///   onScanTap: () => _scan(),
///   onSubmitted: (v) => _handle(v),
///   hintText: 'バーコードでスキャンまたは入力',
/// )
/// FormScanField(controller: _ctrl, focusedColor: ..., showScanButton: false)
/// ```
class FormScanField extends StatelessWidget {
  const FormScanField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.focusedColor,
    this.onScanTap,
    this.onSubmitted,
    this.hintText,
    this.keyboardType,
    this.showScanButton = true,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final Color focusedColor;
  final VoidCallback? onScanTap;
  final ValueChanged<String>? onSubmitted;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool showScanButton;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: _kFieldFontSize,
        fontFamily: _kFont,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        filled: true,
        fillColor: AppColors.lighter,
        contentPadding: _kContentPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kFieldRadius),
          borderSide: const BorderSide(color: AppColors.light, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kFieldRadius),
          borderSide: const BorderSide(color: AppColors.light, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kFieldRadius),
          borderSide: BorderSide(color: focusedColor, width: 2),
        ),
      ),
      onSubmitted: onSubmitted,
    );

    if (!showScanButton) return field;

    return Row(
      children: [
        Expanded(child: field),
        const SizedBox(width: 8),
        _ScanButton(onTap: onScanTap),
      ],
    );
  }
}

/// Internal 48×48 QR scan button used by [FormScanField].
class _ScanButton extends StatelessWidget {
  const _ScanButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.lighter,
        border: Border.all(color: AppColors.light, width: 1),
        borderRadius: BorderRadius.circular(_kFieldRadius),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.qr_code_scanner, size: AppStyles.sizeBottomButtonIcon),
        color: AppColors.blackTextColor,
        onPressed: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. FormDateField
// ─────────────────────────────────────────────────────────────────────────────

/// A read-only TextField with a calendar prefix icon, a clear button, and a
/// calendar-month suffix icon. Tapping anywhere opens the date picker via
/// [onTap].
///
/// ```dart
/// FormDateField(
///   controller: _dateCtrl,
///   focusNode: _dateFocus,
///   focusedColor: AppColors.settingsColor2,
///   onTap: _selectDate,
///   hintText: 'YYYY-MM-DD',
/// )
/// ```
class FormDateField extends StatelessWidget {
  const FormDateField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.focusedColor,
    required this.onTap,
    this.hintText = 'YYYY-MM-DD',
    this.onClear,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final Color focusedColor;
  final VoidCallback onTap;
  final String? hintText;

  /// Optional override for the clear button; defaults to `controller.clear()`.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      readOnly: true,
      style: const TextStyle(
        fontSize: _kFieldFontSize,
        fontFamily: _kFont,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        filled: true,
        fillColor: AppColors.lighter,
        contentPadding: _kContentPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kFieldRadius),
          borderSide: const BorderSide(color: AppColors.light, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kFieldRadius),
          borderSide: const BorderSide(color: AppColors.light, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kFieldRadius),
          borderSide: BorderSide(color: focusedColor, width: 2),
        ),
        prefixIcon: const Icon(Icons.calendar_today, size: AppStyles.sizeBottomButtonIcon),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clear button — shown only when there is a value
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, __) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.clear, size: AppStyles.sizeBottomButtonIcon),
                  onPressed: onClear ?? controller.clear,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month, size: AppStyles.sizeBottomButtonIcon),
              onPressed: onTap,
            ),
          ],
        ),
      ),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. FormDropdownField
// ─────────────────────────────────────────────────────────────────────────────

/// A generic [DropdownButtonFormField] with the standard HHT decoration.
///
/// ```dart
/// FormDropdownField<String>(
///   value: _selected,
///   hint: '選択してください',
///   focusedColor: AppColors.settingsColor2,
///   items: [...],
///   onChanged: (v) => setState(() => _selected = v),
/// )
/// ```
class FormDropdownField<T> extends StatelessWidget {
  const FormDropdownField({
    super.key,
    this.value,
    this.hint,
    required this.focusedColor,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final String? hint;
  final Color focusedColor;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isDense: true,
      isExpanded: true,
      hint: hint != null
          ? Text(
              hint!,
              style: const TextStyle(
                fontSize: _kFieldFontSize,
                fontFamily: _kFont,
                color: AppColors.textPlaceholder,
              ),
            )
          : null,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: _kFieldFontSize,
        fontFamily: _kFont,
        color: AppColors.blackTextColor,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.lighter,
        contentPadding: _kContentPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kFieldRadius),
          borderSide: const BorderSide(color: AppColors.light, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kFieldRadius),
          borderSide: const BorderSide(color: AppColors.light, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kFieldRadius),
          borderSide: BorderSide(color: focusedColor, width: 2),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. BottomActionBar
// ─────────────────────────────────────────────────────────────────────────────

/// A [SafeArea]-wrapped bottom bar with a white background, top light border,
/// and h:12 v:10 padding. Pass [children] (usually [ActionButton] widgets)
/// arranged in a [Row] separated by 8-px gaps.
///
/// ```dart
/// BottomActionBar(
///   children: [
///     ActionButton(label: '戻る', color: AppColors.settingsColor7, onPressed: () {}),
///     ActionButton(label: '保存', color: AppColors.settingsColor5, onPressed: () {}),
///   ],
/// )
/// ```
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.children,
    this.spacing = 8.0,
  });

  final List<Widget> children;

  /// Gap width between adjacent children. Defaults to 8.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final separated = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      separated.add(children[i]);
      if (i < children.length - 1) {
        separated.add(SizedBox(width: spacing));
      }
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.light)),
        ),
        child: Row(children: separated),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. ActionButton
// ─────────────────────────────────────────────────────────────────────────────

/// Standard ElevatedButton for use inside [BottomActionBar].
///
/// - When [width] is null (default) the button expands to fill available space
///   (wrap in [Expanded] manually, or use [BottomActionBar] which does it for
///   you when [width] is null).
/// - Pass a fixed [width] (e.g. 52) for icon-only narrow buttons.
/// - Set [onPressed] to `null` to disable.
///
/// Named constructor [ActionButton.icon] adds a leading icon via
/// [ElevatedButton.icon].
///
/// ```dart
/// ActionButton(label: '戻る', color: AppColors.settingsColor7, onPressed: () {})
/// ActionButton(label: '保存', color: AppColors.settingsColor5, onPressed: () {})
/// ActionButton(label: '←', color: AppColors.settingsColor5, onPressed: null)
/// ActionButton(label: '←', color: ..., onPressed: ..., width: 52)
/// ActionButton.icon(
///   label: '入荷一覧',
///   icon: Icons.arrow_back,
///   color: AppColors.settingsColor7,
///   onPressed: () {},
/// )
/// ```
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.width,
    this.icon,
    bool useIconVariant = false,
  }) : _useIconVariant = useIconVariant;

  /// Named constructor for a button that displays a leading [icon].
  const ActionButton.icon({
    Key? key,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    double? width,
  }) : this(
          key: key,
          label: label,
          color: color,
          onPressed: onPressed,
          width: width,
          icon: icon,
          useIconVariant: true,
        );

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  /// Fixed width. If null, the button will be wrapped in an [Expanded] when
  /// used inside [BottomActionBar] (handled by the parent).
  ///
  /// Tip: pass `width: 52` for narrow arrow buttons.
  final double? width;

  /// Optional leading icon (shown only when [_useIconVariant] is true).
  final IconData? icon;
  final bool _useIconVariant;

  static const _style = AppStyles.button;

  ButtonStyle _buttonStyle(Color bg) => ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.gray,
        disabledForegroundColor: AppColors.white,
        minimumSize: const Size(0, _kButtonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kButtonRadius),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final Widget button = _useIconVariant && icon != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: AppStyles.sizeBottomButtonIcon),
            label: Text(label, style: _style),
            style: _buttonStyle(color),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: _buttonStyle(color),
            child: Text(label, style: _style),
          );

    if (width != null) {
      return SizedBox(width: width, height: _kButtonHeight, child: button);
    }

    // No fixed width — let the parent (Row/BottomActionBar) control sizing.
    // Wrapping in Expanded here would cause issues if called inside a Column,
    // so we return the button without Expanded and let the caller decide.
    return SizedBox(height: _kButtonHeight, child: button);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. TopBanner
// ─────────────────────────────────────────────────────────────────────────────

/// A floating colored notification banner.
///
/// Place inside a [Stack] as `Positioned(top: 0, left: 0, right: 0, ...)`.
/// Auto-dismiss is handled by the parent (typically with a [Timer]).
///
/// ```dart
/// Stack(
///   children: [
///     // ... main content
///     if (_topMessage != null)
///       Positioned(
///         top: 0, left: 0, right: 0,
///         child: TopBanner(message: _topMessage!, color: _topColor),
///       ),
///   ],
/// )
/// ```
class TopBanner extends StatelessWidget {
  const TopBanner({
    super.key,
    required this.message,
    required this.color,
  });

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: _kFont,
          color: AppColors.white,
          fontSize: AppStyles.sizeMainTitle,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
