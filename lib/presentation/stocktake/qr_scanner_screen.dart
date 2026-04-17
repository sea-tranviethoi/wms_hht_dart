import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

/// Full-screen scanner that requests camera permission and returns the
/// first barcode string found via `Navigator.pop(context, code)` or null.
class QrScannerScreen extends StatefulWidget {
  /// If [allowMultiple] is true, the scanner will keep scanning and call
  /// [onScanned] for every detected value. The screen stays open until the
  /// user taps Done. If false (default), the scanner will pop with the
  /// first scanned value.
  final bool allowMultiple;
  final ValueChanged<String?>? onScanned;

  const QrScannerScreen({
    super.key,
    this.allowMultiple = false,
    this.onScanned,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _scanned = false;
  String? _lastScanned;
  DateTime? _lastScannedAt;
  final MobileScannerController _controller = MobileScannerController();
  PermissionStatus? _permissionStatus;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    setState(() => _permissionStatus = status);
    if (!status.isGranted) {
      // Try request once automatically
      await _requestPermission();
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _requesting = true);
    final res = await Permission.camera.request();
    setState(() {
      _requesting = false;
      _permissionStatus = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_permissionStatus == null || _requesting) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_permissionStatus!.isGranted) {
      content = MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;
          final code = barcodes.first.rawValue;
          if (code == null) return;

          // throttle identical scans within 800ms
          final now = DateTime.now();
          if (_lastScanned != null &&
              _lastScanned == code &&
              _lastScannedAt != null) {
            if (now.difference(_lastScannedAt!).inMilliseconds < 800) return;
          }
          _lastScanned = code;
          _lastScannedAt = now;

          if (widget.allowMultiple) {
            // keep scanning; report via callback
            widget.onScanned?.call(code);
            // provide short visual feedback by updating state
            setState(() {});
            return;
          }

          // single-scan behavior: pop with value
          if (_scanned) return;
          _scanned = true;
          Navigator.of(context).pop(code);
        },
      );
    } else if (_permissionStatus!.isPermanentlyDenied) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text('Camera access is permanently denied.'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open app settings'),
            ),
          ],
        ),
      );
    } else {
      // denied but not permanently
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 56),
            const SizedBox(height: 12),
            const Text('Camera permission is required to scan barcodes.'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _requestPermission,
              child: const Text('Grant permission'),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () async {
                await openAppSettings();
              },
              child: const Text('Open app settings'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Scan QR / Barcode'),
            const SizedBox(width: 12),
            if (widget.allowMultiple && _lastScanned != null) ...[
              const Icon(Icons.done_all, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Last: ${_lastScanned ?? ''}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Toggle flash',
          ),
          if (widget.allowMultiple)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: content,
    );
  }
}
