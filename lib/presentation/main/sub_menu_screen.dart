import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../routes/route_names.dart';
import '../providers/language_provider.dart';
import 'main_menu_screen.dart';

class SubMenuScreen extends StatelessWidget {
  const SubMenuScreen({super.key});

  List<MenuItem> _getMenuItems(BuildContext context) {
    return [
      MenuItem(
        id: 1,
        title: 'SO Tracking',
        color: AppColors.menuColors[0],
        route: '/so-tracking',
      ),
      MenuItem(
        id: 2,
        title: 'Inquiries',
        color: AppColors.menuColors[1],
        route: '/inquiries',
      ),
      MenuItem(
        id: 3,
        title: 'Stock Take',
        color: AppColors.menuColors[2],
        route: RouteNames.binAuditList,
      ),
      MenuItem(
        id: 4,
        title: 'Sales Return',
        color: AppColors.menuColors[3],
        route: '/sales-return',
      ),
      MenuItem(
        id: 5,
        title: 'Setting',
        color: AppColors.menuColors[4],
        route: '/settings-menu',
      ),
      MenuItem(
        id: 6,
        title: 'Back',
        color: AppColors.menuColors[5],
        route: RouteNames.mainMenu,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lighter,
      appBar: AppBar(
        title: Text('Sub Menu'),
        backgroundColor: AppColors.headerColor,
        actions: [_LanguageSelector()],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _getMenuItems(context).length,
        itemBuilder: (context, index) {
          final item = _getMenuItems(context)[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Material(
              color: item.color,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                onTap: () {
                  context.push(item.route);
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
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

class _LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LanguageProvider>();
    final current = provider.locale;
    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language, color: AppColors.black),
      onSelected: provider.setLocale,
      initialValue: current,
      itemBuilder: (_) => const [
        PopupMenuItem(value: Locale('en'), child: Text('English')),
        PopupMenuItem(value: Locale('ja'), child: Text('日本語')),
      ],
    );
  }
}
