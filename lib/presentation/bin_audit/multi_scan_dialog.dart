import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import 'bin_audit_scan_session.dart';

/// Tap-to-capture multi-barcode scanner for cycle counting.
///
/// A single camera frame often can't decode every barcode in view at once —
/// the underlying decoder has a per-frame processing budget, so with several
/// codes in frame it may only resolve a couple per pass. To work around this,
/// every code seen in ANY recent frame is accumulated live into a pending set
/// (shown to the user as it grows) while the camera hovers over a group of
/// items; 撮影 then commits that whole accumulated set as one count, so codes
/// missed on one frame but caught a moment later are still included.
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

  /// Distinct raw codes seen across recent frames, not yet committed by 撮影.
  /// Accumulates across multiple camera frames (not just the latest one) so
  /// codes the decoder misses on one pass are still caught on the next.
  final Set<String> _pending = {};

  /// Units added by the last capture — shown as a brief confirmation.
  int _lastAdded = 0;

  /// True when the last 撮影 found nothing pending.
  bool _emptyCapture = false;

  @override
  void initState() {
    super.initState();
    // unrestricted → onDetect fires as fast as the decoder can manage, so the
    // pending set fills in quickly while the camera hovers over the items.
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
    final newCodes = <String>[
      for (final b in capture.barcodes)
        if (b.rawValue != null && b.rawValue!.trim().isNotEmpty)
          b.rawValue!.trim(),
    ];
    if (newCodes.isEmpty) return;
    // Only rebuild when something new actually shows up, to avoid
    // re-rendering on every single frame.
    final before = _pending.length;
    _pending.addAll(newCodes);
    if (_pending.length != before) setState(() {});
  }

  void _capture() {
    if (_pending.isEmpty) {
      // Nothing detected yet — tell the user instead of failing silently
      // (this is a barcode scanner, not a plain photo capture).
      setState(() {
        _lastAdded = 0;
        _emptyCapture = true;
      });
      return;
    }
    _session.addCapture(_pending.toList());
    setState(() {
      _lastAdded = _pending.length;
      _emptyCapture = false;
      _pending.clear();
    });
  }

  void _reset() {
    setState(() {
      _session.reset();
      _pending.clear();
      _lastAdded = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final matcher = BinAuditCodeMatcher(widget.validCodes);
    final split = _session.splitBy(widget.validCodes);
    final entries = _session.counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final pendingSorted = _pending.toList()..sort();

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Camera ──────────────────────────────────────────
            SizedBox(
              height: 260,
              child: Stack(
                children: [
                  MobileScanner(controller: _controller, onDetect: _onDetect),
                  // Frame guide
                  Center(
                    child: Container(
                      width: 260,
                      height: 170,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.flash_on, color: AppColors.white),
                      tooltip: 'ライト',
                      onPressed: () => _controller?.toggleTorch(),
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

            // ── Live pending detections ───────────────────────────
            // Shows what the camera has picked up SO FAR for the current
            // group, before 撮影 commits it. Lets the user visually confirm
            // every item is seen (hold steady a moment) instead of guessing.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: AppColors.settingsColor6.withOpacity(0.08),
              child: Row(
                children: [
                  Text(
                    '検出中 (${_pending.length}):',
                    style: const TextStyle(
                      fontFamily: AppStyles.font,
                      fontSize: AppStyles.sizeSubText,
                      fontWeight: FontWeight.bold,
                      color: AppColors.settingsColor6,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      pendingSorted.isEmpty ? '—' : pendingSorted.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppStyles.font,
                        fontSize: AppStyles.sizeSubText,
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
              height: 140,
              child: entries.isEmpty
                  ? const Center(
                      child: Text(
                        'カメラを商品に向けてください',
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
                        final itemCode = matcher.matchFor(e.key);
                        final matched = itemCode != null;
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
                          subtitle: matched && itemCode != e.key
                              ? Text(
                                  '→ $itemCode',
                                  style: const TextStyle(
                                    fontFamily: AppStyles.font,
                                    fontSize: AppStyles.sizeSubText,
                                    color: AppColors.grayTextColor,
                                  ),
                                )
                              : null,
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
