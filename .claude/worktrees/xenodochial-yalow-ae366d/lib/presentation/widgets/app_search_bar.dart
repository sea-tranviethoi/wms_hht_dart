import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// ─── AppSearchBar ────────────────────────────────────────────────────
/// Search bar thống nhất cho list screens (warehouse_receipt, putaway,
/// picking, bundle, bin_movement, bin_audit, stocktake).
///
/// • Filled style với icon search
/// • Clear button khi có text
/// • onChanged debounce do caller xử lý (giữ widget tối giản)
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
    setState(() {}); // toggle clear button
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
        borderRadius: AppRadius.borderRadiusSm,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _ctrl,
        autofocus: widget.autofocus,
        onSubmitted: (_) => widget.onSubmitted?.call(),
        style: TextStyle(
          fontFamily: 'MSPGothic',
          fontSize: 14.sp,
          color: AppColors.blackTextColor,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            fontFamily: 'MSPGothic',
            color: AppColors.textPlaceholder,
            fontSize: 13.sp,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.gray, size: 20),
          suffixIcon: _ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppColors.gray, size: 18),
                  onPressed: () => _ctrl.clear(),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          isDense: true,
        ),
      ),
    );
  }
}
