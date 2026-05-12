import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// ─── AppShimmer ──────────────────────────────────────────────────────
/// Lightweight shimmer placeholder (no external package).
/// Use as a loading skeleton instead of CircularProgressIndicator when
/// you can render a faithful layout outline.
///
/// Usage:
/// ```dart
/// AppShimmer(
///   child: Container(
///     height: 60,
///     decoration: BoxDecoration(
///       color: AppColors.white,
///       borderRadius: AppRadius.borderRadiusMd,
///     ),
///   ),
/// );
/// ```
class AppShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const AppShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1200),
    this.baseColor = AppColors.lighter,
    this.highlightColor = AppColors.white,
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width * (_controller.value * 2 - 1);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.25, 0.5, 0.75],
              transform: _SlidingGradientTransform(slidePercent: dx / bounds.width),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// Pre-built skeleton row for list screens.
/// Renders a card-shaped placeholder identical in size to AppListTile.
class AppShimmerListItem extends StatelessWidget {
  const AppShimmerListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        height: 72.h,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.borderRadiusMd,
        ),
      ),
    );
  }
}

/// Convenience: a column of N shimmer list items, wrap-padded.
class AppShimmerList extends StatelessWidget {
  final int itemCount;
  const AppShimmerList({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: itemCount,
      itemBuilder: (_, __) => const AppShimmerListItem(),
    );
  }
}
