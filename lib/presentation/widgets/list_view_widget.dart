import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../l10n/app_strings.dart';

class ListViewWidget<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;
  final Widget? emptyWidget;
  final String? emptyMessage;
  final bool isLoading;
  final Widget? loadingWidget;

  const ListViewWidget({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.emptyWidget,
    this.emptyMessage,
    this.isLoading = false,
    this.loadingWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ??
          const Center(
            child: CircularProgressIndicator(),
          );
    }

    if (items.isEmpty) {
      return emptyWidget ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                emptyMessage ?? AppStrings.of(context).noData,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPlaceholder,
                ),
              ),
            ),
          );
    }

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding ?? const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return itemBuilder(context, items[index], index);
      },
    );
  }
}

// List Item Card Widget
class ListItemCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;

  const ListItemCard({
    Key? key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 2,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: backgroundColor ?? AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

