import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/di/injection.dart';
import '../../core/storage/cache_storage.dart';
import '../../data/datasources/remote/bundle_remote_datasource.dart';
import '../../data/models/bundle/bundle_line.dart';
import '../../routes/route_names.dart';
import '../../core/utils/qr_code_parser.dart';
import '../widgets/form_widgets.dart';
import '../widgets/top_notification_mixin.dart';

/// Bundle detail screen — standalone, no Provider/BLoC needed
class BundleDetailScreen extends StatefulWidget {
  final String transNo;
  final BundleLine? bundleLine;
  final int currentIndex;
  final List<BundleLine> allLines;

  const BundleDetailScreen({
    super.key,
    required this.transNo,
    this.bundleLine,
    this.currentIndex = 0,
    this.allLines = const [],
  });

  @override
  State<BundleDetailScreen> createState() => _BundleDetailScreenState();
}

class _BundleDetailScreenState extends State<BundleDetailScreen>
    with TopNotificationMixin {
  final _binCtrl = TextEditingController();
  final _productCodeCtrl = TextEditingController();
  final _productNameCtrl = TextEditingController();
  final _demandQtyCtrl = TextEditingController();
  final _actualQtyCtrl = TextEditingController();
  final _lotNoCtrl = TextEditingController();
  final _expirationDateCtrl = TextEditingController();
  final _janCodeCtrl = TextEditingController();
  final _qrCodeCtrl = TextEditingController();

  final _binFocus = FocusNode();
  final _qrFocus = FocusNode();
  final _actualQtyFocus = FocusNode();

  late int _currentIndex;
  late List<BundleLine> _lines;
  MobileScannerController? _scannerController;
  String? _scanningField;
  bool _isSyncing = false;

  final Map<int, Map<String, dynamic>> _scanData = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _lines = widget.allLines.isNotEmpty
        ? widget.allLines
        : (widget.bundleLine != null ? [widget.bundleLine!] : []);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateFormFields());
  }

  @override
  void dispose() {
    _binCtrl.dispose();
    _productCodeCtrl.dispose();
    _productNameCtrl.dispose();
    _demandQtyCtrl.dispose();
    _actualQtyCtrl.dispose();
    _lotNoCtrl.dispose();
    _expirationDateCtrl.dispose();
    _janCodeCtrl.dispose();
    _qrCodeCtrl.dispose();
    _binFocus.dispose();
    _qrFocus.dispose();
    _actualQtyFocus.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  // ─── Form helpers ─────────────────────────────────────────────

  void _updateFormFields() {
    if (_lines.isEmpty || _currentIndex >= _lines.length) return;
    final line = _lines[_currentIndex];
    final saved = _scanData[_currentIndex];

    _binCtrl.text = saved?['bin'] ?? line.bin ?? '';
    _productCodeCtrl.text = line.productCode;
    _productNameCtrl.text = line.productName ?? '';
    _demandQtyCtrl.text = line.demandQty.toStringAsFixed(0);
    _actualQtyCtrl.text =
        (saved?['actualQty'] as double? ?? line.actualQty)
            .toStringAsFixed(0);
    _lotNoCtrl.text = saved?['lotNo'] ?? line.lotNo ?? '';
    _expirationDateCtrl.text =
        saved?['expirationDate'] ?? line.expirationDate ?? '';
    _janCodeCtrl.text = saved?['janCode'] ?? '';
    _qrCodeCtrl.text = saved?['qrCode'] ?? '';

    _binFocus.requestFocus();
  }

  void _saveScanField(String key, dynamic value) {
    _scanData[_currentIndex] ??= {};
    _scanData[_currentIndex]![key] = value;
  }

  void _saveScanData(double actualQty, String janCode, String lotNo,
      String expirationDate, String qrCode) {
    _scanData[_currentIndex] = {
      'bin': _binCtrl.text,
      'actualQty': actualQty,
      'janCode': janCode,
      'lotNo': lotNo,
      'expirationDate': expirationDate,
      'qrCode': qrCode,
    };
  }

  // ─── Scan handlers ────────────────────────────────────────────

  void _handleBinSubmit(String value) {
    if (value.isEmpty) return;
    final binData = splitQRCodeBin(value);
    final binCode = binData['binCode'] ?? value;
    _binCtrl.text = binCode;
    _saveScanField('bin', binCode);
    _qrFocus.requestFocus();
  }

  void _handleQRCodeSubmit(String value) {
    if (value.isEmpty) {
      _actualQtyFocus.requestFocus();
      return;
    }
    final qrData = splitQRCodePick(value);
    final productCode = qrData['productCode'];
    final janCode = qrData['janCode'];
    final lotNo = qrData['lotNo'];
    final expired = qrData['expired'];

    if (productCode == null ||
        janCode == null ||
        lotNo == null ||
        expired == null) {
      _showSnack('QRコードのフォーマットが正しくありません', isError: true);
      _qrCodeCtrl.clear();
      _qrFocus.requestFocus();
      return;
    }

    final currentLine = _lines[_currentIndex];
    if (productCode.toLowerCase() !=
        currentLine.productCode.toLowerCase()) {
      _showSnack('スキャンした商品が事前セットすべきの商品と違います。ご確認ください。',
          isError: true);
      _qrCodeCtrl.clear();
      _qrFocus.requestFocus();
      return;
    }

    final currentQty = double.tryParse(_actualQtyCtrl.text) ?? 0.0;
    final newQty = currentQty + 1;

    if (newQty > currentLine.demandQty) {
      _showSnack('実数量が必要な数量を超えました', isError: true);
      _actualQtyCtrl.text = currentLine.demandQty.toStringAsFixed(0);
      return;
    }

    setState(() {
      _actualQtyCtrl.text = newQty.toStringAsFixed(0);
      _janCodeCtrl.text = janCode;
      _lotNoCtrl.text = lotNo;
      _expirationDateCtrl.text = expired.replaceAll('/', '-');
      _qrCodeCtrl.text = value;
    });

    _saveScanData(newQty, janCode, lotNo, expired.replaceAll('/', '-'), value);

    if (newQty >= currentLine.demandQty) {
      if (_currentIndex < _lines.length - 1) {
        _handleNext();
      } else {
        _verifyComplete();
      }
    } else {
      _qrCodeCtrl.clear();
      _qrFocus.requestFocus();
    }
  }

  // ─── Navigation ───────────────────────────────────────────────

  void _handleNext() {
    if (_currentIndex < _lines.length - 1) {
      setState(() {
        _currentIndex++;
        _updateFormFields();
      });
    }
  }

  void _handlePrev() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _updateFormFields();
      });
    }
  }

  Future<void> _verifyComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認', style: TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeItemTitle)),
        content: Text(
          '事前セット ${widget.transNo} が完了しました。送信しますか？',
          style: const TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeBodyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.grayTextColor),
            child: const Text('いいえ', style: TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeBodyText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.settingsColor4),
            child: const Text('はい', style: TextStyle(fontFamily: AppStyles.font, fontSize: AppStyles.sizeBodyText)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _syncData();
    } else if (mounted) {
      context.go(RouteNames.bundleList);
    }
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);
    try {
      final hhtInfo = sl<CacheStorage>().getString('hhtInfo') ?? '';

      // Build lines according to the InventBundlesLineDTO schema
      final lines = _lines.asMap().entries.map((e) {
        final i = e.key;
        final line = e.value;
        final data = _scanData[i] ?? {};
        final m = <String, dynamic>{
          'transNo': widget.transNo,
          'productCode': line.productCode,
          'bin': data['bin'] ?? line.bin ?? '',
          'lotNo': data['lotNo'] ?? line.lotNo ?? '',
          'demandQty': line.demandQty,
          'actualQty': data['actualQty'] ?? line.actualQty,
          'status': line.status,
          'expirationDate':
              data['expirationDate'] ?? line.expirationDate,
          'location': line.location,
          'unitId': line.unitId,
        };
        // Omit id when null — the server cannot bind "id": null to a Guid
        if (line.id != null) m['id'] = line.id;
        return m;
      }).toList();

      // Server binds one InventBundleDTO (object) that contains the inventBundleLines array
      final payload = <String, dynamic>{
        'transNo': widget.transNo,
        'status': 1, // EnumStatusBundle: completed
        'hhtStatus': 1, // EnumHHTStatus
        if (hhtInfo.isNotEmpty) 'hhtInfo': hhtInfo,
        'inventBundleLines': lines,
      };

      await sl<BundleRemoteDataSource>().uploadFromHandheld(payload);
      if (mounted) {
        _showSnack('データは正常に同期されました', isError: false);
        context.go(RouteNames.bundleList);
      }
    } catch (e) {
      if (mounted) _showSnack('同期に失敗しました: ${friendlyError(e)}', isError: true);
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    showTopNotification(
      message,
      isError ? AppColors.settingsColor7 : AppColors.settingsColor5,
      duration: const Duration(seconds: 2),
    );
  }

  void _startBarcodeScanner(String field) {
    setState(() {
      _scanningField = field;
      _scannerController = MobileScannerController();
    });
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          height: 400,
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  for (final barcode in capture.barcodes) {
                    if (barcode.rawValue != null) {
                      _scannerController?.stop();
                      Navigator.pop(context);
                      if (_scanningField == 'bin') {
                        _handleBinSubmit(barcode.rawValue!);
                      } else {
                        _handleQRCodeSubmit(barcode.rawValue!);
                      }
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
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_lines.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.settingsColor4,
          title: const Text('事前セット詳細', style: AppStyles.appBarTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white, size: AppStyles.sizeTopBarIcon),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text('明細データがありません',
              style: TextStyle(fontFamily: AppStyles.font)),
        ),
      );
    }

    if (_isSyncing) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: SizedBox(
            width: AppStyles.sizeSpinner,
            height: AppStyles.sizeSpinner,
            child: CircularProgressIndicator(
              color: AppColors.settingsColor4,
              strokeWidth: AppStyles.widthSpinnerStroke,
            ),
          ),
        ),
      );
    }

    final line = _lines[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.settingsColor4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white, size: AppStyles.sizeTopBarIcon),
          onPressed: () => context.pop(),
        ),
        title: Text('事前セット詳細 (${_currentIndex + 1}/${_lines.length})', style: AppStyles.appBarTitle),
      ),
      body: Stack(
        children: [
          Column(
        children: [
          // ── Header ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.lighter,
            child: Row(
              children: [
                const Text('事前セット:',
                    style: TextStyle(
                        fontFamily: AppStyles.font,
                        fontSize: AppStyles.sizeInfoText,
                        color: AppColors.grayTextColor)),
                const SizedBox(width: 8),
                Text(
                  widget.transNo,
                  style: const TextStyle(
                      fontFamily: AppStyles.font,
                      fontSize: AppStyles.sizeInfoText,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackTextColor),
                ),
                const Spacer(),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: line.actualQty >= line.demandQty
                        ? AppColors.wageningenGreen.withOpacity(0.15)
                        : AppColors.settingsColor4.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: line.actualQty >= line.demandQty
                          ? AppColors.wageningenGreen
                          : AppColors.settingsColor4,
                    ),
                  ),
                  child: Text(
                    line.actualQty >= line.demandQty ? '完了' : '未対応',
                    style: TextStyle(
                      fontFamily: AppStyles.font,
                      fontSize: AppStyles.sizeSubText,
                      fontWeight: FontWeight.bold,
                      color: line.actualQty >= line.demandQty
                          ? AppColors.wageningenGreen
                          : AppColors.settingsColor4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.light),

          // ── Form fields ───────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FormLabel(label: '棚番'),
                  const SizedBox(height: 4),
                  FormScanField(
                    controller: _binCtrl,
                    focusNode: _binFocus,
                    focusedColor: AppColors.settingsColor4,
                    onScanTap: () => _startBarcodeScanner('bin'),
                    onSubmitted: _handleBinSubmit,
                  ),
                  const SizedBox(height: 14),
                  const FormLabel(label: '商品コード'),
                  const SizedBox(height: 4),
                  FormReadOnlyField(value: _productCodeCtrl.text, icon: Icons.inventory_2_outlined),
                  const SizedBox(height: 14),
                  const FormLabel(label: '商品名'),
                  const SizedBox(height: 4),
                  FormReadOnlyField(value: _productNameCtrl.text, icon: Icons.label_outline),
                  const SizedBox(height: 14),
                  const FormLabel(label: '需要数量'),
                  const SizedBox(height: 4),
                  FormReadOnlyField(value: _demandQtyCtrl.text, icon: Icons.shopping_cart_outlined),
                  const SizedBox(height: 14),
                  const FormLabel(label: 'QRコード'),
                  const SizedBox(height: 4),
                  FormScanField(
                    controller: _qrCodeCtrl,
                    focusNode: _qrFocus,
                    focusedColor: AppColors.settingsColor4,
                    onScanTap: () => _startBarcodeScanner('qrCode'),
                    onSubmitted: _handleQRCodeSubmit,
                  ),
                  const SizedBox(height: 14),
                  const FormLabel(label: '実数量'),
                  const SizedBox(height: 4),
                  FormScanField(
                    controller: _actualQtyCtrl,
                    focusNode: _actualQtyFocus,
                    focusedColor: AppColors.settingsColor4,
                    keyboardType: TextInputType.number,
                    showScanButton: false,
                  ),
                  const SizedBox(height: 14),
                  const FormLabel(label: 'JANコード'),
                  const SizedBox(height: 4),
                  FormReadOnlyField(value: _janCodeCtrl.text, icon: Icons.qr_code),
                  const SizedBox(height: 14),
                  const FormLabel(label: 'ロット'),
                  const SizedBox(height: 4),
                  FormReadOnlyField(value: _lotNoCtrl.text, icon: Icons.numbers),
                  const SizedBox(height: 14),
                  const FormLabel(label: '賞味期限'),
                  const SizedBox(height: 4),
                  FormReadOnlyField(value: _expirationDateCtrl.text, icon: Icons.calendar_today),
                ],
              ),
            ),
          ),

          // ── Bottom bar ────────────────────────────────────────
          BottomActionBar(
            children: [
              Expanded(child: ActionButton(
                label: '前へ',
                color: _currentIndex > 0 ? AppColors.settingsColor4 : AppColors.gray,
                onPressed: _currentIndex > 0 ? _handlePrev : null,
              )),
              Expanded(child: ActionButton(
                label: _currentIndex < _lines.length - 1 ? '次へ' : '完了・送信',
                color: _currentIndex < _lines.length - 1
                    ? AppColors.settingsColor4
                    : AppColors.settingsColor5,
                onPressed: _currentIndex < _lines.length - 1
                    ? _handleNext
                    : _verifyComplete,
              )),
            ],
          ),
        ],
      ),
          buildTopBanner(),
        ],
      ),
    );
  }

}
