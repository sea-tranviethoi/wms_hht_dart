import 'package:flutter/services.dart';

/// Port từ modules/KeyenceModule.js
///
/// Giao tiếp với native Keyence SDK qua MethodChannel + EventChannel
/// Phase 9 sẽ implement phía Kotlin (Android)
/// Hiện tại: stub trả về mock data cho dev trên thiết bị thường
class KeyenceScanner {
  KeyenceScanner._();
  static final KeyenceScanner instance = KeyenceScanner._();

  // ─── Channels ─────────────────────────────────────────────────
  static const _methodChannel = MethodChannel('com.fbthht/keyence_scanner');
  static const _eventChannel  = EventChannel('com.fbthht/keyence_scanner_events');

  bool _isInitialized = false;
  Stream<String>? _scanStream;

  // ─── Stream nhận barcode từ thiết bị Keyence ─────────────────
  Stream<String> get scanStream {
    _scanStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => event?.toString() ?? '');
    return _scanStream!;
  }

  // ─── Init scanner ─────────────────────────────────────────────
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _methodChannel.invokeMethod('createScanManager');
      _isInitialized = true;
    } on MissingPluginException {
      // Dev mode: không có thiết bị Keyence — bỏ qua
    } catch (_) {
      // Không crash app nếu scanner không available
    }
  }

  // ─── Start scanning ───────────────────────────────────────────
  Future<void> startRead() async {
    try {
      await _methodChannel.invokeMethod('startReadControl');
    } on MissingPluginException {
      // Dev mode
    } catch (_) {}
  }

  // ─── Stop scanning ────────────────────────────────────────────
  Future<void> stopRead() async {
    try {
      await _methodChannel.invokeMethod('stopReadControl');
    } on MissingPluginException {
      // Dev mode
    } catch (_) {}
  }

  // ─── Release (gọi khi dispose màn hình) ──────────────────────
  Future<void> release() async {
    try {
      await _methodChannel.invokeMethod('releaseScanManager');
      _isInitialized = false;
    } on MissingPluginException {
      // Dev mode
    } catch (_) {}
  }
}
