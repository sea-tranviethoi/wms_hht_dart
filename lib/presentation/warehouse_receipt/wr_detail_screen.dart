import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../config/theme_config.dart';
import '../../core/di/injection.dart';
import '../../data/datasources/remote/wr_remote_datasource.dart';
import '../../data/models/warehouse_receipt/receipt_line.dart';
import '../../routes/route_names.dart';
import 'package:go_router/go_router.dart';

class WRDetailsScreen extends StatefulWidget {
  /// Receipt number — used for display and to load lines
  final String receiptNo;

  /// Display-only supplier name (passed from list screen)
  final String? supplierName;

  final int tenantId;

  const WRDetailsScreen({
    super.key,
    required this.receiptNo,
    this.supplierName,
    this.tenantId = 0,
  });

  @override
  State<WRDetailsScreen> createState() => _WRDetailsScreenState();
}

class _WRDetailsScreenState extends State<WRDetailsScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _orderQtyController = TextEditingController();
  final TextEditingController _actualQtyController = TextEditingController();
  final TextEditingController _lotNoController = TextEditingController();
  final TextEditingController _expirationDateController =
      TextEditingController();

  final FocusNode _barcodeFocus = FocusNode();
  final FocusNode _actualQtyFocus = FocusNode();
  final FocusNode _lotNoFocus = FocusNode();
  final FocusNode _expirationDateFocus = FocusNode();

  int _currentIndex = 0;
  String _selectedStatus = '通常'; // 通常, NG, 不足
  ReceiptLine? _currentLine;
  List<ReceiptLine> _lines = [];
  bool _isLoading = true;
  List<File> _capturedImages = [];
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLines());
  }

  Future<void> _loadLines() async {
    setState(() => _isLoading = true);
    try {
      final lines = await sl<WRRemoteDataSource>()
          .getLinesByReceiptNo(widget.receiptNo);
      if (mounted) {
        setState(() {
          _lines = lines.where((l) => !l.isDeleted).toList();
          _isLoading = false;
          if (_lines.isNotEmpty) {
            _currentLine = _lines[_currentIndex];
            _updateFormFields();
          }
        });
        _barcodeFocus.requestFocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('明細の読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateFormFields() {
    if (_currentLine == null) return;
    _productNameController.text = _currentLine!.productName ?? '';
    _orderQtyController.text = _currentLine!.orderQty.toString();
    _actualQtyController.text =
        _currentLine!.transQty?.toStringAsFixed(0) ?? '0';
    _lotNoController.text = _currentLine!.lotNo ?? '';
    _expirationDateController.text = _currentLine!.expirationDate ?? '';

    // Map status: 1=通常, 2=NG, 3=不足
    _selectedStatus = switch (_currentLine!.status) {
      2 => 'NG',
      3 => '不足',
      _ => '通常',
    };
  }

  Future<void> _handleBarcodeSubmit(String barcode) async {
    if (barcode.isEmpty) return;
    _barcodeController.clear();
    _actualQtyFocus.requestFocus();
  }

  void _startBarcodeScanner(String field) {
    setState(() => _scannerController = MobileScannerController());
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                      Navigator.pop(context);
                      _handleScannedData(bc.rawValue!, field);
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

  void _handleScannedData(String data, String field) {
    setState(() {
      if (field == 'janCode') {
        _barcodeController.text = data;
      } else if (field == 'actualQty') {
        _actualQtyController.text = data;
      } else if (field == 'lotNo') {
        _lotNoController.text = data;
      }
    });
  }

  Future<void> _selectExpirationDate() async {
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null && mounted) {
      setState(() => _capturedImages.add(File(image.path)));
    }
  }

  void _handlePrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _currentLine = _lines[_currentIndex];
        _updateFormFields();
      });
      _barcodeFocus.requestFocus();
    }
  }

  void _handleNext() {
    if (_currentIndex < _lines.length - 1) {
      setState(() {
        _currentIndex++;
        _currentLine = _lines[_currentIndex];
        _updateFormFields();
      });
      _barcodeFocus.requestFocus();
    }
  }

  Future<void> _handleSave() async {
    if (_currentLine == null) return;
    if (_actualQtyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('実際数量を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final statusValue = switch (_selectedStatus) {
      'NG' => 2,
      '不足' => 3,
      _ => 1,
    };

    setState(() {
      _currentLine = _currentLine!.copyWith(
        transQty: double.tryParse(_actualQtyController.text),
        lotNo: _lotNoController.text,
        expirationDate: _expirationDateController.text,
        status: statusValue,
      );
      _lines[_currentIndex] = _currentLine!;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存しました'), backgroundColor: Colors.green),
    );

    if (_currentIndex < _lines.length - 1) {
      _handleNext();
    }
  }

  void _handleBackToList() {
    context.go(
      '${RouteNames.warehouseReceiptList}'
      '?tenantId=${widget.tenantId}'
      '&company=${Uri.encodeComponent(widget.supplierName ?? '')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lighter,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo_1.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox(width: 100, height: 100),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryLight),
                  ),
                ],
              ),
            )
          : _lines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '明細データがありません',
                        style:
                            TextStyle(fontFamily: 'MSPGothic', fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _handleBackToList,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.btn_red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('入荷一覧'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Receipt Number Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.borderTable,
                        border: Border(
                          bottom:
                              BorderSide(color: AppColors.borderTable),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '入荷番号:',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'MSPGothic',
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.receiptNo,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'MSPGothic',
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_currentIndex + 1} / ${_lines.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'MSPGothic',
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // JANコード
                            _buildFieldWithBarcode(
                              label: 'JANコード',
                              controller: _barcodeController,
                              focusNode: _barcodeFocus,
                              hintText: '',
                              onSubmitted: _handleBarcodeSubmit,
                              onBarcodeTap: () =>
                                  _startBarcodeScanner('janCode'),
                            ),
                            const SizedBox(height: 16),

                            // 商品 dropdown
                            _buildProductDropdown(),
                            const SizedBox(height: 16),

                            // 予定数量 (read-only)
                            _buildReadOnlyField(
                              label: '予定数量',
                              controller: _orderQtyController,
                              icon: Icons.shopping_cart,
                            ),
                            const SizedBox(height: 16),

                            // 実際数量
                            _buildFieldWithBarcode(
                              label: '実際数量',
                              controller: _actualQtyController,
                              focusNode: _actualQtyFocus,
                              hintText: '0',
                              keyboardType: TextInputType.number,
                              onBarcodeTap: () =>
                                  _startBarcodeScanner('actualQty'),
                            ),
                            const SizedBox(height: 16),

                            // 賞味期限
                            _buildDateField(),
                            const SizedBox(height: 16),

                            // ロット
                            _buildFieldWithBarcode(
                              label: 'ロット',
                              controller: _lotNoController,
                              focusNode: _lotNoFocus,
                              hintText: '',
                              onBarcodeTap: () =>
                                  _startBarcodeScanner('lotNo'),
                            ),
                            const SizedBox(height: 16),

                            // 状態
                            _buildStatusDropdown(),
                            const SizedBox(height: 24),

                            // 商品写真撮り
                            InkWell(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  border: Border.all(
                                      color: Colors.blue.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.camera_alt,
                                        color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      '商品写真撮り:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue.shade700,
                                        fontFamily: 'MSPGothic',
                                      ),
                                    ),
                                    if (_capturedImages.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8),
                                        child: Text(
                                          '${_capturedImages.length} 枚',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (_capturedImages.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _capturedImages.length,
                                  itemBuilder: (context, idx) {
                                    return Stack(
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(
                                              right: 8),
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Image.file(
                                            _capturedImages[idx],
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close,
                                                color: Colors.red),
                                            onPressed: () {
                                              setState(() =>
                                                  _capturedImages
                                                      .removeAt(idx));
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Bottom navigation
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: AppColors.borderTable),
                        ),
                      ),
                      child: Row(
                        children: [
                          // 入荷一覧
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _handleBackToList,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.btn_red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text(
                                '入荷一覧',
                                style: TextStyle(
                                    fontSize: 16, fontFamily: 'MSPGothic'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // ← prev
                          SizedBox(
                            width: 60,
                            child: ElevatedButton(
                              onPressed:
                                  _currentIndex > 0 ? _handlePrevious : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _currentIndex > 0
                                    ? AppColors.gray
                                    : Colors.grey.shade300,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Icon(Icons.arrow_back),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // → next
                          SizedBox(
                            width: 60,
                            child: ElevatedButton(
                              onPressed:
                                  _currentIndex < _lines.length - 1
                                      ? _handleNext
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _currentIndex < _lines.length - 1
                                        ? AppColors.gray
                                        : Colors.grey.shade300,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Icon(Icons.arrow_forward),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 保存
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.btnGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text(
                                '保存',
                                style: TextStyle(
                                    fontSize: 16, fontFamily: 'MSPGothic'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // ─── Widget builders ──────────────────────────────────────────

  Widget _buildFieldWithBarcode({
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    String? hintText,
    TextInputType? keyboardType,
    VoidCallback? onBarcodeTap,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 14, fontFamily: 'MSPGothic', color: AppColors.black),
        ),
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
                onSubmitted: onSubmitted,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border:
                    Border.all(color: AppColors.headerColor, width: 2),
                color: Colors.white,
              ),
              child: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: onBarcodeTap,
                color: AppColors.blackText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '商品',
          style: TextStyle(
              fontSize: 14, fontFamily: 'MSPGothic', color: AppColors.black),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.headerColor, width: 2),
            color: AppColors.headerColor,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<String>(
            value: _productNameController.text.isNotEmpty
                ? _productNameController.text
                : null,
            isExpanded: true,
            underline: const SizedBox(),
            hint: const Text(
              '商品を選択',
              style: TextStyle(
                  color: AppColors.textPlaceholder, fontFamily: 'MSPGothic'),
            ),
            items: _lines
                .map((line) => DropdownMenuItem<String>(
                      value: line.productName ?? line.productCode,
                      child: Text(
                        line.productName ?? line.productCode,
                        style: const TextStyle(fontFamily: 'MSPGothic'),
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              final selected = _lines.firstWhere(
                (l) => (l.productName ?? l.productCode) == value,
                orElse: () => _lines[_currentIndex],
              );
              setState(() {
                _currentLine = selected;
                _currentIndex = _lines.indexOf(selected);
                _productNameController.text = value;
                _updateFormFields();
              });
            },
            icon: const Icon(Icons.arrow_drop_down),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 14, fontFamily: 'MSPGothic', color: AppColors.black),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(
              borderSide:
                  BorderSide(color: AppColors.headerColor, width: 2),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide:
                  BorderSide(color: AppColors.headerColor, width: 2),
            ),
            filled: true,
            fillColor: AppColors.headerColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            prefixIcon: icon != null ? Icon(icon) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '賞味期限',
          style: TextStyle(
              fontSize: 14, fontFamily: 'MSPGothic', color: AppColors.black),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _expirationDateController,
          focusNode: _expirationDateFocus,
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
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            prefixIcon: const Icon(Icons.calendar_today),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: _selectExpirationDate,
            ),
          ),
          onTap: _selectExpirationDate,
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '状態',
          style: TextStyle(
              fontSize: 14, fontFamily: 'MSPGothic', color: AppColors.black),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.headerColor, width: 2),
            color: AppColors.headerColor,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<String>(
            value: _selectedStatus,
            isExpanded: true,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                value: '通常',
                child: Text('通常', style: TextStyle(fontFamily: 'MSPGothic')),
              ),
              DropdownMenuItem(
                value: 'NG',
                child: Text('NG', style: TextStyle(fontFamily: 'MSPGothic')),
              ),
              DropdownMenuItem(
                value: '不足',
                child: Text('不足', style: TextStyle(fontFamily: 'MSPGothic')),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _selectedStatus = value);
            },
            icon: const Icon(Icons.arrow_drop_down),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _productNameController.dispose();
    _orderQtyController.dispose();
    _actualQtyController.dispose();
    _lotNoController.dispose();
    _expirationDateController.dispose();
    _barcodeFocus.dispose();
    _actualQtyFocus.dispose();
    _lotNoFocus.dispose();
    _expirationDateFocus.dispose();
    _scannerController?.dispose();
    super.dispose();
  }
}
