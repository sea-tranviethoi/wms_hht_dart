import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/key_codes.dart';
import '../../../core/hardware/keyboard_event_bus.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../routes/route_names.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Port từ screens/MainMenu.js
///
/// 7 tile màu sắc tương ứng với 7 module:
///   入荷 / 棚上げ / ピッキング / 事前セット / 棚移動 / 棚卸 / ログアウト
///
/// Hỗ trợ hardware keys (Keyence side buttons → keyCode 8–14)
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  late final VoidCallback _unsubscribeHardwareKey;

  // ─── Menu Items Definition ────────────────────────────────────

  static const List<_MenuItem> _items = [
    _MenuItem(
      label: '入荷',
      subtitle: 'Warehouse Receipt',
      color: AppColors.settingsColor1,
      keyCode: HardwareKeyCodes.warehouseReceipt,
    ),
    _MenuItem(
      label: '棚上げ',
      subtitle: 'Putaway',
      color: AppColors.settingsColor2,
      keyCode: HardwareKeyCodes.putaway,
    ),
    _MenuItem(
      label: 'ピッキング',
      subtitle: 'Picking',
      color: AppColors.settingsColor3,
      keyCode: HardwareKeyCodes.picking,
    ),
    _MenuItem(
      label: '事前セット',
      subtitle: 'Bundle',
      color: AppColors.settingsColor4,
      keyCode: HardwareKeyCodes.bundle,
    ),
    _MenuItem(
      label: '棚移動',
      subtitle: 'Bin Movement',
      color: AppColors.settingsColor5,
      keyCode: HardwareKeyCodes.binMovement,
    ),
    _MenuItem(
      label: '棚卸',
      subtitle: 'Bin Audit',
      color: AppColors.settingsColor6,
      keyCode: HardwareKeyCodes.binAudit,
    ),
    _MenuItem(
      label: 'ログアウト',
      subtitle: 'Logout',
      color: AppColors.settingsColor7,
      keyCode: HardwareKeyCodes.logout,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Subscribe hardware key từ Keyence
    _unsubscribeHardwareKey =
        KeyboardEventBus.instance.addListener(_handleHardwareKey);
  }

  @override
  void dispose() {
    _unsubscribeHardwareKey();
    super.dispose();
  }

  // ─── Hardware Key Handler ─────────────────────────────────────

  bool _handleHardwareKey(int keyCode) {
    if (!HardwareKeyCodes.moduleKeys.contains(keyCode)) return false;

    if (keyCode == HardwareKeyCodes.logout) {
      _showLogoutDialog();
      return true;
    }

    final route = HardwareKeyCodes.keyToRoute[keyCode];
    if (route != null && mounted) {
      context.push(route);
      return true;
    }
    return false;
  }

  // ─── Tap Handler ──────────────────────────────────────────────

  void _handleTap(_MenuItem item) {
    if (item.keyCode == HardwareKeyCodes.logout) {
      _showLogoutDialog();
      return;
    }

    // Modules cần chọn tenant trước
    if (item.keyCode == HardwareKeyCodes.warehouseReceipt) {
      context.push(
        '${RouteNames.tenantSelection}?funcNumber=1',
      );
      return;
    }
    if (item.keyCode == HardwareKeyCodes.picking) {
      context.push(
        '${RouteNames.tenantSelection}?funcNumber=3',
      );
      return;
    }

    // Modules không cần chọn tenant → vào thẳng list
    final routeMap = {
      HardwareKeyCodes.putaway     : RouteNames.putawayList,
      HardwareKeyCodes.bundle      : RouteNames.bundleList,
      HardwareKeyCodes.binMovement : RouteNames.binMovementList,
      HardwareKeyCodes.binAudit    : RouteNames.binAuditList,
    };

    final route = routeMap[item.keyCode];
    if (route != null) context.push(route);
  }

  // ─── Logout ───────────────────────────────────────────────────

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text(
          'ログアウト',
          style: TextStyle(fontFamily: 'MSPGothic'),
        ),
        content: const Text(
          'ログアウトしますか？',
          style: TextStyle(fontFamily: 'MSPGothic'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('いいえ', style: TextStyle(fontFamily: 'MSPGothic')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              // Clear hardware key bus trước khi logout
              KeyboardEventBus.instance.clear();
              context.read<AuthBloc>().add(LoggedOut());
              context.go(RouteNames.login);
            },
            child: const Text(
              'はい',
              style: TextStyle(
                fontFamily: 'MSPGothic',
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lighter,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.themeBackground,
        title: const Text(
          'メニュー',
          style: TextStyle(
            fontFamily: 'MSPGothic',
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Version badge
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                'v${AppConstants.appVersion}',
                style: TextStyle(
                  fontFamily: 'MSPGothic',
                  color: AppColors.lighter,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return _MenuTile(
            item: item,
            onTap: () => _handleTap(item),
          );
        },
      ),
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _MenuItem {
  final String label;
  final String subtitle;
  final Color color;
  final int keyCode;

  const _MenuItem({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.keyCode,
  });
}

// ─── Tile Widget ──────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  final VoidCallback onTap;

  const _MenuTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: item.color,
        borderRadius: BorderRadius.circular(12),
        elevation: 3,
        shadowColor: item.color.withValues(alpha: 0.4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: 'MSPGothic',
                          color: AppColors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontFamily: 'MSPGothic',
                          color: AppColors.white,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.white,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
