import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/di/injection.dart';
import '../../data/repositories/bin_movement_repository.dart';
import '../../data/models/bin_movement/invent_transfer_line.dart';
import '../../routes/route_names.dart';
import '../widgets/form_widgets.dart';
import '../widgets/top_notification_mixin.dart';

/// Bin movement detail screen — Phase 7
/// Reviews and enters each line linked to the transfer number, then registers the bin movement as complete.
class BinMovementDetailScreen extends StatefulWidget {
  final String id;
  final String transferNo;
  final String? description;
  final List<InventTransferLine> lines;

  const BinMovementDetailScreen({
    super.key,
    required this.id,
    required this.transferNo,
    this.description,
    required this.lines,
  });

  @override
  State<BinMovementDetailScreen> createState() =>
      _BinMovementDetailScreenState();
}

class _BinMovementDetailScreenState extends State<BinMovementDetailScreen>
    with TopNotificationMixin {
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
    if (_editedLines.isNotEmpty) {
      _updateFormFields();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _toBinFocus.requestFocus());
    }
  }

  // ─── Form helpers ─────────────────────────────────────────────

  InventTransferLine get _current => _editedLines[_currentIndex];

  void _updateFormFields() {
    if (_editedLines.isEmpty) return;
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
    showTopNotification('保存しました', AppColors.settingsColor5,
        duration: const Duration(seconds: 1));
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
        title: const Text('棚移動完了', style: TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeMainTitle)),
        content: Text(
          '${widget.transferNo} — ${_editedLines.length}件の棚移動を登録しますか？',
          style: const TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeBodyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.grayTextColor),
            child: const Text('キャンセル', style: TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeBodyText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.settingsColor5),
            child: const Text('完了', style: TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeBodyText)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSyncing = true);
    try {
      final remote = sl<BinMovementRepository>();

      // 1. Update each line with new toBin/qty
      for (final l in _editedLines) {
        if (l.id == null) continue;
        await remote.updateLine({
          'id': l.id,
          'transferNo': l.transferNo,
          'productCode': l.productCode,
          'unitId': l.unitId,
          'qty': l.transQty ?? l.journalQty,
          'fromBin': l.fromBin ?? '',
          'toBin': l.toBin ?? '',
          'fromLotNo': l.lotNo,
          'toLotNo': l.lotNo,
          'status': 0,
        });
      }

      // 2. Complete transfer
      await remote.completeTransfer(widget.id);

      if (mounted) {
        setState(() => _isSyncing = false);
        showTopNotification('棚移動が完了しました', AppColors.settingsColor5);
        context.go(RouteNames.binMovementList);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        _showError('棚移動完了に失敗しました: ${friendlyError(e)}');
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
    showTopNotification(msg, AppColors.settingsColor7);
  }

  // ─── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Empty state — no lines for this transfer
    if (_editedLines.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.settingsColor5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white, size: AppStyles.sizeTopBarIcon),
            onPressed: () => context.go(RouteNames.binMovementList),
          ),
          title: const Text('棚移動詳細', style: AppStyles.appBarTitle),
        ),
        body: const Center(
          child: Text('明細データがありません',
              style: TextStyle(
                fontFamily: AppStyles.font,
                fontSize: AppStyles.sizeBodyText,
                color: AppColors.grayTextColor,
              )),
        ),
      );
    }

    final line = _current;
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == _editedLines.length - 1;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.settingsColor5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white, size: AppStyles.sizeTopBarIcon),
          onPressed: () => context.go(RouteNames.binMovementList),
        ),
        title: const Text('棚移動詳細', style: AppStyles.appBarTitle),
      ),
      body: Stack(
        children: [
          _isSyncing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: AppStyles.sizeSpinner,
                    height: AppStyles.sizeSpinner,
                    child: CircularProgressIndicator(
                      strokeWidth: AppStyles.widthSpinnerStroke,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('棚移動登録中...',
                      style: TextStyle(
                        fontFamily: AppStyles.font,
                        fontSize: AppStyles.sizeBodyText,
                      )),
                ],
              ),
            )
          : Column(
              children: [
                // ── Header ─────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  color: AppColors.lighter,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.transferNo,
                              style: const TextStyle(
                                fontSize: AppStyles.sizeBodyText,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppStyles.font,
                                color: AppColors.blackTextColor,
                              ),
                            ),
                            if (widget.description != null &&
                                widget.description!.isNotEmpty)
                              Text(
                                widget.description!,
                                style: const TextStyle(
                                  fontSize: AppStyles.sizeSubText,
                                  fontFamily: AppStyles.font,
                                  color: AppColors.grayTextColor,
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
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.light),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${_editedLines.length}',
                          style: const TextStyle(
                            fontSize: AppStyles.sizeBodyText,
                            fontFamily: AppStyles.font,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blackTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.light),

                // ── Form ───────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Product code + product name (read-only)
                        const FormLabel(label: '商品番号'),
                        const SizedBox(height: 4),
                        FormReadOnlyField(value: line.productCode, icon: Icons.inventory),
                        const SizedBox(height: 8),
                        if (line.productName != null &&
                            line.productName!.isNotEmpty) ...[
                          const FormLabel(label: '商品名'),
                          const SizedBox(height: 4),
                          FormReadOnlyField(value: line.productName!),
                          const SizedBox(height: 8),
                        ],

                        // Source bin (read-only)
                        const FormLabel(label: '移動元棚番号'),
                        const SizedBox(height: 4),
                        FormReadOnlyField(value: line.fromBin ?? '—', icon: Icons.output),
                        const SizedBox(height: 12),

                        // Arrow indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_downward,
                                color: AppColors.settingsColor5, size: AppStyles.sizeBottomButtonIcon),
                            const SizedBox(width: 6),
                            const Text('移動',
                                style: TextStyle(
                                    color: AppColors.settingsColor5,
                                    fontFamily: AppStyles.font,
                                    fontSize: AppStyles.sizeBodyText)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Destination bin (scan)
                        const FormLabel(label: '移動先棚番号'),
                        const SizedBox(height: 4),
                        FormScanField(
                          controller: _toBinController,
                          focusNode: _toBinFocus,
                          focusedColor: AppColors.settingsColor5,
                          hintText: 'バーコードでスキャンまたは入力',
                          onScanTap: () => _startScanner('toBin'),
                          onSubmitted: (_) => _transQtyFocus.requestFocus(),
                        ),
                        const SizedBox(height: 12),

                        // Planned quantity (read-only)
                        const FormLabel(label: '予定数量'),
                        const SizedBox(height: 4),
                        FormReadOnlyField(value: line.journalQty.toStringAsFixed(0), icon: Icons.inventory_2),
                        const SizedBox(height: 12),

                        // Actual quantity (scan)
                        const FormLabel(label: '実際数量'),
                        const SizedBox(height: 4),
                        FormScanField(
                          controller: _transQtyController,
                          focusNode: _transQtyFocus,
                          focusedColor: AppColors.settingsColor5,
                          hintText: '0',
                          keyboardType: TextInputType.number,
                          onScanTap: () => _startScanner('transQty'),
                          onSubmitted: (_) => _lotNoFocus.requestFocus(),
                        ),
                        const SizedBox(height: 12),

                        // Lot number (scan)
                        const FormLabel(label: 'ロット番号'),
                        const SizedBox(height: 4),
                        FormScanField(
                          controller: _lotNoController,
                          focusNode: _lotNoFocus,
                          focusedColor: AppColors.settingsColor5,
                          hintText: '',
                          onScanTap: () => _startScanner('lotNo'),
                        ),
                        const SizedBox(height: 12),

                        // Expiration date (date picker)
                        const FormLabel(label: '賞味期限'),
                        const SizedBox(height: 4),
                        FormDateField(
                          controller: _expirationDateController,
                          focusedColor: AppColors.settingsColor5,
                          onTap: _selectDate,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── Bottom buttons ─────────────────────────────
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      border: Border(top: BorderSide(color: AppColors.light)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row 1: Back | ← | → | Save
                        Row(
                          children: [
                            Expanded(child: ActionButton(
                              label: '戻る',
                              color: AppColors.settingsColor7,
                              onPressed: () => context.go(RouteNames.binMovementList),
                            )),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 52,
                              height: AppStyles.heightBottomButton,
                              child: ElevatedButton(
                                onPressed: isFirst ? null : _handlePrevious,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFirst ? AppColors.gray : AppColors.settingsColor5,
                                  disabledBackgroundColor: AppColors.gray,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Icon(Icons.arrow_back, size: AppStyles.sizeBottomButtonIcon),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 52,
                              height: AppStyles.heightBottomButton,
                              child: ElevatedButton(
                                onPressed: isLast ? null : _handleNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isLast ? AppColors.gray : AppColors.settingsColor5,
                                  disabledBackgroundColor: AppColors.gray,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Icon(Icons.arrow_forward, size: AppStyles.sizeBottomButtonIcon),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: ActionButton(
                              label: '保存',
                              color: AppColors.settingsColor5,
                              onPressed: _handleSave,
                            )),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Row 2: Bin movement complete
                        SizedBox(
                          width: double.infinity,
                          child: ActionButton.icon(
                            label: '棚移動完了',
                            icon: Icons.swap_horiz,
                            color: AppColors.settingsColor5,
                            onPressed: _handleComplete,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          buildTopBanner(),
        ],
      ),
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
