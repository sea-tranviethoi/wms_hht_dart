import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/di/injection.dart';
import '../../../core/audio/sound_manager.dart';
import '../../../core/hardware/keyboard_event_bus.dart';
import '../../../core/hardware/keyence_scanner.dart';
import '../../../core/constants/key_codes.dart';
import '../../../core/utils/qr_code_parser.dart';
import '../../blocs/picking/picking_bloc.dart';
import '../../../data/models/picking/picking_line.dart';
import '../../../routes/route_names.dart';
import '../../widgets/top_notification_mixin.dart';

/// Port từ screens/Picking/PickingDetail.js
///
/// Màn hình xử lý từng picking line:
///   1. Scan bin (validate với expected bin)
///   2. Scan QR code sản phẩm (validate productCode + tăng qty)
///   3. Nhập actualQty thủ công nếu cần
///   4. Next / Prev để chuyển line
///   5. Hoàn thành → sync lên server
class PickingDetailScreen extends StatefulWidget {
  final String pickNo;
  final PickingLine? pickingLine;
  final int currentIndex;
  final int tenantId;
  final String company;
  final List<PickingLine> allLines;

  const PickingDetailScreen({
    super.key,
    required this.pickNo,
    this.pickingLine,
    this.currentIndex = 0,
    required this.tenantId,
    this.company = '',
    this.allLines = const [],
  });

  @override
  State<PickingDetailScreen> createState() => _PickingDetailScreenState();
}

class _PickingDetailScreenState extends State<PickingDetailScreen>
    with TopNotificationMixin {
  // ─── Controllers ─────────────────────────────────────────────
  final _binCtrl = TextEditingController();
  final _qrCtrl = TextEditingController();
  final _actualQtyCtrl = TextEditingController();

  final _binFocus = FocusNode();
  final _qrFocus = FocusNode();
  final _qtyFocus = FocusNode();

  // ─── State ────────────────────────────────────────────────────
  late int _currentIndex;
  late List<PickingLine> _lines;

  // Track scan data per line index: index → {bin, actualQty, qrCode, ...}
  final Map<int, _LineData> _lineData = {};

  late VoidCallback _unsubscribeKey;
  StreamSubscription? _scannerSub;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _lines = widget.allLines.isNotEmpty
        ? widget.allLines
        : (widget.pickingLine != null ? [widget.pickingLine!] : []);

    _unsubscribeKey = KeyboardEventBus.instance.addListener(_onHardwareKey);
    _startScanner();
    _loadCurrentLine();
  }

  @override
  void dispose() {
    _binCtrl.dispose();
    _qrCtrl.dispose();
    _actualQtyCtrl.dispose();
    _binFocus.dispose();
    _qrFocus.dispose();
    _qtyFocus.dispose();
    _unsubscribeKey();
    _scannerSub?.cancel();
    sl<KeyenceScanner>().stopRead();
    super.dispose();
  }

  // ─── Scanner ──────────────────────────────────────────────────

  Future<void> _startScanner() async {
    await sl<KeyenceScanner>().startRead();
    _scannerSub = sl<KeyenceScanner>().scanStream.listen((barcode) {
      if (barcode.isEmpty) return;
      // Determine which field is focused
      if (_binFocus.hasFocus) {
        _handleBinSubmit(barcode);
      } else {
        _handleQRSubmit(barcode);
      }
    });
  }

  // ─── Hardware key ─────────────────────────────────────────────

  bool _onHardwareKey(int keyCode) {
    // HHT scan trigger → focus on current active field and trigger scan
    if (keyCode == HardwareKeyCodes.scanTriggerLeft ||
        keyCode == HardwareKeyCodes.scanTriggerRight) {
      return true;
    }
    return false;
  }

  // ─── Load line data ───────────────────────────────────────────

  void _loadCurrentLine() {
    if (_lines.isEmpty) return;
    final line = _lines[_currentIndex];
    final saved = _lineData[_currentIndex];

    _binCtrl.text = saved?.bin ?? line.bin ?? '';
    _qrCtrl.text = saved?.qrCode ?? '';
    _actualQtyCtrl.text =
        (saved?.actualQty ?? line.actualQty ?? 0.0).toStringAsFixed(0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _binFocus.requestFocus();
    });
  }

  void _saveCurrentLine() {
    if (_lines.isEmpty) return;
    final line = _lines[_currentIndex];
    _lineData[_currentIndex] = _LineData(
      lineId: line.id ?? 0,
      productCode: line.productCode,
      bin: _binCtrl.text,
      actualQty: double.tryParse(_actualQtyCtrl.text) ?? 0.0,
      qrCode: _qrCtrl.text,
      shipmentLineId: line.shipmentLineId,
      unitId: line.unitId,
      pickQty: line.pickQty,
      lotNo: line.lotNo,
    );
  }

  // ─── Bin scan handler ─────────────────────────────────────────

  Future<void> _handleBinSubmit(String raw) async {
    if (raw.isEmpty) return;
    final parsed = splitQRCodeBin(raw);
    final binCode = parsed['binCode'] ?? raw;

    final expected = _lines[_currentIndex].bin;
    if (expected != null &&
        expected.isNotEmpty &&
        expected.toLowerCase() != binCode.toLowerCase()) {
      // Bin không khớp → hỏi confirm
      final ok = await _showConfirmDialog(
        'スキャンした棚番 [$binCode] がピッキングすべきの棚番 [$expected] と違います。続けますか？',
      );
      if (ok != true) {
        _binCtrl.clear();
        _binFocus.requestFocus();
        return;
      }
    }

    _binCtrl.text = binCode;
    await sl<SoundManager>().playCorrect();
    _qrFocus.requestFocus();
  }

  // ─── QR scan handler ──────────────────────────────────────────

  Future<void> _handleQRSubmit(String raw) async {
    if (raw.isEmpty) {
      _qtyFocus.requestFocus();
      return;
    }

    final parsed = splitQRCodePick(raw);
    final productCode = parsed['productCode'];

    if (productCode == null) {
      await sl<SoundManager>().playError();
      _showSnack('QRコードの形式が正しくありません', isError: true);
      _qrCtrl.clear();
      _qrFocus.requestFocus();
      return;
    }

    final line = _lines[_currentIndex];
    if (productCode.toLowerCase() != line.productCode.toLowerCase()) {
      await sl<SoundManager>().playError();
      _showSnack('スキャンした商品がピッキングすべき商品と違います', isError: true);
      _qrCtrl.clear();
      _qrFocus.requestFocus();
      return;
    }

    // 数量 +1
    final current = double.tryParse(_actualQtyCtrl.text) ?? 0.0;
    final newQty = current + 1;

    if (newQty > line.pickQty) {
      await sl<SoundManager>().playWarning();
      _showSnack('実数量が必要数量を超えました', isError: true);
      _actualQtyCtrl.text = line.pickQty.toStringAsFixed(0);
      return;
    }

    setState(() {
      _actualQtyCtrl.text = newQty.toStringAsFixed(0);
      _qrCtrl.text = raw;
    });
    _saveCurrentLine();
    await sl<SoundManager>().playCorrect();

    if (newQty >= line.pickQty) {
      // Line complete → auto next or finish
      await _handleLineComplete();
    } else {
      _qrCtrl.clear();
      _qrFocus.requestFocus();
    }
  }

  // ─── Line complete ────────────────────────────────────────────

  Future<void> _handleLineComplete() async {
    _saveCurrentLine();
    if (_currentIndex < _lines.length - 1) {
      _goNext();
    } else {
      await _showSyncDialog();
    }
  }

  // ─── Navigation ───────────────────────────────────────────────

  void _goNext() {
    if (_currentIndex >= _lines.length - 1) return;
    _saveCurrentLine();
    setState(() {
      _currentIndex++;
      _loadCurrentLine();
    });
  }

  void _goPrev() {
    if (_currentIndex <= 0) return;
    _saveCurrentLine();
    setState(() {
      _currentIndex--;
      _loadCurrentLine();
    });
  }

  // ─── Sync to server ───────────────────────────────────────────

  Future<void> _showSyncDialog() async {
    final ok = await _showConfirmDialog(
      'ピッキング番号 ${widget.pickNo} が完了しました。送信しますか？',
    );
    if (ok == true && mounted) {
      _syncData();
    }
  }

  void _syncData() {
    _saveCurrentLine();
    final payloads = _lineData.entries.map((e) {
      final d = e.value;
      return StagingPayload(
        lineId: d.lineId,
        productCode: d.productCode,
        bin: d.bin,
        lotNo: d.lotNo,
        pickQty: d.pickQty,
        actualQty: d.actualQty,
        qrCode: d.qrCode,
        shipmentLineId: d.shipmentLineId,
        unitId: d.unitId,
      );
    }).toList();

    context.read<PickingBloc>().add(SyncPickingData(
          pickNo: widget.pickNo,
          stagingList: payloads,
          tenantId: widget.tenantId,
          company: widget.company,
        ));
  }

  // ─── UI helpers ───────────────────────────────────────────────

  Future<bool?> _showConfirmDialog(String message) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認', style: TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeDialogTitle)),
        content: Text(message,
            style: const TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeDialogContent)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('いいえ',
                style: TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeDialogAction)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('はい',
                style: TextStyle(
                    fontFamily: AppStyles.font,
                    fontSize: AppStyles.sizeDialogAction,
                    color: AppColors.settingsColor3,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    showTopNotification(
      msg,
      isError ? AppColors.settingsColor7 : AppColors.settingsColor5,
      duration: const Duration(seconds: 2),
    );
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<PickingBloc, PickingState>(
      listener: (context, state) {
        if (state is PickingSynced) {
          _showSnack('データは正常に同期されました');
          final c = Uri.encodeComponent(widget.company);
          context.go(
              '${RouteNames.pickingList}?tenantId=${widget.tenantId}&company=$c');
        } else if (state is PickingError) {
          _showSnack(state.message, isError: true);
        }
      },
      child: _lines.isEmpty
          ? const Scaffold(body: Center(child: Text('データがありません')))
          : _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    final line = _lines[_currentIndex];
    final total = _lines.length;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.settingsColor3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white, size: AppStyles.sizeAppBarIcon),
          onPressed: () => context.pop(),
        ),
        title: Text('ピッキング: ${widget.pickNo}  ${_currentIndex + 1}/$total', style: AppStyles.appBarTitle),
      ),
      body: Stack(
        children: [
          BlocBuilder<PickingBloc, PickingState>(
        builder: (context, state) {
          if (state is PickingSyncing) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: AppStyles.sizeSpinner,
                    height: AppStyles.sizeSpinner,
                    child: CircularProgressIndicator(
                      color: AppColors.settingsColor3,
                      strokeWidth: AppStyles.widthSpinnerStroke,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('データ同期中...',
                      style: TextStyle(
                        fontFamily: AppStyles.font,
                        fontSize: AppStyles.sizeBody,
                      )),
                ],
              ),
            );
          }
          return _buildForm(line);
        },
      ),
          buildTopBanner(),
        ],
      ),
    );
  }

  Widget _buildForm(PickingLine line) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Progress ────────────────────────────────────────
          _progressBar(),
          const SizedBox(height: 12),

          // ── Product info ────────────────────────────────────
          _infoCard(line),
          const SizedBox(height: 12),

          // ── Scan fields ─────────────────────────────────────
          _scanSection(),
          const SizedBox(height: 16),

          // ── Navigation buttons ──────────────────────────────
          _navigationButtons(line),
        ],
      ),
    );
  }

  Widget _progressBar() {
    final done = _lineData.values.where((d) => d.actualQty >= d.pickQty).length;
    final total = _lines.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('進捗: $done / $total 件完了',
                style: TextStyle(
                    fontFamily: AppStyles.font,
                    fontSize: AppStyles.sizeSub,
                    color: AppColors.grayTextColor)),
            Text('${(done / total * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontFamily: AppStyles.font,
                    fontSize: AppStyles.sizeSub,
                    fontWeight: FontWeight.bold,
                    color: AppColors.settingsColor3)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: total > 0 ? done / total : 0,
          backgroundColor: AppColors.lighter,
          color: AppColors.settingsColor3,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _infoCard(PickingLine line) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _infoRow('商品コード', line.productCode, bold: true),
            if (line.productName != null && line.productName!.isNotEmpty)
              _infoRow('商品名', line.productName!),
            if (line.bin != null && line.bin!.isNotEmpty)
              _infoRow('棚番', line.bin!),
            if (line.lotNo != null && line.lotNo!.isNotEmpty)
              _infoRow('ロット番号', line.lotNo!),
            _infoRow(
              '数量',
              '${line.pickQty.toStringAsFixed(0)} ${line.unitName ?? ''}',
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                  fontFamily: AppStyles.font,
                  fontSize: AppStyles.sizeSub,
                  color: AppColors.grayTextColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: AppStyles.font,
                fontSize: AppStyles.sizeInfo,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanSection() {
    return Column(
      children: [
        // Bin scan
        _ScanField(
          label: '棚番スキャン',
          controller: _binCtrl,
          focusNode: _binFocus,
          hintText: '棚番をスキャンまたは入力',
          icon: Icons.inventory_2_outlined,
          onSubmitted: _handleBinSubmit,
        ),
        const SizedBox(height: 8),

        // QR scan
        _ScanField(
          label: 'QRコードスキャン',
          controller: _qrCtrl,
          focusNode: _qrFocus,
          hintText: '商品QRコードをスキャン',
          icon: Icons.qr_code_scanner,
          onSubmitted: _handleQRSubmit,
        ),
        const SizedBox(height: 8),

        // Actual qty
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.format_list_numbered,
                    color: AppColors.settingsColor3),
                const SizedBox(width: 8),
                Text('実数量',
                    style: TextStyle(
                        fontFamily: AppStyles.font,
                        fontSize: AppStyles.sizeInfo,
                        color: AppColors.blackTextColor)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _actualQtyCtrl,
                    focusNode: _qtyFocus,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppStyles.font,
                      fontSize: AppStyles.sizeTitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.settingsColor3,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _navigationButtons(PickingLine line) {
    final isLast = _currentIndex == _lines.length - 1;
    final actual = double.tryParse(_actualQtyCtrl.text) ?? 0.0;
    final allDone =
        _lineData.values.every((d) => d.actualQty >= d.pickQty) &&
            actual >= line.pickQty;

    return Column(
      children: [
        Row(
          children: [
            // Prev
            if (_currentIndex > 0) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _goPrev,
                  icon: const Icon(Icons.arrow_back,
                      size: AppStyles.sizePrimaryButtonIcon),
                  label: const Text(
                    '前へ',
                    style: TextStyle(
                        fontFamily: AppStyles.font,
                        fontWeight: FontWeight.bold,
                        fontSize: AppStyles.sizePrimaryButton),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.settingsColor3,
                    side: const BorderSide(
                        color: AppColors.settingsColor3, width: 1.5),
                    minimumSize: const Size.fromHeight(AppStyles.heightPrimaryButton),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Next / Complete
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: isLast
                    ? (allDone ? _showSyncDialog : () => _handleLineComplete())
                    : _goNext,
                icon: Icon(
                  isLast
                      ? (allDone ? Icons.cloud_upload : Icons.check)
                      : Icons.arrow_forward,
                  size: AppStyles.sizePrimaryButtonIcon,
                ),
                label: Text(
                  isLast
                      ? (allDone ? '完了・送信' : '完了確認')
                      : '次へ',
                  style: const TextStyle(
                      fontFamily: AppStyles.font,
                      fontWeight: FontWeight.bold,
                      fontSize: AppStyles.sizePrimaryButton),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLast && allDone
                      ? AppColors.settingsColor5
                      : AppColors.settingsColor3,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(AppStyles.heightPrimaryButton),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Scan field widget ────────────────────────────────────────────────────────

class _ScanField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final IconData icon;
  final ValueChanged<String> onSubmitted;

  const _ScanField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.icon,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: AppColors.settingsColor3),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.done,
                onSubmitted: onSubmitted,
                style: const TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeInfo),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(
                      fontFamily: AppStyles.font,
                      fontSize: AppStyles.sizeCaption,
                      color: AppColors.grayTextColor),
                  hintText: hintText,
                  hintStyle: TextStyle(
                      fontFamily: AppStyles.font,
                      color: AppColors.gray,
                      fontSize: AppStyles.sizeCaption),
                  border: InputBorder.none,
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.gray, size: 18),
                          onPressed: () {
                            controller.clear();
                            focusNode.requestFocus();
                          },
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Line data model ──────────────────────────────────────────────────────────

class _LineData {
  final int lineId;
  final String productCode;
  final String bin;
  final double actualQty;
  final String? qrCode;
  final String? shipmentLineId;
  final int? unitId;
  final double pickQty;
  final String? lotNo;

  const _LineData({
    required this.lineId,
    required this.productCode,
    required this.bin,
    required this.actualQty,
    this.qrCode,
    this.shipmentLineId,
    this.unitId,
    required this.pickQty,
    this.lotNo,
  });
}

