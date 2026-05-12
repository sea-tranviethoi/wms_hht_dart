import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/key_codes.dart';
import '../../../core/hardware/keyboard_event_bus.dart';
import '../../blocs/auth/auth_bloc.dart';
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
      barrierColor: AppColors.shadowMedium,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon header
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.btnRed.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.btnRed,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ログアウト',
                style: TextStyle(
                  fontFamily: 'MSPGothic',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blackTextColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ログアウトしますか？',
                style: TextStyle(
                  fontFamily: 'MSPGothic',
                  fontSize: 14,
                  color: AppColors.grayTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // No (cancel) — outlined neutral
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darker,
                        side: const BorderSide(color: AppColors.light),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'いいえ',
                        style: TextStyle(
                          fontFamily: 'MSPGothic',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Yes (confirm) — filled danger
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        // Clear hardware key bus trước khi logout
                        KeyboardEventBus.instance.clear();
                        context.read<AuthBloc>().add(LoggedOut());
                        context.go(RouteNames.login);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.btnRed,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'はい',
                        style: TextStyle(
                          fontFamily: 'MSPGothic',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                style: const TextStyle(
                  fontFamily: 'MSPGothic',
                  color: AppColors.lighter,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            children: [
              // ── 6 module tiles, 2 cột (window-style cards) ─────
              Expanded(
                child: Padding(
                  // Inset thêm để mỗi tile -10% chiều rộng
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.6, // -40% chiều cao so với hình vuông
                    ),
                    itemCount: 6, // exclude logout
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _MenuTile(
                        item: item,
                        index: index + 1,
                        onTap: () => _handleTap(item),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // ── Logout button — riêng dưới đáy ─────────────────
              _LogoutTile(
                item: _items.last,
                onTap: () => _handleTap(_items.last),
              ),
            ],
          ),
        ),
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

/// Simple tile: solid color card với label trắng
class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  final int index;
  final VoidCallback onTap;

  const _MenuTile({
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.color,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$index. ${item.label}',
                style: const TextStyle(
                  fontFamily: 'MSPGothic',
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                style: TextStyle(
                  fontFamily: 'MSPGothic',
                  color: AppColors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logout — full-width tile dưới đáy
class _LogoutTile extends StatelessWidget {
  final _MenuItem item;
  final VoidCallback onTap;

  const _LogoutTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.color,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.logout, color: AppColors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: const TextStyle(
                  fontFamily: 'MSPGothic',
                  color: AppColors.white,
                  fontSize: 16,
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
