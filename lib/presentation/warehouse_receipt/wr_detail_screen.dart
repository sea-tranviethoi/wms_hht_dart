import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/di/injection.dart';
import '../../data/datasources/remote/wr_remote_datasource.dart';
import '../../data/models/warehouse_receipt/receipt_line.dart';
import '../../routes/route_names.dart';
import 'package:go_router/go_router.dart';
import '../widgets/form_widgets.dart';

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
  String _selectedStatus = '通常'; // 通常 (Normal), NG, 不足 (Shortage)
  ReceiptLine? _currentLine;
  List<ReceiptLine> _lines = [];
  bool _isLoading = true;
  final List<File> _capturedImages = [];
  MobileScannerController? _scannerController;

  String? _topMessage;
  Color _topColor = Colors.green;
  Timer? _topTimer;

  void _showTopNotification(String message, Color color) {
    _topTimer?.cancel();
    setState(() { _topMessage = message; _topColor = color; });
    _topTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _topMessage = null);
    });
  }

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
        _showTopNotification('明細の読み込みに失敗しました: $e', AppColors.settingsColor7);
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

    // Map status: 1=通常 (Normal), 2=NG, 3=不足 (Shortage)
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
      _showTopNotification('実際数量を入力してください', AppColors.settingsColor7);
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

    _showTopNotification('保存しました', AppColors.settingsColor5);

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
      backgroundColor: AppColors.white,
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
                      Text(
                        '明細データがありません',
                        style:
                            TextStyle(fontFamily: AppStyles.font, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _handleBackToList,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.btnRed,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('入荷一覧'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    Column(children: [
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
                          Text(
                            '入荷番号:',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: AppStyles.font,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.receiptNo,
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: AppStyles.font,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_currentIndex + 1} / ${_lines.length}',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppStyles.font,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form
                    Expanded(
                      child: Stack(
                        children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // JAN code
                            const FormLabel(label: 'JANコード'),
                            const SizedBox(height: 4),
                            FormScanField(
                              controller: _barcodeController,
                              focusNode: _barcodeFocus,
                              focusedColor: AppColors.settingsColor1,
                              hintText: '',
                              onSubmitted: _handleBarcodeSubmit,
                              onScanTap: () => _startBarcodeScanner('janCode'),
                            ),
                            const SizedBox(height: 16),

                            // Product dropdown
                            _buildProductDropdown(),
                            const SizedBox(height: 16),

                            // Planned quantity (read-only)
                            const FormLabel(label: '予定数量'),
                            const SizedBox(height: 4),
                            FormReadOnlyField(value: _orderQtyController.text, icon: Icons.shopping_cart),
                            const SizedBox(height: 16),

                            // Actual quantity
                            const FormLabel(label: '実際数量'),
                            const SizedBox(height: 4),
                            FormScanField(
                              controller: _actualQtyController,
                              focusNode: _actualQtyFocus,
                              focusedColor: AppColors.settingsColor1,
                              hintText: '0',
                              keyboardType: TextInputType.number,
                              onScanTap: () => _startBarcodeScanner('actualQty'),
                            ),
                            const SizedBox(height: 16),

                            // Expiration date
                            const FormLabel(label: '賞味期限'),
                            const SizedBox(height: 4),
                            FormDateField(
                              controller: _expirationDateController,
                              focusNode: _expirationDateFocus,
                              focusedColor: AppColors.settingsColor1,
                              onTap: _selectExpirationDate,
                            ),
                            const SizedBox(height: 16),

                            // Lot number
                            const FormLabel(label: 'ロット'),
                            const SizedBox(height: 4),
                            FormScanField(
                              controller: _lotNoController,
                              focusNode: _lotNoFocus,
                              focusedColor: AppColors.settingsColor1,
                              hintText: '',
                              onScanTap: () => _startBarcodeScanner('lotNo'),
                            ),
                            const SizedBox(height: 16),

                            // Status
                            _buildStatusDropdown(),
                            const SizedBox(height: 24),

                            // Product photo capture
                            InkWell(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.settingsColor1.withValues(alpha: 0.05),
                                  border: Border.all(
                                      color: AppColors.settingsColor1.withValues(alpha: 0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.camera_alt,
                                        color: AppColors.settingsColor1),
                                    const SizedBox(width: 8),
                                    Text(
                                      '商品写真撮り:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.settingsColor1,
                                        fontFamily: AppStyles.font,
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
                                            color: AppColors.settingsColor1,
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
                      // Floating notification below header
                      if (_topMessage != null)
                        Positioned(
                          top: 0, left: 0, right: 0,
                          child: Container(
                            color: _topColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Text(
                              _topMessage!,
                              style: const TextStyle(
                                fontFamily: AppStyles.font,
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        ], // end Stack children
                      ),   // end Stack
                    ),     // end Expanded

                    // Bottom navigation
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          border: Border(top: BorderSide(color: AppColors.light)),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: ActionButton(
                              label: '入荷一覧',
                              color: AppColors.settingsColor7,
                              onPressed: _handleBackToList,
                            )),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 52,
                              height: AppStyles.heightBottomButton,
                              child: ElevatedButton(
                                onPressed: _currentIndex > 0 ? _handlePrevious : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentIndex > 0 ? AppColors.gray : AppColors.lighter,
                                  disabledBackgroundColor: AppColors.lighter,
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: AppColors.grayTextColor,
                                  padding: EdgeInsets.zero,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Icon(Icons.arrow_back, size: 22),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 52,
                              height: AppStyles.heightBottomButton,
                              child: ElevatedButton(
                                onPressed: _currentIndex < _lines.length - 1 ? _handleNext : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentIndex < _lines.length - 1 ? AppColors.gray : AppColors.lighter,
                                  disabledBackgroundColor: AppColors.lighter,
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: AppColors.grayTextColor,
                                  padding: EdgeInsets.zero,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Icon(Icons.arrow_forward, size: 22),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: ActionButton(
                              label: '保存',
                              color: AppColors.settingsColor1,
                              onPressed: _handleSave,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                    ), // end inner Column
                  ], // end Stack
                ),
    );
  }

  // ─── Widget builders ──────────────────────────────────────────

  Widget _buildProductDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '商品',
          style: TextStyle(
              fontSize: 16, fontFamily: AppStyles.font, color: AppColors.black),
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
                  color: AppColors.textPlaceholder, fontFamily: AppStyles.font),
            ),
            items: _lines
                .map((line) => DropdownMenuItem<String>(
                      value: line.productName ?? line.productCode,
                      child: Text(
                        line.productName ?? line.productCode,
                        style: const TextStyle(fontFamily: AppStyles.font),
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

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '状態',
          style: TextStyle(
              fontSize: 16, fontFamily: AppStyles.font, color: AppColors.black),
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
                child: Text('通常', style: TextStyle(fontFamily: AppStyles.font)),
              ),
              DropdownMenuItem(
                value: 'NG',
                child: Text('NG', style: TextStyle(fontFamily: AppStyles.font)),
              ),
              DropdownMenuItem(
                value: '不足',
                child: Text('不足', style: TextStyle(fontFamily: AppStyles.font)),
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
    _topTimer?.cancel();
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
