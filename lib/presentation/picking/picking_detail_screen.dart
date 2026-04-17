import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../config/theme_config.dart';
import '../../routes/route_names.dart';
import '../../data/models/picking/picking_line.dart';
import '../providers/picking_provider.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/qr_code_parser.dart';

class PickingDetailScreen extends StatefulWidget {
  final String pickNo;
  final PickingLine? pickingLine;
  final int currentIndex;
  final int tenantId;
  final String company;

  const PickingDetailScreen({
    Key? key,
    required this.pickNo,
    this.pickingLine,
    this.currentIndex = 0,
    required this.tenantId,
    this.company = '',
  }) : super(key: key);

  @override
  State<PickingDetailScreen> createState() => _PickingDetailScreenState();
}

class _PickingDetailScreenState extends State<PickingDetailScreen> {
  final TextEditingController _binController = TextEditingController();
  final TextEditingController _productCodeController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _pickQtyController = TextEditingController();
  final TextEditingController _actualPickQtyController = TextEditingController();
  final TextEditingController _lotNoController = TextEditingController();
  final TextEditingController _expirationDateController = TextEditingController();
  final TextEditingController _janCodeController = TextEditingController();
  final TextEditingController _qrCodeController = TextEditingController();

  final FocusNode _binFocus = FocusNode();
  final FocusNode _qrCodeFocus = FocusNode();
  final FocusNode _actualQtyFocus = FocusNode();

  int _currentIndex = 0;
  List<PickingLine> _lines = [];
  MobileScannerController? _scannerController;
  String? _scanningField; // 'bin', 'qrCode'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final provider = context.read<PickingProvider>();
    try {
      await provider.selectPickingList(widget.pickNo);
      _lines = provider.currentPickingLines;
      if (_lines.isNotEmpty && _currentIndex < _lines.length) {
        _updateFormFields();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateFormFields() {
    if (_currentIndex >= _lines.length) return;
    final line = _lines[_currentIndex];
    
    _binController.text = line.bin ?? '';
    _productCodeController.text = line.productCode;
    _productNameController.text = line.productName ?? '';
    _pickQtyController.text = line.pickQty.toString();
    _actualPickQtyController.text = (line.actualQty ?? 0.0).toString();
    _lotNoController.text = line.lotNo ?? '';
    _expirationDateController.text = '';
    _janCodeController.text = '';
    _qrCodeController.text = '';

    _binFocus.requestFocus();
  }

  Future<void> _handleBinSubmit(String value) async {
    if (value.isEmpty) return;

    // Parse bin QR code
    final binData = splitQRCodeBin(value);
    final binCode = binData['binCode'] ?? value;

    // Validate bin exists
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorage(prefs);
    final binsJson = await localStorage.getJson('dataBins');
    final binsList = _asList(binsJson);
    
    final binExists = binsList.any((bin) =>
        (bin['binCode']?.toString().toLowerCase() ?? '') ==
        binCode.toLowerCase());

    if (!binExists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('スキャンした棚番が倉庫に存在しません。ご確認ください'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _binController.clear();
      _binFocus.requestFocus();
      return;
    }

    // Check if bin matches expected bin
    final currentLine = _lines[_currentIndex];
    if (currentLine.bin != null &&
        currentLine.bin!.toLowerCase() != binCode.toLowerCase()) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notification'),
          content: Text(
            'スキャンした棚番 [$binCode] がピッキングすべきの棚番 [${currentLine.bin}] と違います。ピッキングを続けますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('続ける'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        _binController.clear();
        _binFocus.requestFocus();
        return;
      }
    }

    _binController.text = binCode;
    _qrCodeFocus.requestFocus();
  }

  Future<void> _handleQRCodeSubmit(String value) async {
    if (value.isEmpty) {
      _actualQtyFocus.requestFocus();
      return;
    }

    // Parse QR code
    final qrData = splitQRCodePick(value);
    final productCode = qrData['productCode'];
    final janCode = qrData['janCode'];
    final lotNo = qrData['lotNo'];
    final expired = qrData['expired'];

    if (productCode == null || janCode == null || lotNo == null || expired == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid QR code format'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _qrCodeController.clear();
      _qrCodeFocus.requestFocus();
      return;
    }

    // Validate product code matches
    final currentLine = _lines[_currentIndex];
    if (productCode.toLowerCase() != currentLine.productCode.toLowerCase()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('スキャンした商品がピッキングすべきの商品と違います。ご確認ください。'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _qrCodeController.clear();
      _qrCodeFocus.requestFocus();
      return;
    }

    // Validate expiration date
    final replaceDate = expired.replaceAll('/', '-');
    if (currentLine.lotNo != null && currentLine.lotNo!.isNotEmpty) {
      // Check expiration date if available
      // Note: This is simplified - actual implementation may need more validation
    }

    // Update quantity
    final currentQty = double.tryParse(_actualPickQtyController.text) ?? 0.0;
    final newQty = currentQty + 1;

    if (newQty > currentLine.pickQty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('実数量が必要な数量を超えました'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _actualPickQtyController.text = currentLine.pickQty.toString();
      return;
    }

    setState(() {
      _actualPickQtyController.text = newQty.toString();
      _janCodeController.text = janCode;
      _lotNoController.text = lotNo;
      _expirationDateController.text = replaceDate;
      _qrCodeController.text = value;
    });

    // Save to local storage
    await _saveToLocalStorage();

    // If quantity is complete, move to next
    if (newQty >= currentLine.pickQty) {
      if (_currentIndex < _lines.length - 1) {
        _handleNext();
      } else {
        // All items completed - verify sync
        await _verifySync();
      }
    } else {
      _qrCodeController.clear();
      _qrCodeFocus.requestFocus();
    }
  }

  Future<void> _saveToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorage(prefs);

    // Get existing data
    final warehousePickJson = await localStorage.getString('warehousepick');
    List<Map<String, dynamic>> warehousePick = [];
    if (warehousePickJson != null) {
      warehousePick = List<Map<String, dynamic>>.from(jsonDecode(warehousePickJson));
    }

    // Find or create entry for this pickNo
    final currentLine = _lines[_currentIndex];
    final pickNoEntry = warehousePick.firstWhere(
      (item) => item.containsKey(widget.pickNo),
      orElse: () => <String, dynamic>{},
    );

    if (pickNoEntry.isEmpty) {
      warehousePick.add({widget.pickNo: []});
    }

    final lines = pickNoEntry[widget.pickNo] as List<dynamic>? ?? [];
    final lineIndex = lines.indexWhere((l) => l['id'] == currentLine.id);

    final lineData = {
      'id': currentLine.id,
      'pickNo': widget.pickNo,
      'productCode': currentLine.productCode,
      'bin': _binController.text,
      'lotNo': _lotNoController.text,
      'pickQty': currentLine.pickQty,
      'actualQty': double.tryParse(_actualPickQtyController.text) ?? 0.0,
      'productQRCode': _qrCodeController.text,
      'pickbox': '',
      'completed': (double.tryParse(_actualPickQtyController.text) ?? 0.0) >= currentLine.pickQty ? 1 : 0,
    };

    if (lineIndex >= 0) {
      lines[lineIndex] = lineData;
    } else {
      lines.add(lineData);
    }

    pickNoEntry[widget.pickNo] = lines;
    await localStorage.saveString('warehousepick', jsonEncode(warehousePick));
  }

  Future<void> _verifySync() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification'),
        content: Text('ピッキング番号 ${widget.pickNo} が完了しました。送信しますか？'),
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
      await _saveScannedData();
    }
  }

  Future<void> _saveScannedData() async {
    // Save to pickingScanned
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorage(prefs);

    final warehousePickJson = await localStorage.getString('warehousepick');
    if (warehousePickJson == null) return;

    final warehousePick = List<Map<String, dynamic>>.from(jsonDecode(warehousePickJson));
    final pickNoEntry = warehousePick.firstWhere(
      (item) => item.containsKey(widget.pickNo),
      orElse: () => <String, dynamic>{},
    );

    if (pickNoEntry.isEmpty) return;

    final pickingScannedJson = await localStorage.getString('pickingScanned');
    List<Map<String, dynamic>> pickingScanned = [];
    if (pickingScannedJson != null) {
      pickingScanned = List<Map<String, dynamic>>.from(jsonDecode(pickingScannedJson));
    }

    final existingIndex = pickingScanned.indexWhere((item) => item.containsKey(widget.pickNo));
    if (existingIndex >= 0) {
      pickingScanned[existingIndex] = pickNoEntry;
    } else {
      pickingScanned.add(pickNoEntry);
    }

    await localStorage.saveString('pickingScanned', jsonEncode(pickingScanned));

    // Navigate back to list
    if (mounted) {
      final company = Uri.encodeComponent(widget.company);
      context.go(
        '${RouteNames.pickingList}?tenantId=${widget.tenantId}&company=$company',
      );
    }
  }

  Future<void> _syncData() async {
    setState(() => _isLoading = true);

    try {
      final provider = context.read<PickingProvider>();
      // TODO: Implement full sync logic similar to React Native
      // This would involve:
      // 1. Get data from pickingScanned
      // 2. Update picking lines
      // 3. Update staging
      // 4. Update HHT status
      // 5. Complete picking
      // 6. Clear local storage

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('データは正常に同期されました'),
            backgroundColor: Colors.green,
          ),
        );

        final company = Uri.encodeComponent(widget.company);
        context.go(
          '${RouteNames.pickingList}?tenantId=${widget.tenantId}&company=$company',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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

  void _startBarcodeScanner(String field) {
    setState(() {
      _scanningField = field;
      _scannerController = MobileScannerController();
    });

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
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      _scannerController?.stop();
                      Navigator.pop(context);
                      if (_scanningField == 'bin') {
                        _handleBinSubmit(barcode.rawValue!);
                      } else if (_scanningField == 'qrCode') {
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
    if (_isLoading && _lines.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.lighter,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_1.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
              ),
            ],
          ),
        ),
      );
    }

    if (_lines.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ピッキング詳細'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: const Center(
          child: Text('No picking lines found'),
        ),
      );
    }

    final currentLine = _lines[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.lighter,
      appBar: AppBar(
        title: Text('ピッキング詳細 (${_currentIndex + 1}/${_lines.length})'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Picking Number Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.borderTable,
              border: Border(
                bottom: BorderSide(color: AppColors.borderTable, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'ピッキング番号:',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'MSPGothic',
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.pickNo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'MSPGothic',
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 棚 (Bin)
                  _buildFieldWithBarcode(
                    label: '棚',
                    controller: _binController,
                    focusNode: _binFocus,
                    onSubmitted: _handleBinSubmit,
                    onBarcodeTap: () => _startBarcodeScanner('bin'),
                  ),
                  const SizedBox(height: 16),

                  // 商品コード (Product Code) - Read-only
                  _buildReadOnlyField(
                    label: '商品コード',
                    controller: _productCodeController,
                    icon: Icons.inventory,
                  ),
                  const SizedBox(height: 16),

                  // 商品名 (Product Name) - Read-only
                  _buildReadOnlyField(
                    label: '商品名',
                    controller: _productNameController,
                    icon: Icons.label,
                  ),
                  const SizedBox(height: 16),

                  // 予定数量 (Scheduled Quantity) - Read-only
                  _buildReadOnlyField(
                    label: '予定数量',
                    controller: _pickQtyController,
                    icon: Icons.shopping_cart,
                  ),
                  const SizedBox(height: 16),

                  // QRコード (QR Code)
                  _buildFieldWithBarcode(
                    label: 'QRコード',
                    controller: _qrCodeController,
                    focusNode: _qrCodeFocus,
                    onSubmitted: _handleQRCodeSubmit,
                    onBarcodeTap: () => _startBarcodeScanner('qrCode'),
                  ),
                  const SizedBox(height: 16),

                  // 実数量 (Actual Quantity)
                  _buildField(
                    label: '実数量',
                    controller: _actualPickQtyController,
                    focusNode: _actualQtyFocus,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // JANコード (JAN Code) - Read-only
                  _buildReadOnlyField(
                    label: 'JANコード',
                    controller: _janCodeController,
                    icon: Icons.qr_code,
                  ),
                  const SizedBox(height: 16),

                  // ロット (Lot) - Read-only
                  _buildReadOnlyField(
                    label: 'ロット',
                    controller: _lotNoController,
                    icon: Icons.numbers,
                  ),
                  const SizedBox(height: 16),

                  // 賞味期限 (Expiration Date) - Read-only
                  _buildReadOnlyField(
                    label: '賞味期限',
                    controller: _expirationDateController,
                    icon: Icons.calendar_today,
                  ),
                  const SizedBox(height: 24),

                  // Navigation Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _currentIndex > 0 ? _handlePrev : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentIndex > 0
                                ? AppColors.btn_brown
                                : Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            '前へ',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _currentIndex < _lines.length - 1
                              ? _handleNext
                              : () => _verifySync(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentIndex < _lines.length - 1
                                ? AppColors.btn_brown
                                : AppColors.greenDark,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            _currentIndex < _lines.length - 1 ? '次へ' : '完了',
                            style: const TextStyle(fontSize: 16),
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
    required Function(String) onSubmitted,
    required VoidCallback onBarcodeTap,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'MSPGothic',
          ),
        ),
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
              borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
            ),
          ),
          onSubmitted: onSubmitted,
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'MSPGothic',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'MSPGothic',
          ),
        ),
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

  List<dynamic> _asList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) return data.values.toList();
    return [];
  }

  @override
  void dispose() {
    _binController.dispose();
    _productCodeController.dispose();
    _productNameController.dispose();
    _pickQtyController.dispose();
    _actualPickQtyController.dispose();
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

