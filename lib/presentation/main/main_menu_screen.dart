import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../config/theme_config.dart';
import '../../routes/route_names.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../../l10n/app_strings.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({Key? key}) : super(key: key);

  List<MenuItem> _getMenuItems(BuildContext context) {
    return [
      MenuItem(
        id: 1,
        title: 'WH Receipt',
        color: AppColors.menuColors[0],
        route: RouteNames.whReceiptSubMenu, // New route for WH Receipt submenu
      ),
      MenuItem(
        id: 2,
        title: 'Putaway',
        color: AppColors.menuColors[1],
        route: RouteNames.putawayList,
      ),
      MenuItem(
        id: 3,
        title: 'Picking',
        color: AppColors.menuColors[2],
        route: RouteNames.pickingList,
      ),
      MenuItem(
        id: 4,
        title: 'Bin Movement',
        color: AppColors.menuColors[3],
        route: RouteNames.binMovementList,
      ),
      MenuItem(
        id: 5,
        title: 'Sub Menu',
        color: AppColors.menuColors[4],
        route: RouteNames.subMenu,
      ),
      MenuItem(
        id: 6,
        title: 'Sign Out',
        color: AppColors.menuColors[5],
        route: '/logout',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lighter,
      appBar: AppBar(
        title: Text(AppStrings.of(context).menuTitle),
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
                  if (item.route == '/logout') {
                    _handleLogout(context);
                  } else {
                    context.push(item.route);
                  }
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

  void _handleLogout(BuildContext context) {
    final rootContext = context;
    final router = GoRouter.of(rootContext);
    final authProvider = Provider.of<AuthProvider>(rootContext, listen: false);

    final strings = AppStrings.ofWithoutWatch(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.loginTitle),
        content: Text('${strings.loginTitle}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.no),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.logout();
              router.go(RouteNames.login);
            },
            child: Text(strings.yes),
          ),
        ],
      ),
    );
  }
}

class MenuItem {
  final int id;
  final String title;
  final Color color;
  final String route;

  const MenuItem({
    required this.id,
    required this.title,
    required this.color,
    required this.route,
  });
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
