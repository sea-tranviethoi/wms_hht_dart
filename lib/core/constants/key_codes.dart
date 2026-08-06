/// Hardware keyCode mapping for the Keyence HHT device
/// Ported from modules/KeyboardEventModule.js
///
/// Keyence devices have physical side buttons that send keyCodes 8–14.
/// Each keyCode corresponds to one functional module.
class HardwareKeyCodes {
  HardwareKeyCodes._();

  // ─── Module Navigation Keys ───────────────────────────────────
  /// Physical button 1 → Warehouse Receipt module (入荷)
  static const int warehouseReceipt   = 8;

  /// Physical button 2 → Putaway module (棚上げ)
  static const int putaway            = 9;

  /// Physical button 3 → Picking module (ピッキング)
  static const int picking            = 10;

  /// Physical button 4 → Bundle module (事前セット)
  static const int bundle             = 11;

  /// Physical button 5 → Bin Movement module (棚移動)
  static const int binMovement        = 12;

  /// Physical button 6 → Bin Audit module (棚卸)
  static const int binAudit           = 13;

  /// Physical button 7 → Logout
  static const int logout             = 14;

  // ─── Scanner Trigger Keys ─────────────────────────────────────
  /// Left scan trigger button (side scan button)
  static const int scanTriggerLeft    = 103;

  /// Right scan trigger button
  static const int scanTriggerRight   = 104;

  /// Set of all module keys for quick membership checks
  static const Set<int> moduleKeys = {
    warehouseReceipt,
    putaway,
    picking,
    bundle,
    binMovement,
    binAudit,
    logout,
  };

  /// Map from keyCode → route name (used in MainMenu)
  static const Map<int, String> keyToRoute = {
    warehouseReceipt : '/warehouse-receipt',
    putaway          : '/putaway',
    picking          : '/picking',
    bundle           : '/bundle',
    binMovement      : '/bin-movement',
    binAudit         : '/bin-audit',
  };
}
