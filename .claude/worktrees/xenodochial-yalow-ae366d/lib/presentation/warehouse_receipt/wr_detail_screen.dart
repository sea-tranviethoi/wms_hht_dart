import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../core/constants/app_colors.dart';
import '../../core/di/injection.dart';
import '../../data/datasources/remote/wr_remote_datasource.dart';
import '../../data/models/warehouse_receipt/receipt_line.dart';
import '../../routes/route_names.dart';
import '../widgets/app_empty.dart';
import '../widgets/module_tinted_button.dart';
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
  final List<File> _capturedImages = [];
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
            backgroundColor: AppColors.btnRed,
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
                  icon: const Icon(Icons.close, color: AppColors.white),
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
          backgroundColor: AppColors.btnRed,
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
      const SnackBar(content: Text('保存しました'), backgroundColor: AppColors.btnGreen),
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
                        AppColors.settingsColor1),
                  ),
                ],
              ),
            )
          : _lines.isEmpty
              ? AppEmpty.list(
                  message: '明細データがありません',
                  action: ModuleTintedButton(
                    label: '入荷一覧',
                    icon: Icons.list,
                    color: AppColors.settingsColor1,
                    onPressed: _handleBackToList,
                  ),
                )
              : Column(
                  children: [
                    // Receipt Number Header — Blue tint (settingsColor1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.settingsColor1
                            .withValues(alpha: 0.08),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.settingsColor1
                                .withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '入荷番号',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'MSPGothic',
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.grayTextColor,
                                  ),
                                ),
                                Text(
                                  widget.receiptNo,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'MSPGothic',
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.blackTextColor,
                                  ),
                                ),
                                if (widget.supplierName != null &&
                                    widget.supplierName!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      widget.supplierName!,
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
                          // Page indicator badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.settingsColor1,
                                  width: 1.2),
                            ),
                            child: Text(
                              '${_currentIndex + 1} / ${_lines.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'MSPGothic',
                                fontWeight: FontWeight.w700,
                                color: AppColors.settingsColor1,
                              ),
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
                                  color: AppColors.settingsColor1.withValues(alpha: 0.08),
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
                                                color: AppColors.gray),
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
                                                color: AppColors.btnRed),
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
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          border: Border(
                            top: BorderSide(color: AppColors.light),
                          ),
                        ),
                        child: Row(
                          children: [
                            // 入荷一覧
                            Expanded(
                              child: ModuleTintedButton(
                                label: '入荷一覧',
                                icon: Icons.list,
                                color: AppColors.settingsColor1,
                                onPressed: _handleBackToList,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _NavArrowButton(
                              icon: Icons.chevron_left,
                              enabled: _currentIndex > 0,
                              onPressed: _handlePrevious,
                            ),
                            const SizedBox(width: 6),
                            _NavArrowButton(
                              icon: Icons.chevron_right,
                              enabled: _currentIndex < _lines.length - 1,
                              onPressed: _handleNext,
                            ),
                            const SizedBox(width: 6),
                            // 保存
                            Expanded(
                              child: ModuleTintedButton(
                                label: '保存',
                                icon: Icons.save,
                                color: AppColors.settingsColor1,
                                onPressed: _handleSave,
                              ),
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
              fontSize: 12,
              fontFamily: 'MSPGothic',
              fontWeight: FontWeight.w600,
              color: AppColors.grayTextColor),
        ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppColors.light, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppColors.light, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppColors.settingsColor1, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
                onSubmitted: onSubmitted,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.settingsColor1,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: onBarcodeTap,
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

  Widget _buildProductDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '商品',
          style: TextStyle(
              fontSize: 12,
              fontFamily: 'MSPGothic',
              fontWeight: FontWeight.w600,
              color: AppColors.grayTextColor),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.lighter,
            borderRadius: BorderRadius.circular(8),
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
              fontSize: 12,
              fontFamily: 'MSPGothic',
              fontWeight: FontWeight.w600,
              color: AppColors.grayTextColor),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: true,
          style: const TextStyle(
            fontFamily: 'MSPGothic',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.blackTextColor,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppColors.lighter,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.grayTextColor, size: 18)
                : null,
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
              fontSize: 12,
              fontFamily: 'MSPGothic',
              fontWeight: FontWeight.w600,
              color: AppColors.grayTextColor),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _expirationDateController,
          focusNode: _expirationDateFocus,
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.light, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.light, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: AppColors.settingsColor1, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: const Icon(Icons.calendar_today,
                color: AppColors.grayTextColor, size: 18),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_month,
                  color: AppColors.settingsColor1),
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
              fontSize: 12,
              fontFamily: 'MSPGothic',
              fontWeight: FontWeight.w600,
              color: AppColors.grayTextColor),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.lighter,
            borderRadius: BorderRadius.circular(8),
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

/// Compact prev/next arrow button — outlined Blue when enabled,
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
    final color = enabled ? AppColors.settingsColor1 : AppColors.gray;
    return SizedBox(
      width: 62,
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
                color: enabled ? AppColors.settingsColor1 : AppColors.light,
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
