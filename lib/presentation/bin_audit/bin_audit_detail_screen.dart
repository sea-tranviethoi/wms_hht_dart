import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/ai/vision_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/di/injection.dart';
import '../../data/repositories/bin_audit_repository.dart';
import '../../data/models/stocktake/invent_stocktake_recording.dart';
import '../../routes/route_names.dart';
import '../widgets/form_widgets.dart';
import '../widgets/top_notification_mixin.dart';
import 'multi_scan_dialog.dart';

/// Bin audit detail screen — Phase 8
///
/// Fetches the stocktake recording and displays its line list.
/// Scanning a product increments its actual quantity; saving performs a bulk update.
class BinAuditDetailScreen extends StatefulWidget {
  final String id;
  final String? stockTakeNo;

  const BinAuditDetailScreen({
    super.key,
    required this.id,
    this.stockTakeNo,
  });

  @override
  State<BinAuditDetailScreen> createState() => _BinAuditDetailScreenState();
}

class _BinAuditDetailScreenState extends State<BinAuditDetailScreen>
    with TopNotificationMixin {
  static final _dateFormat = DateFormat('yyyy/MM/dd');

  // ─── State ───────────────────────────────────────────────────
  bool _loading = true;
  bool _saving = false;
  String? _error;

  InventStockTakeRecording? _recording;
  List<InventStockTakeRecordingLine> _lines = [];

  /// One controller per line (keyed by stable line key)
  final Map<String, TextEditingController> _qtyControllers = {};

  /// Keys of lines that have unsaved changes
  final Set<String> _pendingKeys = {};

  bool _visionBusy = false;

  MobileScannerController? _scannerController;

  // ─── Init ────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rec = await sl<BinAuditRepository>()
          .getRecordingById(widget.id);

      final lines = List<InventStockTakeRecordingLine>.from(
        rec.lines ?? [],
      );

      // Build qty controllers
      for (final ctrl in _qtyControllers.values) {
        ctrl.dispose();
      }
      _qtyControllers.clear();
      _pendingKeys.clear();

      for (int i = 0; i < lines.length; i++) {
        final key = _lineKey(i, lines[i]);
        _qtyControllers[key] = TextEditingController(
          text: (lines[i].actualQty ?? 0).toStringAsFixed(0),
        );
      }

      if (mounted) {
        setState(() {
          _recording = rec;
          _lines = lines;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '棚卸詳細の取得に失敗しました: ${friendlyError(e)}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────

  String _lineKey(int idx, InventStockTakeRecordingLine line) {
    final json = line.toJson();
    return json['id']?.toString() ?? (line.itemCode ?? idx.toString());
  }

  bool get _canEdit {
    final s = _recording?.status?.trim();
    if (s == null) return false;
    final n = int.tryParse(s);
    return s != '1' && n != 1;
  }

  // ─── Discrepancy helpers ─────────────────────────────────────

  /// Signed difference actual − expected, or null if either is missing.
  num? _diff(InventStockTakeRecordingLine line) {
    final exp = line.expectedQty;
    final act = line.actualQty;
    if (exp == null || act == null) return null;
    return act - exp;
  }

  /// Colour for a line based on its discrepancy:
  ///   equal → green, short (actual<expected) → red, over → orange.
  Color _diffColor(num diff) {
    if (diff == 0) return AppColors.wageningenGreen;
    if (diff < 0) return AppColors.settingsColor7;
    return Colors.orange.shade700;
  }

  /// Number of lines whose actual quantity differs from the expected.
  int get _discrepancyCount {
    var n = 0;
    for (final l in _lines) {
      final d = _diff(l);
      if (d != null && d != 0) n++;
    }
    return n;
  }

  // ─── Scan ────────────────────────────────────────────────────

  void _startScan() {
    setState(() => _scannerController = MobileScannerController());
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          height: 420,
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  for (final bc in capture.barcodes) {
                    if (bc.rawValue != null) {
                      _scannerController?.stop();
                      Navigator.pop(ctx);
                      _onScanned(bc.rawValue!);
                      break;
                    }
                  }
                },
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    _scannerController?.stop();
                    Navigator.pop(ctx);
                  },
                ),
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Text(
                  '商品コードをスキャン',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: AppStyles.font,
                    fontSize: AppStyles.sizeBodyText,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onScanned(String code) {
    final trimmed = code.trim();
    final idx = _lines.indexWhere(
      (l) => (l.itemCode ?? '').trim() == trimmed,
    );

    if (idx < 0) {
      _showMessage('「$trimmed」に一致する明細が見つかりません', isError: true);
      return;
    }

    final line = _lines[idx];
    final lineJson = Map<String, dynamic>.from(line.toJson());
    final current = (line.actualQty ?? 0).toInt();
    lineJson['actualQty'] = current + 1;

    final updated = InventStockTakeRecordingLine.fromJson(lineJson);
    final key = _lineKey(idx, line);

    setState(() {
      _lines[idx] = updated;
      _qtyControllers[key]?.text = (current + 1).toString();
      _pendingKeys.add(key);
    });

    _showMessage(
      '${line.itemCode}: $current → ${current + 1}',
      isError: false,
    );
  }

  // ─── Multi-barcode (tap-to-capture) ──────────────────────────

  Future<void> _startMultiScan() async {
    final validCodes = <String>{
      for (final l in _lines)
        if ((l.itemCode ?? '').trim().isNotEmpty) l.itemCode!.trim(),
    };

    final session = await MultiScanDialog.show(context, validCodes);
    if (session == null || !mounted) return;

    final split = session.splitBy(validCodes);

    // Accumulate counted units onto the matching lines (consistent with the
    // single-scan +1 behaviour).
    int updatedLines = 0;
    split.matched.forEach((code, counted) {
      final idx =
          _lines.indexWhere((l) => (l.itemCode ?? '').trim() == code);
      if (idx < 0) return;
      final line = _lines[idx];
      final key = _lineKey(idx, line);
      final current = (line.actualQty ?? 0).toInt();
      final lineJson = Map<String, dynamic>.from(line.toJson());
      lineJson['actualQty'] = current + counted;
      _lines[idx] = InventStockTakeRecordingLine.fromJson(lineJson);
      _qtyControllers[key]?.text = (current + counted).toString();
      _pendingKeys.add(key);
      updatedLines++;
    });

    setState(() {});

    final totalMatched =
        split.matched.values.fold<int>(0, (a, b) => a + b);
    final msg = StringBuffer('$updatedLines件に反映 (合計 $totalMatched点)');
    if (split.hasUnmatched) {
      msg.write(' / 不一致 ${split.unmatched.length}件');
    }
    _showMessage(msg.toString(), isError: split.hasUnmatched);
  }

  // ─── Multi-QR photo scan (pyzbar-decoded, server-highlighted) ────

  Future<void> _startVisionScan() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85, // higher quality than other captures — QR decode needs sharp edges
      maxWidth: 1920,
    );
    if (photo == null || !mounted) return;

    final validCodes = <String>{
      for (final l in _lines)
        if ((l.itemCode ?? '').trim().isNotEmpty) l.itemCode!.trim(),
    };

    setState(() => _visionBusy = true);
    try {
      final result =
          await sl<VisionClient>().identify(File(photo.path), validCodes);
      if (!mounted) return;

      if (result.isEmpty) {
        _showMessage('写真からQRコードを検出できませんでした', isError: true);
        return;
      }
      await _confirmApplyPhotoScan(result);
    } on VisionException catch (e) {
      if (mounted) _showMessage(e.message, isError: true);
    } catch (e) {
      if (mounted) _showMessage('画像解析に失敗しました: ${friendlyError(e)}', isError: true);
    } finally {
      if (mounted) setState(() => _visionBusy = false);
    }
  }

  /// Shows the highlighted photo plus the per-item counts found, and offers
  /// to add each count to the matching line's actual quantity.
  Future<void> _confirmApplyPhotoScan(VisionResult result) async {
    final entries = result.matched.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('写真スキャン結果',
            style: TextStyle(fontFamily: AppStyles.font)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.annotatedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(result.annotatedImage!),
                ),
              const SizedBox(height: 12),
              Text(
                '検出: ${result.totalDetected}件'
                '${result.unmatchedCount > 0 ? '（不一致 ${result.unmatchedCount}件）' : ''}',
                style: const TextStyle(fontFamily: AppStyles.font),
              ),
              const SizedBox(height: 4),
              if (entries.isEmpty)
                const Text('一致した商品はありません',
                    style: TextStyle(fontFamily: AppStyles.font))
              else
                ...entries.map((e) => Text(
                      '${e.key}  × ${e.value}',
                      style: const TextStyle(
                        fontFamily: AppStyles.font,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('いいえ',
                style: TextStyle(fontFamily: AppStyles.font)),
          ),
          if (entries.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                for (final e in entries) {
                  for (var i = 0; i < e.value; i++) {
                    _onScanned(e.key);
                  }
                }
              },
              child: const Text('はい',
                  style: TextStyle(
                    fontFamily: AppStyles.font,
                    fontWeight: FontWeight.bold,
                    color: AppColors.settingsColor6,
                  )),
            ),
        ],
      ),
    );
  }

  // ─── Manual qty edit ─────────────────────────────────────────

  void _onQtyChanged(int idx, String value) {
    final key = _lineKey(idx, _lines[idx]);
    final newQty = num.tryParse(value);
    if (newQty == null) return;

    final lineJson = Map<String, dynamic>.from(_lines[idx].toJson());
    lineJson['actualQty'] = newQty;
    setState(() {
      _lines[idx] = InventStockTakeRecordingLine.fromJson(lineJson);
      _pendingKeys.add(key);
    });
  }

  // ─── Save ────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_pendingKeys.isEmpty) {
      _showMessage('変更がありません', isError: false);
      return;
    }

    setState(() => _saving = true);
    try {
      // Collect only changed lines
      final updates = <Map<String, dynamic>>[];
      for (int i = 0; i < _lines.length; i++) {
        final key = _lineKey(i, _lines[i]);
        if (_pendingKeys.contains(key)) {
          updates.add(_lines[i].toJson());
        }
      }

      await sl<BinAuditRepository>().updateRangeLines(updates);

      if (!mounted) return;
      _pendingKeys.clear();
      _showMessage('${updates.length}件を保存しました', isError: false);
      await _fetch(); // reload to sync with server
    } catch (e) {
      if (mounted) _showMessage('保存に失敗しました: ${friendlyError(e)}', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────

  void _showMessage(String msg, {required bool isError}) {
    showTopNotification(
      msg,
      isError ? AppColors.settingsColor7 : AppColors.settingsColor6,
      duration: const Duration(seconds: 2),
    );
  }

  // ─── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final title =
        widget.stockTakeNo?.isNotEmpty == true ? widget.stockTakeNo! : '棚卸詳細';

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(title, style: AppStyles.appBarTitle),
        backgroundColor: AppColors.settingsColor6,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white, size: AppStyles.sizeTopBarIcon),
          onPressed: () => context.go(RouteNames.binAuditList),
        ),
        actions: [
          if (!_loading && _canEdit)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner,
                  color: AppColors.white, size: AppStyles.sizeTopBarIcon),
              tooltip: 'スキャン（単品）',
              onPressed: _saving ? null : _startScan,
            ),
          if (!_loading && _canEdit)
            IconButton(
              icon: _visionBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white),
                    )
                  : const Icon(Icons.image_search,
                      color: AppColors.white, size: AppStyles.sizeTopBarIcon),
              tooltip: '写真スキャン',
              onPressed: _visionBusy ? null : _startVisionScan,
            ),
          if (!_loading && _canEdit && _pendingKeys.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save, color: AppColors.white, size: AppStyles.sizeTopBarIcon),
              tooltip: '保存',
              onPressed: _saving ? null : _save,
            ),
        ],
      ),
      body: Stack(
        children: [
          _loading
          ? const Center(
              child: SizedBox(
                width: AppStyles.sizeSpinner,
                height: AppStyles.sizeSpinner,
                child: CircularProgressIndicator(
                  strokeWidth: AppStyles.widthSpinnerStroke,
                ),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: AppColors.settingsColor7),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetch,
                        child: const Text('再読み込み'),
                      ),
                    ],
                  ),
                )
              : _recording == null
                  ? const Center(child: Text('データがありません'))
                  : Column(
                      children: [
                        _buildHeader(),
                        Expanded(child: _buildLinesList()),
                        _buildBottomBar(),
                      ],
                    ),
          buildTopBanner(),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────

  Widget _buildHeader() {
    final rec = _recording!;
    final dateStr = rec.transactionDate != null
        ? _dateFormat.format(rec.transactionDate!)
        : null;

    final statusText = rec.statusText ?? rec.status ?? '—';
    final isDone = rec.status?.trim() == '1' ||
        int.tryParse(rec.status?.trim() ?? '') == 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: AppColors.lighter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rec.stockTakeNo ?? '—'}'
                      '${rec.recordNo != null ? '  #${rec.recordNo}' : ''}',
                      style: const TextStyle(
                        fontSize: AppStyles.sizeMainTitle,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppStyles.font,
                        color: AppColors.blackTextColor,
                      ),
                    ),
                    if (dateStr != null)
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: AppStyles.sizeBodyText,
                          fontFamily: AppStyles.font,
                          color: AppColors.black,
                        ),
                      ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDone ? AppColors.wageningenGreen.withOpacity(0.15) : AppColors.settingsColor6.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDone ? AppColors.wageningenGreen : AppColors.settingsColor6,
                    width: 1,
                  ),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: AppStyles.sizeBodyText,
                    fontFamily: AppStyles.font,
                    fontWeight: FontWeight.bold,
                    color: isDone ? AppColors.wageningenGreen : AppColors.settingsColor6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (rec.personInCharge != null &&
                  rec.personInCharge!.isNotEmpty) ...[
                const Icon(Icons.person, size: 16, color: AppColors.black),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    rec.personInCharge!,
                    style: const TextStyle(
                      fontSize: AppStyles.sizeBodyText,
                      fontFamily: AppStyles.font,
                      color: AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (rec.location != null && rec.location!.isNotEmpty) ...[
                const Icon(Icons.location_on, size: 16, color: AppColors.black),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    rec.location!,
                    style: const TextStyle(
                      fontSize: AppStyles.sizeBodyText,
                      fontFamily: AppStyles.font,
                      color: AppColors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          // Line count summary
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '明細: ${_lines.length}件'
                '${_pendingKeys.isNotEmpty ? '  (未保存: ${_pendingKeys.length}件)' : ''}',
                style: TextStyle(
                  fontSize: AppStyles.sizeBodyText,
                  fontFamily: AppStyles.font,
                  color: _pendingKeys.isNotEmpty
                      ? AppColors.settingsColor6
                      : AppColors.black,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '差異: $_discrepancyCount件',
                style: TextStyle(
                  fontSize: AppStyles.sizeBodyText,
                  fontFamily: AppStyles.font,
                  fontWeight: FontWeight.bold,
                  color: _discrepancyCount > 0
                      ? AppColors.settingsColor7
                      : AppColors.wageningenGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Lines list ───────────────────────────────────────────────

  Widget _buildLinesList() {
    if (_lines.isEmpty) {
      return const Center(
        child: Text(
          '明細データがありません',
          style: TextStyle(fontFamily: AppStyles.font),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: _lines.length,
      itemBuilder: (context, idx) {
        final line = _lines[idx];
        final key = _lineKey(idx, line);
        final isPending = _pendingKeys.contains(key);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: isPending ? 3 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isPending ? AppColors.settingsColor6 : Colors.transparent,
              width: isPending ? 1.5 : 0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Item code + description ───────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${idx + 1}. ${line.itemCode ?? '—'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppStyles.sizeBodyText,
                              fontFamily: AppStyles.font,
                            ),
                          ),
                          if (line.description != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              line.description!,
                              style: const TextStyle(
                                fontSize: AppStyles.sizeBodyText,
                                fontFamily: AppStyles.font,
                                color: AppColors.grayTextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Builder(builder: (_) {
                      final d = _diff(line);
                      if (d == null || d == 0) return const SizedBox.shrink();
                      final c = _diffColor(d);
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: c),
                        ),
                        child: Text(
                          '差異 ${d > 0 ? '+' : ''}${d.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: AppStyles.sizeSubText,
                            fontFamily: AppStyles.font,
                            fontWeight: FontWeight.bold,
                            color: c,
                          ),
                        ),
                      );
                    }),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.lighter,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '未保存',
                          style: const TextStyle(
                            fontSize: AppStyles.sizeBodyText,
                            color: AppColors.settingsColor7,
                            fontFamily: AppStyles.font,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Lot / Bin ─────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _infoChip(
                        label: 'ロット',
                        value: line.lot ?? '—',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _infoChip(
                        label: '棚番号',
                        value: line.bin ?? '—',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Expected qty / Actual qty ─────────────
                Row(
                  children: [
                    // Planned quantity (read-only)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '予定数量',
                            style: const TextStyle(
                              fontSize: AppStyles.sizeBodyText,
                              fontFamily: AppStyles.font,
                              color: AppColors.grayTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.lighter,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              line.expectedQty?.toStringAsFixed(0) ?? '—',
                              style: const TextStyle(
                                fontSize: AppStyles.sizeBodyText,
                                fontFamily: AppStyles.font,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Actual quantity (editable if not done)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '実際数量',
                            style: const TextStyle(
                              fontSize: AppStyles.sizeBodyText,
                              fontFamily: AppStyles.font,
                              color: AppColors.grayTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _qtyControllers[key],
                            enabled: _canEdit,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: isPending
                                      ? AppColors.settingsColor6
                                      : AppColors.light,
                                  width: isPending ? 2 : 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: isPending
                                      ? AppColors.settingsColor6
                                      : AppColors.light,
                                  width: isPending ? 2 : 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: AppColors.settingsColor6,
                                  width: 2,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                    color: AppColors.light),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: AppStyles.sizeBodyText,
                              fontFamily: AppStyles.font,
                              fontWeight: FontWeight.w500,
                            ),
                            onChanged: _canEdit
                                ? (v) => _onQtyChanged(idx, v)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lighter,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: AppStyles.sizeBodyText,
              fontFamily: AppStyles.font,
              color: AppColors.grayTextColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppStyles.sizeBodyText,
                fontFamily: AppStyles.font,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom bar ───────────────────────────────────────────────

  Widget _buildBottomBar() {
    return BottomActionBar(
      children: [
        Expanded(child: ActionButton(
          label: '戻る',
          color: AppColors.settingsColor7,
          onPressed: () => context.go(RouteNames.binAuditList),
        )),
        if (_canEdit) ...[
          Expanded(child: ActionButton.icon(
            label: '連続',
            icon: Icons.filter_center_focus,
            color: AppColors.settingsColor6,
            onPressed: _saving ? null : _startMultiScan,
          )),
          Expanded(child: _saving
            ? ActionButton.icon(
                label: '保存中...',
                icon: Icons.hourglass_empty,
                color: AppColors.gray,
                onPressed: null,
              )
            : ActionButton.icon(
                label: '保存',
                icon: Icons.save,
                color: _pendingKeys.isNotEmpty ? AppColors.settingsColor5 : AppColors.gray,
                onPressed: (_saving || _pendingKeys.isEmpty) ? null : _save,
              )),
        ],
      ],
    );
  }

  // ─── Dispose ─────────────────────────────────────────────────

  @override
  void dispose() {
    for (final ctrl in _qtyControllers.values) {
      ctrl.dispose();
    }
    _qtyControllers.clear();
    _scannerController?.dispose();
    super.dispose();
  }
}
