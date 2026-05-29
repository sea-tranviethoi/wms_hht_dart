import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/key_codes.dart';
import '../../../core/hardware/keyboard_event_bus.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../core/constants/app_styles.dart';
import '../../../routes/route_names.dart';

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
          style: TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeDialogTitle),
        ),
        content: const Text(
          'ログアウトしますか？',
          style: TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeDialogContent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('いいえ', style: TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeDialogAction)),
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
                fontFamily: AppStyles.font,
                fontSize: AppStyles.sizeDialogAction,
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
      backgroundColor: AppColors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF2D4A38), // settingsColor5 (BinMove) tối hơn
        title: const Text('メニュー', style: AppStyles.appBarTitle),
        actions: [
          // Version badge
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                'v${AppConstants.appVersion}',
                style: TextStyle(
                  fontFamily: AppStyles.font,
                  color: AppColors.lighter,
                  fontSize: AppStyles.sizeCaption,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 6 modules — 2-col grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: GridView.builder(
                itemCount: _items.length - 1, // exclude logout
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.5,
                ),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _MenuTile(item: item, onTap: () => _handleTap(item));
                },
              ),
            ),
          ),
          // Footer — same pattern as BackToMenuButton
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.light)),
              ),
              child: _LogoutButton(onTap: () => _handleTap(_items.last)),
            ),
          ),
        ],
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

// ─── Logout Button ────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2D4A38), // settingsColor5 (BinMove) tối hơn
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: AppStyles.heightBottomButton,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: AppColors.white, size: AppStyles.sizeBottomButtonIcon),
              SizedBox(width: 10),
              Text(
                'ログアウト',
                style: TextStyle(
                  fontFamily: AppStyles.font,
                  color: AppColors.white,
                  fontSize: AppStyles.sizeButton,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tile Widget ──────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  final VoidCallback onTap;

  const _MenuTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.color,
      borderRadius: BorderRadius.circular(6),
      elevation: 2,
      shadowColor: item.color.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontFamily: AppStyles.font,
                        color: AppColors.onColor(item.color),
                        fontSize: AppStyles.sizeMenuLabel,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontFamily: AppStyles.font,
                        color: AppColors.onColor(item.color),
                        fontSize: AppStyles.sizeMenuSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
