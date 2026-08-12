import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import 'bin_audit_scan_session.dart';

/// Tap-to-capture multi-barcode scanner for cycle counting.
///
/// The camera stays open; the latest frame's barcodes are buffered. Pressing
/// 撮影 snapshots the current frame — every barcode in it counts as one unit,
/// so identical items sitting side by side each add one. Counts accumulate
/// across captures and are shown live, split into matched (an existing line)
/// and unmatched values.
///
/// Returns the [BinAuditScanSession] via [Navigator.pop] when the user taps
/// 完了, or null if cancelled.
class MultiScanDialog extends StatefulWidget {
  /// Item codes of the current stocktake lines — used to classify scans live.
  final Set<String> validCodes;

  const MultiScanDialog({super.key, required this.validCodes});

  static Future<BinAuditScanSession?> show(
    BuildContext context,
    Set<String> validCodes,
  ) {
    return showDialog<BinAuditScanSession>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MultiScanDialog(validCodes: validCodes),
    );
  }

  @override
  State<MultiScanDialog> createState() => _MultiScanDialogState();
}

class _MultiScanDialogState extends State<MultiScanDialog> {
  final _session = BinAuditScanSession();
  MobileScannerController? _controller;

  /// Raw values detected in the most recent camera frame.
  List<String> _latestFrame = const [];

  /// Units added by the last capture — shown as a brief confirmation.
  int _lastAdded = 0;

  /// True when the last 撮影 found no barcode in the frame.
  bool _emptyCapture = false;

  @override
  void initState() {
    super.initState();
    // unrestricted → onDetect fires every frame with the barcodes currently in
    // view, so the buffer stays fresh and 撮影 reliably captures what's visible.
    // (The default noDuplicates stops reporting a code while it stays in frame,
    // which leaves the buffer stale/empty at capture time.)
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    // Buffer the latest frame only — nothing is counted until 撮影 is pressed.
    _latestFrame = [
      for (final b in capture.barcodes)
        if (b.rawValue != null && b.rawValue!.trim().isNotEmpty) b.rawValue!,
    ];
  }

  void _capture() {
    final frame = _latestFrame;
    if (frame.isEmpty) {
      // No barcode in the current frame — tell the user instead of failing
      // silently (this is a barcode scanner, not a plain photo capture).
      setState(() {
        _lastAdded = 0;
        _emptyCapture = true;
      });
      return;
    }
    _session.addCapture(frame);
    setState(() {
      _lastAdded = frame.length;
      _emptyCapture = false;
    });
  }

  void _reset() {
    setState(() {
      _session.reset();
      _lastAdded = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final split = _session.splitBy(widget.validCodes);
    final entries = _session.counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Camera ──────────────────────────────────────────
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  MobileScanner(controller: _controller, onDetect: _onDetect),
                  // Frame guide
                  Center(
                    child: Container(
                      width: 260,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: AppColors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  if (_lastAdded > 0)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Text(
                        '+$_lastAdded',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontFamily: AppStyles.font,
                          fontSize: AppStyles.sizeMainTitle,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                      ),
                    ),
                  if (_emptyCapture)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Text(
                        'バーコードが見つかりません',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontFamily: AppStyles.font,
                          fontSize: AppStyles.sizeBodyText,
                          fontWeight: FontWeight.bold,
                          backgroundColor: AppColors.settingsColor7,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Tally summary ───────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppColors.lighter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('撮影', '${_session.captureCount}'),
                  _stat('合計', '${_session.totalUnits}'),
                  _stat('一致', '${split.matched.length}',
                      color: AppColors.settingsColor6),
                  _stat('不一致', '${split.unmatched.length}',
                      color: split.hasUnmatched
                          ? AppColors.settingsColor7
                          : AppColors.grayTextColor),
                ],
              ),
            ),

            // ── Counted list ────────────────────────────────────
            SizedBox(
              height: 160,
              child: entries.isEmpty
                  ? const Center(
                      child: Text(
                        '撮影ボタンでスキャンしてください',
                        style: TextStyle(
                          fontFamily: AppStyles.font,
                          color: AppColors.grayTextColor,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (_, i) {
                        final e = entries[i];
                        final matched = split.matched.containsKey(e.key);
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            matched ? Icons.check_circle : Icons.error_outline,
                            color: matched
                                ? AppColors.settingsColor6
                                : AppColors.settingsColor7,
                            size: 20,
                          ),
                          title: Text(
                            e.key,
                            style: const TextStyle(
                              fontFamily: AppStyles.font,
                              fontSize: AppStyles.sizeBodyText,
                            ),
                          ),
                          trailing: Text(
                            '× ${e.value}',
                            style: const TextStyle(
                              fontFamily: AppStyles.font,
                              fontSize: AppStyles.sizeBodyText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () => setState(() => _session.decrement(e.key)),
                        );
                      },
                    ),
            ),

            // ── Actions ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _session.isEmpty ? null : _reset,
                    child: const Text('リセット',
                        style: TextStyle(fontFamily: AppStyles.font)),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.settingsColor6,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed: _capture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('撮影',
                        style: TextStyle(fontFamily: AppStyles.font)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.settingsColor5,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed: _session.isEmpty
                        ? null
                        : () => Navigator.pop(context, _session),
                    child: const Text('完了',
                        style: TextStyle(fontFamily: AppStyles.font)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppStyles.font,
            fontSize: AppStyles.sizeSubText,
            color: AppColors.grayTextColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppStyles.font,
            fontSize: AppStyles.sizeMainTitle,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.blackTextColor,
          ),
        ),
      ],
    );
  }
}
