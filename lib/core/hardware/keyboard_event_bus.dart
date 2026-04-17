

/// Port từ modules/KeyboardEventBus.js
///
/// Mô hình hoạt động:
/// - Mỗi màn hình subscribe khi được focus, unsubscribe khi blur
/// - Khi nhận event, gọi listener từ CUỐI danh sách (priority cao nhất)
/// - Nếu listener trả về `true` → event đã được xử lý, dừng lại (stop propagation)
/// - Priority chain: Modal (thêm sau = index cao) > Details > List > Home

typedef KeyEventHandler = bool Function(int keyCode);

class KeyboardEventBus {
  KeyboardEventBus._();
  static final KeyboardEventBus instance = KeyboardEventBus._();

  final List<KeyEventHandler> _listeners = [];

  // ─── Subscribe / Unsubscribe ──────────────────────────────────

  /// Đăng ký listener, trả về hàm hủy để dùng trong dispose()
  ///
  /// ```dart
  /// late final VoidCallback _unsub;
  ///
  /// @override
  /// void initState() {
  ///   _unsub = KeyboardEventBus.instance.addListener(_handleKey);
  /// }
  ///
  /// bool _handleKey(int keyCode) {
  ///   if (keyCode == HardwareKeyCodes.picking) {
  ///     // xử lý
  ///     return true; // stop propagation
  ///   }
  ///   return false;
  /// }
  ///
  /// @override
  /// void dispose() {
  ///   _unsub();
  ///   super.dispose();
  /// }
  /// ```
  VoidCallback addListener(KeyEventHandler handler) {
    _listeners.add(handler);
    return () {
      _listeners.remove(handler);
    };
  }

  // ─── Emit ─────────────────────────────────────────────────────

  /// Gửi keyCode tới listeners theo thứ tự ưu tiên (LIFO)
  void emit(int keyCode) {
    for (int i = _listeners.length - 1; i >= 0; i--) {
      final handled = _listeners[i](keyCode);
      if (handled) break;
    }
  }

  // ─── Clear (dùng khi logout) ──────────────────────────────────
  void clear() => _listeners.clear();
}

// Alias cho dễ dùng
typedef VoidCallback = void Function();
