import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/injection.dart';
import '../../core/storage/cache_storage.dart';
import '../../data/datasources/remote/putaway_remote_datasource.dart';
import '../../data/models/putaway/putaway_line.dart';
import '../../data/models/putaway/putaway_staging.dart';
import '../../routes/route_names.dart';
import '../widgets/app_loading.dart';
import '../widgets/module_tinted_button.dart';

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

class _PutawayDetailScreenState extends State<PutawayDetailScreen> {
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('保存しました'),
        backgroundColor: AppColors.btnGreen,
        duration: Duration(seconds: 1),
      ),
    );
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
        title: const Text('棚上げ完了'),
        content: Text(
          '${widget.productCode} — ${_editedLines.length}件の棚上げを登録しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.btnRed),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.btnGreen),
            child: const Text('完了'),
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
              masterId: l.id!,
              detailId: l.receiptLineId ?? 0,
              hhtInfo: hhtInfo,
            );
          }
        }
      }

      // 5. Complete putaway
      await remote.completePutaway();

      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('棚上げが完了しました'),
            backgroundColor: AppColors.btnGreen,
          ),
        );
        context.go(RouteNames.putawayList);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        _showError('棚上げ完了に失敗しました:\n$e');
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
                  icon: const Icon(Icons.close, color: AppColors.white),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.btnRed),
    );
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
        title: const Text('棚上げ詳細'),
        backgroundColor: AppColors.settingsColor2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.putawayList),
        ),
      ),
      body: _isSyncing
          ? AppLoading.centered(message: '棚上げ登録中...')
          : Column(
              children: [
                // ── Header ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.settingsColor2.withValues(alpha: 0.08),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.settingsColor2.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.productCode,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'MSPGothic',
                                color: AppColors.blackTextColor,
                              ),
                            ),
                            if (widget.productName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  widget.productName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'MSPGothic',
                                    color: AppColors.grayTextColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                          border: Border.all(
                              color: AppColors.settingsColor2, width: 1.2),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${_editedLines.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'MSPGothic',
                            fontWeight: FontWeight.w700,
                            color: AppColors.settingsColor2,
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
                        _buildReadOnlyField(
                          label: '棚上げNo',
                          value: line.putAwayNo,
                          icon: Icons.assignment,
                        ),
                        const SizedBox(height: 12),

                        // 予定数量 (read-only)
                        _buildReadOnlyField(
                          label: '予定数量',
                          value: line.journalQty.toStringAsFixed(0),
                          icon: Icons.inventory_2,
                        ),
                        const SizedBox(height: 12),

                        // 棚 (bin) — scan
                        _buildScanField(
                          label: '棚番号',
                          controller: _binController,
                          focusNode: _binFocus,
                          hintText: 'バーコードでスキャンまたは入力',
                          onScanTap: () => _startScanner('bin'),
                          onSubmitted: (_) => _transQtyFocus.requestFocus(),
                        ),
                        const SizedBox(height: 12),

                        // 実際数量 — scan
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

                        // ロット — scan
                        _buildScanField(
                          label: 'ロット番号',
                          controller: _lotNoController,
                          focusNode: _lotNoFocus,
                          hintText: '',
                          onScanTap: () => _startScanner('lotNo'),
                        ),
                        const SizedBox(height: 12),

                        // 賞味期限 — date picker
                        _buildDateField(),
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
                      border: Border(
                          top: BorderSide(color: AppColors.light)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row 1: 戻る | ← | → | 保存
                        Row(
                          children: [
                            Expanded(
                              child: ModuleTintedButton(
                                label: '戻る',
                                icon: Icons.arrow_back,
                                color: AppColors.settingsColor2,
                                onPressed: () =>
                                    context.go(RouteNames.putawayList),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _NavArrowButton(
                              icon: Icons.chevron_left,
                              enabled: !isFirst,
                              onPressed: _handlePrevious,
                            ),
                            const SizedBox(width: 6),
                            _NavArrowButton(
                              icon: Icons.chevron_right,
                              enabled: !isLast,
                              onPressed: _handleNext,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ModuleTintedButton(
                                label: '保存',
                                icon: Icons.save,
                                color: AppColors.settingsColor2,
                                onPressed: _handleSave,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Row 2: 棚上げ完了 — module color filled
                        ModuleFilledButton(
                          label: '棚上げ完了',
                          icon: Icons.check_circle_outline,
                          color: AppColors.settingsColor2,
                          onPressed: _handleComplete,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ─── Widget builders ──────────────────────────────────────────

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
                fontSize: 12,
                fontFamily: 'MSPGothic',
                fontWeight: FontWeight.w600,
                color: AppColors.grayTextColor)),
        const SizedBox(height: 4),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.lighter,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.grayTextColor),
                const SizedBox(width: 8),
              ],
              Text(
                value,
                style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'MSPGothic',
                    fontWeight: FontWeight.w600,
                    color: AppColors.blackTextColor),
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
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.light, width: 1),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontFamily: 'MSPGothic',
                fontWeight: FontWeight.w600,
                color: AppColors.grayTextColor)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                style: const TextStyle(
                  fontFamily: 'MSPGothic',
                  fontSize: 15,
                  color: AppColors.blackTextColor,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: true,
                  fillColor: AppColors.white,
                  border: fieldBorder,
                  enabledBorder: fieldBorder,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppColors.settingsColor2, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
                onSubmitted: onSubmitted,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.settingsColor2,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: onScanTap,
                borderRadius: BorderRadius.circular(8),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.qr_code_scanner,
                      color: AppColors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField() {
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.light, width: 1),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('賞味期限',
            style: TextStyle(
                fontSize: 12,
                fontFamily: 'MSPGothic',
                fontWeight: FontWeight.w600,
                color: AppColors.grayTextColor)),
        const SizedBox(height: 4),
        TextField(
          controller: _expirationDateController,
          readOnly: true,
          style: const TextStyle(
            fontFamily: 'MSPGothic',
            fontSize: 15,
            color: AppColors.blackTextColor,
          ),
          decoration: InputDecoration(
            hintText: 'YYYY-MM-DD',
            filled: true,
            fillColor: AppColors.white,
            border: fieldBorder,
            enabledBorder: fieldBorder,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: AppColors.settingsColor2, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: const Icon(Icons.calendar_today,
                color: AppColors.grayTextColor, size: 18),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_expirationDateController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear,
                        size: 18, color: AppColors.gray),
                    onPressed: () =>
                        setState(() => _expirationDateController.clear()),
                  ),
                IconButton(
                  icon: const Icon(Icons.calendar_month,
                      color: AppColors.settingsColor2),
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

/// Compact prev/next arrow button — outlined module color when enabled,
/// neutral disabled state. Sized 62×44 to fit between primary buttons.
class _NavArrowButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _NavArrowButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.settingsColor2 : AppColors.gray;
    return SizedBox(
      width: 62, // +30% so với 48 trước đó
      height: 44,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: enabled ? AppColors.settingsColor2 : AppColors.light,
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 24, color: color),
          ),
        ),
      ),
    );
  }
}
