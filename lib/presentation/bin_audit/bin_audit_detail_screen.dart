import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/injection.dart';
import '../../data/repositories/bin_audit_repository.dart';
import '../../data/models/stocktake/invent_stocktake_recording.dart';
import '../../routes/route_names.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 棚卸詳細 — Phase 8
///
/// 棚卸記録を取得し、明細一覧を表示。
/// スキャンで対象商品の実際数量をインクリメント、保存で一括更新。
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

class _BinAuditDetailScreenState extends State<BinAuditDetailScreen> {
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
      if (mounted) setState(() => _error = '棚卸詳細の取得に失敗しました:\n$e');
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
                    fontFamily: 'MSPGothic',
                    fontSize: 14.sp,
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
      if (mounted) _showMessage('保存に失敗しました:\n$e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────

  void _showMessage(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
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
        title: Text(title),
        backgroundColor: AppColors.settingsColor6,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.binAuditList),
        ),
        actions: [
          if (!_loading && _canEdit && _pendingKeys.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: '保存',
              onPressed: _saving ? null : _save,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: Colors.red),
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
      decoration: const BoxDecoration(color: AppColors.borderTable),
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
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'MSPGothic',
                        color: AppColors.black,
                      ),
                    ),
                    if (dateStr != null)
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontFamily: 'MSPGothic',
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
                  color: isDone
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDone ? Colors.green : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: 'MSPGothic',
                    fontWeight: FontWeight.bold,
                    color: isDone ? Colors.green.shade700 : Colors.orange.shade700,
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
                const Icon(Icons.person, size: 14, color: AppColors.black),
                const SizedBox(width: 4),
                Text(
                  rec.personInCharge!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontFamily: 'MSPGothic',
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (rec.location != null && rec.location!.isNotEmpty) ...[
                const Icon(Icons.location_on,
                    size: 14, color: AppColors.black),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    rec.location!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontFamily: 'MSPGothic',
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
          Text(
            '明細: ${_lines.length}件'
            '${_pendingKeys.isNotEmpty ? '  (未保存: ${_pendingKeys.length}件)' : ''}',
            style: TextStyle(
              fontSize: 12.sp,
              fontFamily: 'MSPGothic',
              color: _pendingKeys.isNotEmpty
                  ? Colors.orange.shade700
                  : AppColors.black,
            ),
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
          style: TextStyle(fontFamily: 'MSPGothic'),
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
              color: isPending ? Colors.orange : Colors.transparent,
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                              fontFamily: 'MSPGothic',
                            ),
                          ),
                          if (line.description != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              line.description!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontFamily: 'MSPGothic',
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '未保存',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.orange,
                            fontFamily: 'MSPGothic',
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
                    // 予定数量 (read-only)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '予定数量',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontFamily: 'MSPGothic',
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.headerColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              line.expectedQty?.toStringAsFixed(0) ?? '—',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontFamily: 'MSPGothic',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 実際数量 (editable if not done)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '実際数量',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontFamily: 'MSPGothic',
                              color: Colors.black54,
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
                                      ? Colors.orange
                                      : AppColors.headerColor,
                                  width: isPending ? 2 : 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: isPending
                                      ? Colors.orange
                                      : AppColors.headerColor,
                                  width: isPending ? 2 : 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryLight,
                                  width: 2,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                    color: AppColors.headerColor),
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontFamily: 'MSPGothic',
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
        color: AppColors.headerColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11.sp,
              fontFamily: 'MSPGothic',
              color: Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                fontFamily: 'MSPGothic',
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
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderTable)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 戻る
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go(RouteNames.binAuditList),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.btnRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('戻る',
                      style: TextStyle(
                          fontSize: 15.sp, fontFamily: 'MSPGothic')),
                ),
              ),
              if (_canEdit) ...[
                const SizedBox(width: 6),
                // スキャン
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _startScan,
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: Text('スキャン',
                        style: TextStyle(
                            fontSize: 15.sp, fontFamily: 'MSPGothic')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // 保存
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_saving || _pendingKeys.isEmpty)
                        ? null
                        : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text('保存',
                        style: TextStyle(
                            fontSize: 15.sp, fontFamily: 'MSPGothic')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pendingKeys.isNotEmpty
                          ? AppColors.settingsColor6
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
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
