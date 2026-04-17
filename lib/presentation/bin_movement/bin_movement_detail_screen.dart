import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../config/theme_config.dart';
import '../../core/di/injection.dart';
import '../../core/storage/cache_storage.dart';
import '../../data/datasources/remote/bin_movement_remote_datasource.dart';
import '../../data/models/bin_movement/invent_transfer_line.dart';
import '../../routes/route_names.dart';

/// 棚移動詳細 — Phase 7
/// 移動番号に紐づく明細を一件ずつ確認・入力し、最後に棚移動完了を登録する。
class BinMovementDetailScreen extends StatefulWidget {
  final String transferNo;
  final String? description;
  final List<InventTransferLine> lines;

  const BinMovementDetailScreen({
    super.key,
    required this.transferNo,
    this.description,
    required this.lines,
  });

  @override
  State<BinMovementDetailScreen> createState() =>
      _BinMovementDetailScreenState();
}

class _BinMovementDetailScreenState extends State<BinMovementDetailScreen> {
  // ─── Controllers ─────────────────────────────────────────────
  final TextEditingController _toBinController = TextEditingController();
  final TextEditingController _transQtyController = TextEditingController();
  final TextEditingController _lotNoController = TextEditingController();
  final TextEditingController _expirationDateController =
      TextEditingController();

  // ─── Focus ───────────────────────────────────────────────────
  final FocusNode _toBinFocus = FocusNode();
  final FocusNode _transQtyFocus = FocusNode();
  final FocusNode _lotNoFocus = FocusNode();

  // ─── State ───────────────────────────────────────────────────
  int _currentIndex = 0;
  late List<InventTransferLine> _editedLines;
  MobileScannerController? _scannerController;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _editedLines = List.of(widget.lines);
    _updateFormFields();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _toBinFocus.requestFocus());
  }

  // ─── Form helpers ─────────────────────────────────────────────

  InventTransferLine get _current => _editedLines[_currentIndex];

  void _updateFormFields() {
    final line = _current;
    _toBinController.text = line.toBin ?? '';
    _transQtyController.text =
        line.transQty?.toStringAsFixed(0) ?? line.journalQty.toStringAsFixed(0);
    _lotNoController.text = line.lotNo ?? '';
    _expirationDateController.text = line.expirationDate ?? '';
  }

  void _saveCurrentToMemory() {
    _editedLines[_currentIndex] = _current.copyWith(
      toBin: _toBinController.text.trim(),
      transQty:
          double.tryParse(_transQtyController.text) ?? _current.journalQty,
      lotNo: _lotNoController.text.trim(),
      expirationDate: _expirationDateController.text.trim(),
    );
  }

  // ─── Navigation ───────────────────────────────────────────────

  void _handlePrevious() {
    if (_currentIndex <= 0) return;
    _saveCurrentToMemory();
    setState(() {
      _currentIndex--;
      _updateFormFields();
    });
    _toBinFocus.requestFocus();
  }

  void _handleNext() {
    if (_currentIndex >= _editedLines.length - 1) return;
    _saveCurrentToMemory();
    setState(() {
      _currentIndex++;
      _updateFormFields();
    });
    _toBinFocus.requestFocus();
  }

  // ─── Save (in-memory) ─────────────────────────────────────────

  void _handleSave() {
    final toBin = _toBinController.text.trim();
    if (toBin.isEmpty) {
      _showError('移動先棚番号を入力してください');
      return;
    }
    _saveCurrentToMemory();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('保存しました'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
    if (_currentIndex < _editedLines.length - 1) _handleNext();
  }

  // ─── Complete (sync → API) ────────────────────────────────────

  Future<void> _handleComplete() async {
    // Validate all lines have a toBin
    final missing = _editedLines
        .where((l) => (l.toBin == null || l.toBin!.isEmpty))
        .map((l) => l.productCode)
        .toList();
    if (missing.isNotEmpty) {
      _showError('移動先棚番号が未入力の明細があります:\n${missing.join(', ')}');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('棚移動完了'),
        content: Text(
          '${widget.transferNo} — ${_editedLines.length}件の棚移動を登録しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('完了'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSyncing = true);
    try {
      final remote = sl<BinMovementRemoteDataSource>();
      final hhtInfo = sl<CacheStorage>().getString('hhtInfo') ?? '';

      // 1. Delete existing staging for this transfer
      final existing = await remote.getStagingByNo(widget.transferNo);
      for (final s in existing) {
        await remote.deleteStaging(s);
      }

      // 2. Build new staging payload
      final stagingList = _editedLines.map((l) {
        return {
          'transferNo': l.transferNo,
          'productCode': l.productCode,
          'unitId': l.unitId,
          'journalQty': l.journalQty,
          'transQty': l.transQty ?? l.journalQty,
          'fromBin': l.fromBin ?? '',
          'toBin': l.toBin ?? '',
          'status': 0,
          'lotNo': l.lotNo,
          'expirationDate': l.expirationDate,
          'transferLineId': l.id,
        };
      }).toList();

      // 3. Add new staging
      await remote.addStagingRange(stagingList);

      // 4. Update HHT status for each line
      for (final l in _editedLines) {
        if (l.id != null) {
          await remote.updateHHTStatus(
            status: 1,
            masterId: l.id!,
            detailId: 0,
            hhtInfo: hhtInfo,
          );
        }
      }

      // 5. Complete transfer
      await remote.completeTransfer();

      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('棚移動が完了しました'),
            backgroundColor: Colors.green,
          ),
        );
        context.go(RouteNames.binMovementList);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        _showError('棚移動完了に失敗しました:\n$e');
      }
    }
  }

  // ─── QR Scanner ───────────────────────────────────────────────

  void _startScanner(String field) {
    setState(() => _scannerController = MobileScannerController());
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          height: 400,
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  for (final bc in capture.barcodes) {
                    if (bc.rawValue != null) {
                      _scannerController?.stop();
                      Navigator.pop(ctx);
                      _onScanned(bc.rawValue!, field);
                      break;
                    }
                  }
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    _scannerController?.stop();
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onScanned(String value, String field) {
    setState(() {
      switch (field) {
        case 'toBin':
          _toBinController.text = value;
          _transQtyFocus.requestFocus();
        case 'transQty':
          _transQtyController.text = value;
          _lotNoFocus.requestFocus();
        case 'lotNo':
          _lotNoController.text = value;
      }
    });
  }

  // ─── Date picker ─────────────────────────────────────────────

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _expirationDateController.text =
            DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ─── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final line = _current;
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == _editedLines.length - 1;

    return Scaffold(
      backgroundColor: AppColors.lighter,
      appBar: AppBar(
        title: const Text('棚移動詳細'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.binMovementList),
        ),
      ),
      body: _isSyncing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('棚移動登録中...',
                      style: TextStyle(fontFamily: 'MSPGothic')),
                ],
              ),
            )
          : Column(
              children: [
                // ── Header ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.borderTable,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.transferNo,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'MSPGothic',
                                color: AppColors.black,
                              ),
                            ),
                            if (widget.description != null &&
                                widget.description!.isNotEmpty)
                              Text(
                                widget.description!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'MSPGothic',
                                  color: AppColors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.borderTable, width: 1),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${_editedLines.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'MSPGothic',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Form ───────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 商品番号 + 商品名 (read-only)
                        _buildReadOnlyField(
                          label: '商品番号',
                          value: line.productCode,
                          icon: Icons.inventory,
                        ),
                        const SizedBox(height: 8),
                        if (line.productName != null &&
                            line.productName!.isNotEmpty)
                          _buildReadOnlyField(
                            label: '商品名',
                            value: line.productName!,
                          ),
                        const SizedBox(height: 8),

                        // 移動元棚 (read-only)
                        _buildReadOnlyField(
                          label: '移動元棚番号',
                          value: line.fromBin ?? '—',
                          icon: Icons.output,
                        ),
                        const SizedBox(height: 12),

                        // Arrow indicator
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_downward,
                                color: Colors.teal, size: 28),
                            SizedBox(width: 6),
                            Text('移動',
                                style: TextStyle(
                                    color: Colors.teal,
                                    fontFamily: 'MSPGothic',
                                    fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 移動先棚 (scan)
                        _buildScanField(
                          label: '移動先棚番号',
                          controller: _toBinController,
                          focusNode: _toBinFocus,
                          hintText: 'バーコードでスキャンまたは入力',
                          onScanTap: () => _startScanner('toBin'),
                          onSubmitted: (_) => _transQtyFocus.requestFocus(),
                        ),
                        const SizedBox(height: 12),

                        // 予定数量 (read-only)
                        _buildReadOnlyField(
                          label: '予定数量',
                          value: line.journalQty.toStringAsFixed(0),
                          icon: Icons.inventory_2,
                        ),
                        const SizedBox(height: 12),

                        // 実際数量 (scan)
                        _buildScanField(
                          label: '実際数量',
                          controller: _transQtyController,
                          focusNode: _transQtyFocus,
                          hintText: '0',
                          keyboardType: TextInputType.number,
                          onScanTap: () => _startScanner('transQty'),
                          onSubmitted: (_) => _lotNoFocus.requestFocus(),
                        ),
                        const SizedBox(height: 12),

                        // ロット (scan)
                        _buildScanField(
                          label: 'ロット番号',
                          controller: _lotNoController,
                          focusNode: _lotNoFocus,
                          hintText: '',
                          onScanTap: () => _startScanner('lotNo'),
                        ),
                        const SizedBox(height: 12),

                        // 賞味期限 (date)
                        _buildDateField(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── Bottom buttons ─────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(color: AppColors.borderTable)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: 戻る | ← | → | 保存
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => context
                                  .go(RouteNames.binMovementList),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.btn_red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                              child: const Text('戻る',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: 'MSPGothic')),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 56,
                            child: ElevatedButton(
                              onPressed: isFirst ? null : _handlePrevious,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFirst
                                    ? Colors.grey.shade300
                                    : AppColors.gray,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                              child: const Icon(Icons.arrow_back),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 56,
                            child: ElevatedButton(
                              onPressed: isLast ? null : _handleNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isLast
                                    ? Colors.grey.shade300
                                    : AppColors.gray,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                              child: const Icon(Icons.arrow_forward),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.btnGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                              child: const Text('保存',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: 'MSPGothic')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Row 2: 棚移動完了
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleComplete,
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text(
                            '棚移動完了',
                            style: TextStyle(
                                fontSize: 16, fontFamily: 'MSPGothic'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),
              ],
            ),
    );
  }

  // ─── Widget builders ─────────────────────────────────────────

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontFamily: 'MSPGothic',
                color: AppColors.black)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.headerColor,
            border: Border.all(color: AppColors.headerColor, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.blackText),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                      fontSize: 15,
                      fontFamily: 'MSPGothic',
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanField({
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    String? hintText,
    TextInputType? keyboardType,
    VoidCallback? onScanTap,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontFamily: 'MSPGothic',
                color: AppColors.black)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: AppColors.headerColor, width: 2),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: AppColors.headerColor, width: 2),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: AppColors.primaryLight, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                onSubmitted: onSubmitted,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppColors.headerColor, width: 2),
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: onScanTap,
                color: AppColors.blackText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('賞味期限',
            style: TextStyle(
                fontSize: 13,
                fontFamily: 'MSPGothic',
                color: AppColors.black)),
        const SizedBox(height: 4),
        TextField(
          controller: _expirationDateController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'YYYY-MM-DD',
            border: const OutlineInputBorder(
              borderSide:
                  BorderSide(color: AppColors.headerColor, width: 2),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide:
                  BorderSide(color: AppColors.headerColor, width: 2),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide:
                  BorderSide(color: AppColors.primaryLight, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: const Icon(Icons.calendar_today),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_expirationDateController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(
                        () => _expirationDateController.clear()),
                  ),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: _selectDate,
                ),
              ],
            ),
          ),
          onTap: _selectDate,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _toBinController.dispose();
    _transQtyController.dispose();
    _lotNoController.dispose();
    _expirationDateController.dispose();
    _toBinFocus.dispose();
    _transQtyFocus.dispose();
    _lotNoFocus.dispose();
    _scannerController?.dispose();
    super.dispose();
  }
}
