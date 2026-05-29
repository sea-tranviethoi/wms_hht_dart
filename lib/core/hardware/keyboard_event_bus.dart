

// Ported from modules/KeyboardEventBus.js
//
// How it works:
// - Each screen subscribes when focused and unsubscribes when blurred.
// - On receiving an event, listeners are called from the END of the list (highest priority first).
// - If a listener returns `true` → the event is consumed and propagation stops.
// - Priority chain: Modal (added last = highest index) > Detail > List > Home

typedef KeyEventHandler = bool Function(int keyCode);

class KeyboardEventBus {
  KeyboardEventBus._();
  static final KeyboardEventBus instance = KeyboardEventBus._();

  final List<KeyEventHandler> _listeners = [];

  // ─── Subscribe / Unsubscribe ──────────────────────────────────

  /// Registers a listener and returns an unsubscribe callback for use in dispose()
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
  ///     // handle
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

  /// Dispatches a keyCode to listeners in priority order (LIFO)
  void emit(int keyCode) {
    for (int i = _listeners.length - 1; i >= 0; i--) {
      final handled = _listeners[i](keyCode);
      if (handled) break;
    }
  }

  // ─── Clear (use on logout) ────────────────────────────────────
  void clear() => _listeners.clear();
}

// Convenience alias
typedef VoidCallback = void Function();
