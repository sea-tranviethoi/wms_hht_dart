import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme_config.dart';
import '../../routes/route_names.dart';
import '../../l10n/app_strings.dart';

class WhReceiptSubMenuScreen extends StatelessWidget {
  const WhReceiptSubMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_SubMenuItem> items = [
      _SubMenuItem(
        title: 'CDN',
        onTap: () => context.go(RouteNames.warehouseReceiptList),
      ),
      _SubMenuItem(
        title: 'LL',
        onTap: () => context.go('${RouteNames.warehouseReceiptList}?ll=1'), // Example: add query for LL
      ),
      _SubMenuItem(
        title: AppStrings.of(context).back,
        onTap: () => context.go(RouteNames.mainMenu),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.lighter,
      appBar: AppBar(
        title: const Text('WH Receipt'),
        backgroundColor: AppColors.headerColor,
        automaticallyImplyLeading: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return Material(
            color: AppColors.menuColors[index % AppColors.menuColors.length],
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SubMenuItem {
  final String title;
  final VoidCallback onTap;
  _SubMenuItem({required this.title, required this.onTap});
}