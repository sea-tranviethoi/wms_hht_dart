import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/hardware/keyboard_event_bus.dart';

/// Widget wrapper tự động subscribe / unsubscribe KeyboardEventBus
/// khi widget được mount / unmount.
///
/// Dùng bọc bên ngoài Scaffold trong mọi screen cần hardware key.
///
/// Ví dụ:
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
  /// Handler nhận keyCode từ thiết bị Keyence.
  /// Trả về `true` nếu đã xử lý (stop propagation).
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

/// Mixin tiện lợi cho StatefulWidget muốn handle hardware keys
/// mà không cần wrap thêm HardwareKeyListener.
///
/// Sử dụng:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with HardwareKeyMixin {
///   @override
///   bool handleHardwareKey(int keyCode) {
///     // xử lý...
///     return true;
///   }
/// }
/// ```
mixin HardwareKeyMixin<T extends StatefulWidget> on State<T> {
  late final VoidCallback _unsubscribe;

  /// Override method này để handle từng keyCode.
  bool handleHardwareKey(int keyCode) => false;

  @override
  void initState() {
    super.initState();
    _unsubscribe = KeyboardEventBus.instance.addListener(handleHardwareKey);
    // Cũng lắng nghe Flutter HardwareKeyboard cho dev mode (không có Keyence)
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
    // Keyence device đi qua EventChannel, không qua HardwareKeyboard.
    // HardwareKeyboard chỉ dùng trên dev machine để test thủ công nếu cần.
    return false;
  }
}
