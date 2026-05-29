import 'package:flutter/services.dart';

/// Ported from modules/KeyenceModule.js
///
/// Communicates with the native Keyence SDK via MethodChannel + EventChannel.
/// Phase 9 will implement the Kotlin (Android) side.
/// Currently: stub that returns mock data for development on a regular device
class KeyenceScanner {
  KeyenceScanner._();
  static final KeyenceScanner instance = KeyenceScanner._();

  // ─── Channels ─────────────────────────────────────────────────
  static const _methodChannel = MethodChannel('com.fbthht/keyence_scanner');
  static const _eventChannel  = EventChannel('com.fbthht/keyence_scanner_events');

  bool _isInitialized = false;
  Stream<String>? _scanStream;

  // ─── Stream receiving barcodes from the Keyence device ───────
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
      // Dev mode: no Keyence device — skip
    } catch (_) {
      // Do not crash the app if the scanner is unavailable
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

  // ─── Release (call when disposing a screen) ──────────────────
  Future<void> release() async {
    try {
      await _methodChannel.invokeMethod('releaseScanManager');
      _isInitialized = false;
    } on MissingPluginException {
      // Dev mode
    } catch (_) {}
  }
}
