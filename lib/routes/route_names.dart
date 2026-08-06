/// All route name constants — ported from navigation/*.js
/// Use constants instead of hard-coded strings in GoRouter
class RouteNames {
  RouteNames._();

  // ─── Auth ─────────────────────────────────────────────────────
  static const String splash          = '/';
  static const String login           = '/login';
  static const String qrLogin         = '/qr-login';
  static const String tenantSelection = '/tenant-selection';

  // ─── Main ─────────────────────────────────────────────────────
  static const String mainMenu        = '/main-menu';
  static const String locationSelect  = '/location-select';
  static const String settings        = '/settings';

  // ─── Warehouse Receipt ────────────────────────────────────────
  static const String warehouseReceipt        = '/warehouse-receipt';
  static const String warehouseReceiptList    = '/warehouse-receipt/list';
  static const String warehouseReceiptFilter  = '/warehouse-receipt/filter';
  static const String warehouseReceiptDetail  = '/warehouse-receipt/detail';

  // ─── Picking ──────────────────────────────────────────────────
  static const String picking         = '/picking';
  static const String pickingList     = '/picking/list';
  static const String pickingItems    = '/picking/items';
  static const String pickingDetail   = '/picking/detail';

  // ─── Putaway ──────────────────────────────────────────────────
  static const String putaway         = '/putaway';
  static const String putawayList     = '/putaway/list';
  static const String putawayDetail   = '/putaway/detail';

  // ─── Bundle ───────────────────────────────────────────────────
  static const String bundle          = '/bundle';
  static const String bundleList      = '/bundle/list';
  static const String bundleItems     = '/bundle/items';
  static const String bundleDetail    = '/bundle/detail';

  // ─── Bin Movement ─────────────────────────────────────────────
  static const String binMovement       = '/bin-movement';
  static const String binMovementList   = '/bin-movement/list';
  static const String binMovementDetail = '/bin-movement/detail';

  // ─── Bin Audit ────────────────────────────────────────────────
  static const String binAudit          = '/bin-audit';
  static const String binAuditList      = '/bin-audit/list';
  static const String binAuditListBin   = '/bin-audit/list-bin';
  static const String binAuditDetail    = '/bin-audit/detail';
  static const String binAuditItems     = '/bin-audit/items';

  // ─── Camera ───────────────────────────────────────────────────
  static const String camera            = '/camera';

  // ─── Legacy (deprecated) ──────────────────────────────────────
  // Used by old screens not yet migrated to BLoC
  @Deprecated('Use warehouseReceipt instead')
  static const String whReceiptSubMenu  = '/wh-receipt-sub-menu';
  @Deprecated('Use mainMenu tiles instead')
  static const String subMenu           = '/sub-menu';
  @Deprecated('Use binAudit instead')
  static const String stocktake         = '/bin-audit/list';
}

