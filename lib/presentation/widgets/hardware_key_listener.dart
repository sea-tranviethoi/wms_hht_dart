import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/hardware/keyboard_event_bus.dart';

/// Widget wrapper that automatically subscribes / unsubscribes from KeyboardEventBus
/// when the widget is mounted / unmounted.
///
/// Wrap around the Scaffold in any screen that needs hardware key handling.
///
/// Example:
/// ```dart
/// HardwareKeyListener(
///   onKey: (keyCode) {
///     if (keyCode == HardwareKeyCodes.picking) {
///       // navigate ...
///       return true; // consumed
///     }
///     return false;
///   },
///   child: Scaffold(...),
/// )
/// ```
class HardwareKeyListener extends StatefulWidget {
  /// Handler that receives keyCodes from the Keyence device.
  /// Return `true` if handled (stop propagation).
  final KeyEventHandler onKey;
  final Widget child;

  const HardwareKeyListener({
    super.key,
    required this.onKey,
    required this.child,
  });

  @override
  State<HardwareKeyListener> createState() => _HardwareKeyListenerState();
}

class _HardwareKeyListenerState extends State<HardwareKeyListener> {
  late final VoidCallback _unsubscribe;

  @override
  void initState() {
    super.initState();
    _unsubscribe = KeyboardEventBus.instance.addListener(widget.onKey);
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Convenience mixin for StatefulWidgets that want to handle hardware keys
/// without wrapping in an extra HardwareKeyListener widget.
///
/// Usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with HardwareKeyMixin {
///   @override
///   bool handleHardwareKey(int keyCode) {
///     // handle...
///     return true;
///   }
/// }
/// ```
mixin HardwareKeyMixin<T extends StatefulWidget> on State<T> {
  late final VoidCallback _unsubscribe;

  /// Override this method to handle each keyCode.
  bool handleHardwareKey(int keyCode) => false;

  @override
  void initState() {
    super.initState();
    _unsubscribe = KeyboardEventBus.instance.addListener(handleHardwareKey);
    // Also listen to Flutter HardwareKeyboard for dev mode (no Keyence device)
    HardwareKeyboard.instance.addHandler(_onHardwareKeyEvent);
  }

  @override
  void dispose() {
    _unsubscribe();
    HardwareKeyboard.instance.removeHandler(_onHardwareKeyEvent);
    super.dispose();
  }

  bool _onHardwareKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    // Keyence devices go through the EventChannel, not HardwareKeyboard.
    // HardwareKeyboard is only used on a dev machine for manual testing if needed.
    return false;
  }
}
