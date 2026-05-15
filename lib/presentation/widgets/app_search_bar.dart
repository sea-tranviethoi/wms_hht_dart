import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppSearchBar extends StatefulWidget {
  final String? initialValue;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final TextEditingController? controller;
  final bool autofocus;

  const AppSearchBar({
    super.key,
    this.initialValue,
    this.hintText = '検索...',
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.autofocus = false,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _ctrl;
  bool _ownsCtrl = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _ctrl = widget.controller!;
    } else {
      _ctrl = TextEditingController(text: widget.initialValue);
      _ownsCtrl = true;
    }
    _ctrl.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() {});
    widget.onChanged?.call(_ctrl.text);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChanged);
    if (_ownsCtrl) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _ctrl,
        autofocus: widget.autofocus,
        onSubmitted: (_) => widget.onSubmitted?.call(),
        style: const TextStyle(
          fontFamily: 'MSPGothic',
          fontSize: 17,
          color: AppColors.blackTextColor,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(
            fontFamily: 'MSPGothic',
            color: AppColors.grayTextColor,
            fontSize: 16,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.gray, size: 24),
          suffixIcon: _ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppColors.gray, size: 22),
                  onPressed: () => _ctrl.clear(),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          isDense: true,
        ),
      ),
    );
  }
}
