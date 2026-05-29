import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/di/injection.dart';
import '../../core/storage/cache_storage.dart';
import '../../data/datasources/remote/putaway_remote_datasource.dart';
import '../../data/models/putaway/putaway_line.dart';
import '../../data/models/putaway/putaway_staging.dart';
import '../../routes/route_names.dart';
import '../widgets/form_widgets.dart';
import '../widgets/top_notification_mixin.dart';

/// 棚上げ詳細 — Phase 5b
/// 商品ごとの棚上げ明細を一覧表示し、bin・数量・ロット・期限を入力して完了登録する。
class PutawayDetailScreen extends StatefulWidget {
  final String productCode;
  final String productName;
  final List<PutawayLine> lines;

  const PutawayDetailScreen({
    super.key,
    required this.productCode,
    required this.productName,
    required this.lines,
  });

  @override
  State<PutawayDetailScreen> createState() => _PutawayDetailScreenState();
}

class _PutawayDetailScreenState extends State<PutawayDetailScreen>
    with TopNotificationMixin {
  // ─── Controllers ─────────────────────────────────────────────
  final TextEditingController _binController = TextEditingController();
  final TextEditingController _transQtyController = TextEditingController();
  final TextEditingController _lotNoController = TextEditingController();
  final TextEditingController _expirationDateController =
      TextEditingController();

  // ─── Focus ───────────────────────────────────────────────────
  final FocusNode _binFocus = FocusNode();
  final FocusNode _transQtyFocus = FocusNode();
  final FocusNode _lotNoFocus = FocusNode();

  // ─── State ───────────────────────────────────────────────────
  int _currentIndex = 0;
  late List<PutawayLine> _editedLines; // in-memory edits
  MobileScannerController? _scannerController;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    // Deep copy lines so edits don't mutate the original list
    _editedLines = List.of(widget.lines);
    _updateFormFields();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _binFocus.requestFocus());
  }

  // ─── Form helpers ─────────────────────────────────────────────

  PutawayLine get _current => _editedLines[_currentIndex];

  void _updateFormFields() {
    final line = _current;
    _binController.text = line.bin ?? '';
    _transQtyController.text =
        line.transQty?.toStringAsFixed(0) ?? line.journalQty.toStringAsFixed(0);
    _lotNoController.text = line.lotNo ?? '';
    _expirationDateController.text = line.expirationDate ?? '';
  }

  void _saveCurrentToMemory() {
    _editedLines[_currentIndex] = _current.copyWith(
      bin: _binController.text.trim(),
      transQty: double.tryParse(_transQtyController.text) ?? _current.journalQty,
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
    _binFocus.requestFocus();
  }

  void _handleNext() {
    if (_currentIndex >= _editedLines.length - 1) return;
    _saveCurrentToMemory();
    setState(() {
      _currentIndex++;
      _updateFormFields();
    });
    _binFocus.requestFocus();
  }

  // ─── Save (in-memory) ─────────────────────────────────────────

  void _handleSave() {
    final bin = _binController.text.trim();
    if (bin.isEmpty) {
      _showError('棚番号を入力してください');
      return;
    }
    _saveCurrentToMemory();
    showTopNotification('保存しました', AppColors.settingsColor2,
        duration: const Duration(seconds: 1));
    if (_currentIndex < _editedLines.length - 1) _handleNext();
  }

  // ─── Complete (sync all → API) ────────────────────────────────

  Future<void> _handleComplete() async {
    // Validate all lines have a bin
    final missing = _editedLines
        .where((l) => (l.bin == null || l.bin!.isEmpty))
        .map((l) => l.putAwayNo)
        .toList();
    if (missing.isNotEmpty) {
      _showError('棚番号が未入力の明細があります:\n${missing.join(', ')}');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('棚上げ完了', style: TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeDialogTitle)),
        content: Text(
          '${widget.productCode} — ${_editedLines.length}件の棚上げを登録しますか？',
          style: const TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeDialogContent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.grayTextColor),
            child: const Text('キャンセル', style: TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeDialogAction)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.settingsColor2),
            child: const Text('完了', style: TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeDialogAction)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSyncing = true);
    try {
      final remote = sl<PutawayRemoteDataSource>();
      final hhtInfo = sl<CacheStorage>().getString('hhtInfo') ?? '';

      // Group edited lines by putAwayNo
      final grouped = <String, List<PutawayLine>>{};
      for (final line in _editedLines) {
        grouped.putIfAbsent(line.putAwayNo, () => []).add(line);
      }

      for (final entry in grouped.entries) {
        final putAwayNo = entry.key;
        final linesForNo = entry.value;

        // 1. Delete existing staging
        final existing = await remote.getStagingByNo(putAwayNo);
        for (final s in existing) {
          await remote.deleteStaging(s);
        }

        // 2. Build new staging list
        final stagingList = linesForNo.map((l) {
          return PutawayStaging(
            putAwayNo: l.putAwayNo,
            productCode: l.productCode,
            unitId: l.unitId,
            journalQty: l.journalQty,
            transQty: l.transQty ?? l.journalQty,
            bin: l.bin ?? '',
            status: 0,
            lotNo: l.lotNo,
            expirationDate: l.expirationDate,
            putAwayLineId: l.id,
          );
        }).toList();

        // 3. Add new staging
        await remote.addStagingRange(stagingList);

        // 4. Update HHT status for each line
        for (final l in linesForNo) {
          if (l.id != null) {
            await remote.updateHHTStatus(
              status: 1,
              masterId: l.id,
              detailId: l.receiptLineId,
              hhtInfo: hhtInfo,
            );
          }
        }
      }

      // 5. Complete putaway
      await remote.completePutaway();

      if (mounted) {
        setState(() => _isSyncing = false);
        showTopNotification('棚上げが完了しました', AppColors.settingsColor2);
        context.go(RouteNames.putawayList);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        _showError('棚上げ完了に失敗しました: ${friendlyError(e)}');
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
        case 'bin':
          _binController.text = value;
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
        _expirationDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────

  void _showError(String msg) {
    showTopNotification(msg, AppColors.settingsColor7);
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final line = _current;
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == _editedLines.length - 1;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('棚上げ詳細', style: AppStyles.appBarTitle),
        backgroundColor: AppColors.settingsColor2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white, size: AppStyles.sizeAppBarIcon),
          onPressed: () => context.go(RouteNames.putawayList),
        ),
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
                        strokeWidth: AppStyles.widthSpinnerStroke),
                  ),
                  SizedBox(height: 8),
                  Text('棚上げ登録中...',
                      style: TextStyle(
                          fontFamily: AppStyles.font,
                          fontSize: AppStyles.sizeBody)),
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
                    color: AppColors.lighter,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.productCode,
                              style: TextStyle(
                                fontSize: AppStyles.sizeAppBar,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppStyles.font,
                                color: AppColors.black,
                              ),
                            ),
                            if (widget.productName.isNotEmpty)
                              Text(
                                widget.productName,
                                style: const TextStyle(
                                  fontSize: AppStyles.sizeBody,
                                  fontFamily: AppStyles.font,
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
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.light, width: 1),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${_editedLines.length}',
                          style: const TextStyle(
                            fontSize: AppStyles.sizeCounter,
                            fontFamily: AppStyles.font,
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
                        // 棚上げNo (read-only)
                        const FormLabel(label: '棚上げNo'),
                        const SizedBox(height: 4),
                        FormReadOnlyField(value: line.putAwayNo, icon: Icons.assignment),
                        const SizedBox(height: 12),

                        // 予定数量 (read-only)
                        const FormLabel(label: '予定数量'),
                        const SizedBox(height: 4),
                        FormReadOnlyField(value: line.journalQty.toStringAsFixed(0), icon: Icons.inventory_2),
                        const SizedBox(height: 12),

                        // 棚 (bin) — scan
                        const FormLabel(label: '棚番号'),
                        const SizedBox(height: 4),
                        FormScanField(
                          controller: _binController,
                          focusNode: _binFocus,
                          focusedColor: AppColors.settingsColor2,
                          hintText: 'バーコードでスキャンまたは入力',
                          onScanTap: () => _startScanner('bin'),
                          onSubmitted: (_) => _transQtyFocus.requestFocus(),
                        ),
                        const SizedBox(height: 12),

                        // 実際数量 — scan
                        const FormLabel(label: '実際数量'),
                        const SizedBox(height: 4),
                        FormScanField(
                          controller: _transQtyController,
                          focusNode: _transQtyFocus,
                          focusedColor: AppColors.settingsColor2,
                          hintText: '0',
                          keyboardType: TextInputType.number,
                          onScanTap: () => _startScanner('transQty'),
                          onSubmitted: (_) => _lotNoFocus.requestFocus(),
                        ),
                        const SizedBox(height: 12),

                        // ロット — scan
                        const FormLabel(label: 'ロット番号'),
                        const SizedBox(height: 4),
                        FormScanField(
                          controller: _lotNoController,
                          focusNode: _lotNoFocus,
                          focusedColor: AppColors.settingsColor2,
                          hintText: '',
                          onScanTap: () => _startScanner('lotNo'),
                        ),
                        const SizedBox(height: 12),

                        // 賞味期限 — date picker
                        const FormLabel(label: '賞味期限'),
                        const SizedBox(height: 4),
                        FormDateField(
                          controller: _expirationDateController,
                          focusedColor: AppColors.settingsColor2,
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
                        // Row 1: 戻る | ← | → | 保存
                        Row(
                          children: [
                            Expanded(child: ActionButton(
                              label: '戻る',
                              color: AppColors.settingsColor7,
                              onPressed: () => context.go(RouteNames.putawayList),
                            )),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 52,
                              height: AppStyles.heightBottomButton,
                              child: ElevatedButton(
                                onPressed: isFirst ? null : _handlePrevious,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFirst ? AppColors.gray : AppColors.settingsColor2,
                                  disabledBackgroundColor: AppColors.gray,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Icon(Icons.arrow_back, size: AppStyles.sizeNavButtonIcon),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 52,
                              height: AppStyles.heightBottomButton,
                              child: ElevatedButton(
                                onPressed: isLast ? null : _handleNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isLast ? AppColors.gray : AppColors.settingsColor2,
                                  disabledBackgroundColor: AppColors.gray,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Icon(Icons.arrow_forward, size: AppStyles.sizeNavButtonIcon),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: ActionButton(
                              label: '保存',
                              color: AppColors.settingsColor2,
                              onPressed: _handleSave,
                            )),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Row 2: 棚上げ完了
                        SizedBox(
                          width: double.infinity,
                          child: ActionButton.icon(
                            label: '棚上げ完了',
                            icon: Icons.check_circle_outline,
                            color: AppColors.settingsColor2,
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
    _binController.dispose();
    _transQtyController.dispose();
    _lotNoController.dispose();
    _expirationDateController.dispose();
    _binFocus.dispose();
    _transQtyFocus.dispose();
    _lotNoFocus.dispose();
    _scannerController?.dispose();
    super.dispose();
  }
}
