import 'package:flutter/material.dart';
import 'custom_input.dart';
import 'custom_dropdown.dart';
import 'custom_button.dart';
import '../../config/theme_config.dart';
import '../../l10n/app_strings.dart';

// Re-export DropdownItem for convenience
export 'custom_dropdown.dart' show DropdownItem;

class FilterField {
  final String key;
  final String label;
  final FilterFieldType type;
  final dynamic initialValue;
  final List<DropdownItem>? dropdownItems;

  FilterField({
    required this.key,
    required this.label,
    required this.type,
    this.initialValue,
    this.dropdownItems,
  });
}

enum FilterFieldType { text, dropdown, date }

class FilterWidget extends StatefulWidget {
  final List<FilterField> fields;
  final Function(Map<String, dynamic>)? onFilter;
  final Function()? onReset;
  final bool showResetButton;

  const FilterWidget({
    Key? key,
    required this.fields,
    this.onFilter,
    this.onReset,
    this.showResetButton = true,
  }) : super(key: key);

  @override
  State<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  final Map<String, dynamic> _filterValues = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var field in widget.fields) {
      _filterValues[field.key] = field.initialValue;
      if (field.type == FilterFieldType.text) {
        _controllers[field.key] = TextEditingController(
          text: field.initialValue?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleFilter() {
    // Update filter values from controllers
    for (var entry in _controllers.entries) {
      _filterValues[entry.key] = entry.value.text;
    }

    widget.onFilter?.call(_filterValues);
  }

  void _handleReset() {
    setState(() {
      _filterValues.clear();
      for (var field in widget.fields) {
        _filterValues[field.key] = field.initialValue;
        if (_controllers.containsKey(field.key)) {
          _controllers[field.key]!.text = field.initialValue?.toString() ?? '';
        }
      }
    });
    widget.onReset?.call();
    widget.onFilter?.call(_filterValues);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) {
                final strings = AppStrings.of(context);
                return Text(
                  strings.filter,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackText,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: widget.fields.map((field) {
                return SizedBox(width: 200, child: _buildField(field));
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.showResetButton) ...[
                  CustomButton(
                    text: AppStrings.of(context).reset,
                    type: ButtonType.outline,
                    onPressed: _handleReset,
                  ),
                  const SizedBox(width: 8),
                ],
                CustomButton(
                  text: AppStrings.of(context).search,
                  type: ButtonType.primary,
                  onPressed: _handleFilter,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(FilterField field) {
    switch (field.type) {
      case FilterFieldType.text:
        return CustomInput(
          label: field.label,
          controller: _controllers[field.key],
          onChanged: (value) {
            _filterValues[field.key] = value;
          },
        );
      case FilterFieldType.dropdown:
        return CustomDropdown(
          label: field.label,
          value: _filterValues[field.key],
          items: field.dropdownItems ?? [],
          onChanged: (value) {
            setState(() {
              _filterValues[field.key] = value;
            });
          },
        );
      case FilterFieldType.date:
        return CustomInput(
          label: field.label,
          controller: _controllers[field.key],
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              _controllers[field.key]!.text =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              _filterValues[field.key] = date.toIso8601String();
            }
          },
          suffixIcon: const Icon(Icons.calendar_today),
        );
    }
  }
}
