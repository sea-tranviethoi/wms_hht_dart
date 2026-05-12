import 'package:flutter/services.dart';

import 'keyboard_event_bus.dart';

/// NativeKeyboardChannel
///
/// Bridges native Android hardware key events → [KeyboardEventBus].
///
/// Native counterpart: android/.../KeyboardEventPlugin.kt
///   MethodChannel 'com.fbthht/keyboard_events'
///   Native calls invokeMethod('onKeyDown', keyCode: int) on every
///   Keyence side-button press.
///
/// Usage: call [startListening] once at app startup (inside initDependencies).
/// The channel is then active for the lifetime of the app.
class NativeKeyboardChannel {
  NativeKeyboardChannel._();
  static final NativeKeyboardChannel instance = NativeKeyboardChannel._();

  static const _channel = MethodChannel('com.fbthht/keyboard_events');

  bool _isListening = false;

  // ─── Lifecycle ────────────────────────────────────────────────

  /// Start listening for native hardware key events.
  /// Safe to call multiple times — subsequent calls are no-ops.
  void startListening() {
    if (_isListening) return;
    _channel.setMethodCallHandler(_handleNativeCall);
    _isListening = true;
  }

  /// Stop listening (e.g. on logout to clear the event bus).
  void stopListening() {
    _channel.setMethodCallHandler(null);
    _isListening = false;
  }

  // ─── Handler ─────────────────────────────────────────────────

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onKeyDown') {
      final keyCode = call.arguments as int?;
      if (keyCode != null) {
        KeyboardEventBus.instance.emit(keyCode);
      }
    }
  }
}
