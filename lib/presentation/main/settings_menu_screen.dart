import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../providers/language_provider.dart';
import 'main_menu_screen.dart';

class SettingsMenuScreen extends StatelessWidget {
  const SettingsMenuScreen({super.key});

  List<MenuItem> _getMenuItems(BuildContext context) {
    return [
      MenuItem(
        id: 1,
        title: 'Basic Settings',
        color: AppColors.menuColors[0],
        route: '/basic-settings',
      ),
      MenuItem(
        id: 2,
        title: 'Network',
        color: AppColors.menuColors[1],
        route: '/network-settings',
      ),
      MenuItem(
        id: 3,
        title: 'Print Settings',
        color: AppColors.menuColors[2],
        route: '/print-settings',
      ),
      MenuItem(
        id: 4,
        title: 'Misc Settings',
        color: AppColors.menuColors[3],
        route: '/misc-settings',
      ),
      MenuItem(
        id: 5,
        title: 'Function Test',
        color: AppColors.menuColors[4],
        route: '/function-test',
      ),
      MenuItem(
        id: 6,
        title: 'Back',
        color: AppColors.menuColors[5],
        route: '/sub-menu',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lighter,
      appBar: AppBar(
        title: Text('Settings'),
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
