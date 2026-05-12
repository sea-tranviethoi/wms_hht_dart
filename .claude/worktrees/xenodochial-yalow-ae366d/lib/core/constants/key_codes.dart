/// Hardware keyCode mapping từ thiết bị Keyence HHT
/// Port từ modules/KeyboardEventModule.js
///
/// Thiết bị Keyence có các nút cứng bên hông gửi keyCode 8–14
/// Mỗi keyCode tương ứng với 1 module chức năng
class HardwareKeyCodes {
  HardwareKeyCodes._();

  // ─── Module Navigation Keys ───────────────────────────────────
  /// Nút cứng 1 → Module Warehouse Receipt (入荷)
  static const int warehouseReceipt   = 8;

  /// Nút cứng 2 → Module Putaway (棚上げ)
  static const int putaway            = 9;

  /// Nút cứng 3 → Module Picking (ピッキング)
  static const int picking            = 10;

  /// Nút cứng 4 → Module Bundle (事前セット)
  static const int bundle             = 11;

  /// Nút cứng 5 → Module Bin Movement (棚移動)
  static const int binMovement        = 12;

  /// Nút cứng 6 → Module Bin Audit (棚卸)
  static const int binAudit           = 13;

  /// Nút cứng 7 → Logout
  static const int logout             = 14;

  // ─── Scanner Trigger Keys ─────────────────────────────────────
  /// Trigger nút scan trái (side scan button)
  static const int scanTriggerLeft    = 103;

  /// Trigger nút scan phải
  static const int scanTriggerRight   = 104;

  /// Tập hợp tất cả module keys để kiểm tra nhanh
  static const Set<int> moduleKeys = {
    warehouseReceipt,
    putaway,
    picking,
    bundle,
    binMovement,
    binAudit,
    logout,
  };

  /// Map từ keyCode → route name (dùng trong MainMenu)
  static const Map<int, String> keyToRoute = {
    warehouseReceipt : '/warehouse-receipt',
    putaway          : '/putaway',
    picking          : '/picking',
    bundle           : '/bundle',
    binMovement      : '/bin-movement',
    binAudit         : '/bin-audit',
  };
}
