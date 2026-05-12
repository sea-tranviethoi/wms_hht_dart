import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../presentation/blocs/auth/auth_bloc.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/qr_login_screen.dart';
import '../presentation/screens/main/main_menu_screen.dart';
import '../presentation/screens/main/tenant_selection_screen.dart';
import '../presentation/screens/main/location_selection_screen.dart';
import '../presentation/warehouse_receipt/wr_list_screen.dart';
import '../presentation/warehouse_receipt/wr_detail_screen.dart';
import '../presentation/warehouse_receipt/wr_filter_screen.dart';

import '../presentation/putaway/putaway_list_screen.dart';
import '../presentation/putaway/putaway_detail_screen.dart';
// Picking — new BLoC screens (Phase 3)
import '../presentation/screens/picking/picking_list_screen.dart';
import '../presentation/screens/picking/picking_items_screen.dart';
import '../presentation/screens/picking/picking_detail_screen.dart';
import '../presentation/bundle/bundle_list_screen.dart';
import '../presentation/bundle/bundle_items_screen.dart';
import '../presentation/bundle/bundle_detail_screen.dart';
import '../data/models/picking/picking_line.dart';
import '../data/models/bundle/bundle_line.dart';
import '../data/models/putaway/putaway_line.dart';
import '../presentation/bin_movement/bin_movement_list_screen.dart';
import '../presentation/bin_movement/bin_movement_detail_screen.dart';
import '../data/models/bin_movement/invent_transfer_line.dart';
import '../presentation/bin_audit/bin_audit_list_screen.dart';
import '../presentation/bin_audit/bin_audit_detail_screen.dart';
import 'route_names.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final loc = state.matchedLocation;

    // Đang loading → không redirect, hiện splash
    if (authState is AuthLoading) return null;

    final isAuth = authState is AuthAuthenticated;
    final isPublic = loc == RouteNames.login ||
        loc == RouteNames.qrLogin ||
        loc == RouteNames.splash;

    // Chưa login mà vào trang cần auth → về login
    if (!isAuth && !isPublic) return RouteNames.login;

    // Đã login mà vào login page → về main menu
    if (isAuth && (loc == RouteNames.login || loc == RouteNames.splash)) {
      return RouteNames.mainMenu;
    }

    return null;
  },
  routes: [
    // ── Auth ──────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteNames.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: RouteNames.qrLogin,
      builder: (_, __) => const QRLoginScreen(),
    ),
    GoRoute(
      path: RouteNames.tenantSelection,
      builder: (context, state) {
        final funcNumber = state.uri.queryParameters['funcNumber'];
        return TenantSelectionScreen(funcNumber: funcNumber);
      },
    ),
    GoRoute(
      path: RouteNames.locationSelect,
      builder: (_, __) => const LocationSelectionScreen(),
    ),

    // ── Main ──────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.mainMenu,
      builder: (_, __) => const MainMenuScreen(),
    ),

    // ── Warehouse Receipt ──────────────────────────────────────
    GoRoute(
      path: RouteNames.warehouseReceiptList,
      builder: (context, state) {
        final tenantId = int.tryParse(state.uri.queryParameters['tenantId'] ?? '') ?? 0;
        final company = state.uri.queryParameters['company'] ?? '';
        return WRListScreen(tenantId: tenantId, company: company);
      },
    ),
    GoRoute(
      path: RouteNames.warehouseReceiptFilter,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final tenantId = extra['tenantId'] as int? ?? 0;
        final company = extra['company'] as String? ?? '';
        return WRFilterScreen(tenantId: tenantId, company: company);
      },
    ),
    GoRoute(
      path: RouteNames.warehouseReceiptDetail,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final receiptNo = extra['receiptNo'] as String? ?? '';
        final supplierName = extra['supplierName'] as String?;
        final tenantId = extra['tenantId'] as int? ?? 0;
        if (receiptNo.isEmpty) return const SizedBox.shrink();
        return WRDetailsScreen(
          receiptNo: receiptNo,
          supplierName: supplierName,
          tenantId: tenantId,
        );
      },
    ),

    // ── Putaway ───────────────────────────────────────────────
    GoRoute(
      path: RouteNames.putawayList,
      builder: (_, __) => const PutawayListScreen(),
    ),
    GoRoute(
      path: RouteNames.putawayDetail,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final productCode = extra['productCode'] as String? ?? '';
        final productName = extra['productName'] as String? ?? '';
        final lines =
            (extra['lines'] as List?)?.cast<PutawayLine>() ?? const <PutawayLine>[];
        return PutawayDetailScreen(
          productCode: productCode,
          productName: productName,
          lines: lines,
        );
      },
    ),

    // ── Picking ───────────────────────────────────────────────
    GoRoute(
      path: RouteNames.pickingList,
      builder: (context, state) {
        final tenantId = int.tryParse(state.uri.queryParameters['tenantId'] ?? '') ?? 0;
        final company = state.uri.queryParameters['company'] ?? '';
        return PickingListScreen(tenantId: tenantId, company: company);
      },
    ),
    GoRoute(
      path: RouteNames.pickingItems,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return PickingItemsScreen(
          pickNo: extra['pickNo'] as String? ?? '',
          tenantId: extra['tenantId'] as int? ?? 0,
          company: extra['company'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: RouteNames.pickingDetail,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return PickingDetailScreen(
          pickNo: extra['pickNo'] as String? ?? '',
          pickingLine: extra['pickingLine'] as PickingLine?,
          currentIndex: extra['currentIndex'] as int? ?? 0,
          tenantId: extra['tenantId'] as int? ?? 0,
          company: extra['company'] as String? ?? '',
          allLines: extra['allLines'] as List<PickingLine>? ?? const [],
        );
      },
    ),

    // ── Bundle ────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.bundleList,
      builder: (_, __) => const BundleListScreen(),
    ),
    GoRoute(
      path: RouteNames.bundleItems,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return BundleItemsScreen(transNo: extra['transNo'] as String? ?? '');
      },
    ),
    GoRoute(
      path: RouteNames.bundleDetail,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return BundleDetailScreen(
          transNo: extra['transNo'] as String? ?? '',
          bundleLine: extra['bundleLine'] as BundleLine?,
          currentIndex: extra['currentIndex'] as int? ?? 0,
          allLines: extra['allLines'] as List<BundleLine>? ?? const [],
        );
      },
    ),

    // ── Bin Movement (Phase 7) ────────────────────────────────
    GoRoute(
      path: RouteNames.binMovementList,
      builder: (_, __) => const BinMovementListScreen(),
    ),
    GoRoute(
      path: RouteNames.binMovementDetail,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final transferNo = extra['transferNo'] as String? ?? '';
        final description = extra['description'] as String?;
        final lines =
            (extra['lines'] as List?)?.cast<InventTransferLine>() ??
            const <InventTransferLine>[];
        return BinMovementDetailScreen(
          transferNo: transferNo,
          description: description,
          lines: lines,
        );
      },
    ),

    // ── Bin Audit (Phase 8) ───────────────────────────────────
    GoRoute(
      path: RouteNames.binAuditList,
      builder: (_, __) => const BinAuditListScreen(),
    ),
    GoRoute(
      path: RouteNames.binAuditDetail,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final id = extra['id'] as String? ?? '';
        final stockTakeNo = extra['stockTakeNo'] as String?;
        if (id.isEmpty) return const SizedBox.shrink();
        return BinAuditDetailScreen(id: id, stockTakeNo: stockTakeNo);
      },
    ),
    GoRoute(
      path: RouteNames.binAuditListBin,
      builder: (_, __) => const _PlaceholderScreen(title: '棚卸 (棚別)'),
    ),
    GoRoute(
      path: RouteNames.binAuditItems,
      builder: (_, __) => const _PlaceholderScreen(title: '棚卸明細'),
    ),

    // ── Legacy routes (deprecated, kept for old screens) ──────
    GoRoute(
      path: RouteNames.whReceiptSubMenu, // ignore: deprecated_member_use_from_same_package
      builder: (context, state) {
        final funcNumber = state.uri.queryParameters['funcNumber'] ?? '1';
        return TenantSelectionScreen(funcNumber: funcNumber);
      },
    ),
    GoRoute(
      path: RouteNames.subMenu, // ignore: deprecated_member_use_from_same_package
      builder: (_, __) => const _PlaceholderScreen(title: 'サブメニュー'),
    ),
  ],
);

/// Placeholder cho các screen chưa implement
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Text(
            '$title\n(実装中...)',
            style: TextStyle(fontFamily: 'MSPGothic', fontSize: 16.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
}
