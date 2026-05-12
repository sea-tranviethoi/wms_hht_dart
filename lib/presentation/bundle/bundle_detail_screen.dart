import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/injection.dart';
import '../../data/datasources/remote/bundle_remote_datasource.dart';
import '../../data/models/bundle/bundle_line.dart';
import '../../routes/route_names.dart';
import '../../core/utils/qr_code_parser.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 事前セット詳細 — standalone, no Provider/BLoC needed (Phase 6)
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

class _BundleDetailScreenState extends State<BundleDetailScreen> {
  final TextEditingController _binController = TextEditingController();
  final TextEditingController _productCodeController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _demandQtyController = TextEditingController();
  final TextEditingController _actualQtyController = TextEditingController();
  final TextEditingController _lotNoController = TextEditingController();
  final TextEditingController _expirationDateController =
      TextEditingController();
  final TextEditingController _janCodeController = TextEditingController();
  final TextEditingController _qrCodeController = TextEditingController();

  final FocusNode _binFocus = FocusNode();
  final FocusNode _qrCodeFocus = FocusNode();
  final FocusNode _actualQtyFocus = FocusNode();

  int _currentIndex = 0;
  List<BundleLine> _lines = [];
  MobileScannerController? _scannerController;
  String? _scanningField;
  bool _isSyncing = false;

  // In-memory scan data per line index
  final Map<int, Map<String, dynamic>> _scanData = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _lines = widget.allLines.isNotEmpty
        ? widget.allLines
        : (widget.bundleLine != null ? [widget.bundleLine!] : []);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFormFields());
  }

  void _updateFormFields() {
    if (_lines.isEmpty || _currentIndex >= _lines.length) return;
    final line = _lines[_currentIndex];
    final saved = _scanData[_currentIndex];

    _binController.text = saved?['bin'] ?? line.bin ?? '';
    _productCodeController.text = line.productCode;
    _productNameController.text = line.productName ?? '';
    _demandQtyController.text = line.demandQty.toStringAsFixed(0);
    _actualQtyController.text =
        (saved?['actualQty'] as double? ?? line.actualQty)
            .toStringAsFixed(0);
    _lotNoController.text = saved?['lotNo'] ?? line.lotNo ?? '';
    _expirationDateController.text =
        saved?['expirationDate'] ?? line.expirationDate ?? '';
    _janCodeController.text = saved?['janCode'] ?? '';
    _qrCodeController.text = saved?['qrCode'] ?? '';

    _binFocus.requestFocus();
  }

  void _handleBinSubmit(String value) {
    if (value.isEmpty) return;

    final binData = splitQRCodeBin(value);
    final binCode = binData['binCode'] ?? value;
    _binController.text = binCode;
    _saveScanField('bin', binCode);
    _qrCodeFocus.requestFocus();
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
      _qrCodeController.clear();
      _qrCodeFocus.requestFocus();
      return;
    }

    final currentLine = _lines[_currentIndex];
    if (productCode.toLowerCase() !=
        currentLine.productCode.toLowerCase()) {
      _showSnack(
          'スキャンした商品が事前セットすべきの商品と違います。ご確認ください。',
          isError: true);
      _qrCodeController.clear();
      _qrCodeFocus.requestFocus();
      return;
    }

    final currentQty =
        double.tryParse(_actualQtyController.text) ?? 0.0;
    final newQty = currentQty + 1;

    if (newQty > currentLine.demandQty) {
      _showSnack('実数量が必要な数量を超えました', isError: true);
      _actualQtyController.text =
          currentLine.demandQty.toStringAsFixed(0);
      return;
    }

    setState(() {
      _actualQtyController.text = newQty.toStringAsFixed(0);
      _janCodeController.text = janCode;
      _lotNoController.text = lotNo;
      _expirationDateController.text = expired.replaceAll('/', '-');
      _qrCodeController.text = value;
    });

    _saveScanData(newQty, janCode, lotNo, expired.replaceAll('/', '-'),
        value);

    if (newQty >= currentLine.demandQty) {
      if (_currentIndex < _lines.length - 1) {
        _handleNext();
      } else {
        _verifyComplete();
      }
    } else {
      _qrCodeController.clear();
      _qrCodeFocus.requestFocus();
    }
  }

  void _saveScanField(String key, dynamic value) {
    _scanData[_currentIndex] ??= {};
    _scanData[_currentIndex]![key] = value;
  }

  void _saveScanData(double actualQty, String janCode, String lotNo,
      String expirationDate, String qrCode) {
    _scanData[_currentIndex] = {
      'bin': _binController.text,
      'actualQty': actualQty,
      'janCode': janCode,
      'lotNo': lotNo,
      'expirationDate': expirationDate,
      'qrCode': qrCode,
    };
  }

  Future<void> _verifyComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Notification'),
        content:
            Text('事前セット ${widget.transNo} が完了しました。送信しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('いいえ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('はい'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _syncData();
    } else {
      if (mounted) context.go(RouteNames.bundleList);
    }
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);

    try {
      // Build payload from scan data
      final payload = _lines.asMap().entries.map((entry) {
        final i = entry.key;
        final line = entry.value;
        final data = _scanData[i] ?? {};

        return {
          'id': line.id,
          'transNo': widget.transNo,
          'productCode': line.productCode,
          'bin': data['bin'] ?? line.bin ?? '',
          'demandQty': line.demandQty,
          'actualQty': data['actualQty'] ?? line.actualQty,
          'lotNo': data['lotNo'] ?? line.lotNo ?? '',
          'expirationDate': data['expirationDate'] ?? line.expirationDate ?? '',
          'janCode': data['janCode'] ?? '',
          'productQRCode': data['qrCode'] ?? '',
          'pickbox': '',
        };
      }).toList();

      await sl<BundleRemoteDataSource>().uploadFromHandheld(payload);

      if (mounted) {
        _showSnack('データは正常に同期されました', isError: false);
        context.go(RouteNames.bundleList);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('同期に失敗しました: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

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

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
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

  @override
  Widget build(BuildContext context) {
    if (_lines.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('事前セット詳細'),
          backgroundColor: AppColors.settingsColor4,
        ),
        body: const Center(
          child: Text('明細データがありません',
              style: TextStyle(fontFamily: 'MSPGothic')),
        ),
      );
    }

    if (_isSyncing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
            '事前セット詳細 (${_currentIndex + 1}/${_lines.length})'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.borderTable,
              border: Border(
                  bottom: BorderSide(color: AppColors.borderTable)),
            ),
            child: Row(
              children: [
                Text('事前セット:',
                    style: TextStyle(
                        fontSize: 16.sp, fontFamily: 'MSPGothic')),
                const SizedBox(width: 8),
                Text(
                  widget.transNo,
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'MSPGothic'),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFieldWithBarcode(
                    label: '棚',
                    controller: _binController,
                    focusNode: _binFocus,
                    onSubmitted: _handleBinSubmit,
                    onBarcodeTap: () => _startBarcodeScanner('bin'),
                  ),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                      '商品コード', _productCodeController,
                      Icons.inventory),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                      '商品名', _productNameController, Icons.label),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                      '需要数量', _demandQtyController,
                      Icons.shopping_cart),
                  const SizedBox(height: 16),
                  _buildFieldWithBarcode(
                    label: 'QRコード',
                    controller: _qrCodeController,
                    focusNode: _qrCodeFocus,
                    onSubmitted: _handleQRCodeSubmit,
                    onBarcodeTap: () => _startBarcodeScanner('qrCode'),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: '実数量',
                    controller: _actualQtyController,
                    focusNode: _actualQtyFocus,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                      'JANコード', _janCodeController, Icons.qr_code),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                      'ロット', _lotNoController, Icons.numbers),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                      '賞味期限', _expirationDateController,
                      Icons.calendar_today),
                  const SizedBox(height: 24),
                  // Navigation
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _currentIndex > 0 ? _handlePrev : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentIndex > 0
                                ? AppColors.btnBrown
                                : Colors.grey,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('前へ',
                              style: TextStyle(fontSize: 16.sp)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _currentIndex < _lines.length - 1
                              ? _handleNext
                              : _verifyComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _currentIndex < _lines.length - 1
                                    ? AppColors.btnBrown
                                    : AppColors.btnGreen,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            _currentIndex < _lines.length - 1
                                ? '次へ'
                                : '完了',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldWithBarcode({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required void Function(String) onSubmitted,
    required VoidCallback onBarcodeTap,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'MSPGothic')),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: onBarcodeTap,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: AppColors.primaryLight, width: 2),
            ),
          ),
          onSubmitted: onSubmitted,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'MSPGothic')),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: AppColors.primaryLight, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(
      String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'MSPGothic')),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: false,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.grey.shade200,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _binController.dispose();
    _productCodeController.dispose();
    _productNameController.dispose();
    _demandQtyController.dispose();
    _actualQtyController.dispose();
    _lotNoController.dispose();
    _expirationDateController.dispose();
    _janCodeController.dispose();
    _qrCodeController.dispose();
    _binFocus.dispose();
    _qrCodeFocus.dispose();
    _actualQtyFocus.dispose();
    _scannerController?.dispose();
    super.dispose();
  }
}
