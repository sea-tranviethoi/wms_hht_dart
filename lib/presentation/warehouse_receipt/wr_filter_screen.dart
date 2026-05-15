import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/injection.dart';
import '../../core/storage/local_storage.dart';

class WRFilterScreen extends StatefulWidget {
  final int tenantId;
  final String company;

  const WRFilterScreen({
    super.key,
    required this.tenantId,
    this.company = '',
  });

  @override
  State<WRFilterScreen> createState() => _WRFilterScreenState();
}

class _WRFilterScreenState extends State<WRFilterScreen> {
  final _janCodeCtrl        = TextEditingController();
  final _arrivalNumberCtrl  = TextEditingController();
  final _productCodeCtrl    = TextEditingController();
  final _productNameCtrl    = TextEditingController();

  List<Map<String, dynamic>> _vendors = [];
  String? _selectedVendorFrom;
  String? _selectedVendorTo;
  String? _janCodeProductCode;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  @override
  void dispose() {
    _janCodeCtrl.dispose();
    _arrivalNumberCtrl.dispose();
    _productCodeCtrl.dispose();
    _productNameCtrl.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    try {
      final localStorage = LocalStorage(sl<SharedPreferences>());
      final suppliersJson = await localStorage.getJson('dataSuppliers');
      if (suppliersJson != null) {
        final list = _asList(suppliersJson);
        setState(() {
          _vendors = list.map<Map<String, dynamic>>((s) => {
            'id': s['id']?.toString() ?? '',
            'name': s['supplierName'] ?? '',
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading vendors: $e');
    }
  }

  List<dynamic> _asList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) return data.values.toList();
    return [];
  }

  Future<void> _checkJanCode(String janCode) async {
    if (janCode.isEmpty) { setState(() => _janCodeProductCode = null); return; }
    try {
      final localStorage = LocalStorage(sl<SharedPreferences>());
      final productsJson = await localStorage.getJson('dataProductsWithInventory');
      if (productsJson != null) {
        final list = _asList(productsJson);
        for (var product in list) {
          if (product['productJanCode'] != null) {
            final found = _asList(product['productJanCode'])
                .any((jan) => jan['janCode']?.toString().toLowerCase() == janCode.toLowerCase());
            if (found) {
              setState(() => _janCodeProductCode = product['productCode']?.toString());
              return;
            }
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('プロダクトコードが存在しません', style: TextStyle(fontFamily: 'MSPGothic')),
            backgroundColor: AppColors.settingsColor7,
          ));
        }
        setState(() => _janCodeProductCode = null);
      }
    } catch (e) {
      debugPrint('Error checking JAN code: $e');
    }
  }

  void _startQRScanner(String field) {
    _scannerController = MobileScannerController();
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
                  for (final barcode in capture.barcodes) {
                    if (barcode.rawValue != null) {
                      _scannerController?.stop();
                      Navigator.pop(context);
                      _handleScannedBarcode(barcode.rawValue!, field);
                      break;
                    }
                  }
                },
              ),
              Positioned(
                top: 16, right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () { _scannerController?.stop(); Navigator.pop(context); },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleScannedBarcode(String value, String field) {
    if (field == 'janCode') {
      _janCodeCtrl.text = value;
      _checkJanCode(value);
    } else if (field == 'productCode') {
      _productCodeCtrl.text = value;
    }
  }

  void _handleApplyFilter() {
    final filters = <String, dynamic>{'tenantId': widget.tenantId};
    if (_selectedVendorFrom != null && _selectedVendorFrom!.isNotEmpty)
      filters['vendorId'] = _selectedVendorFrom;
    if (_productNameCtrl.text.isNotEmpty)
      filters['productName'] = _productNameCtrl.text;
    if (_productCodeCtrl.text.isNotEmpty)
      filters['productCode'] = _productCodeCtrl.text;
    if (_janCodeCtrl.text.isNotEmpty)
      filters['janCode'] = _janCodeProductCode ?? _janCodeCtrl.text;
    if (_arrivalNumberCtrl.text.isNotEmpty)
      filters['arrivalNumber'] = _arrivalNumberCtrl.text;
    Navigator.pop(context, filters);
  }

  void _handleClear() {
    setState(() {
      _selectedVendorFrom = null;
      _selectedVendorTo   = null;
      _janCodeProductCode = null;
    });
    _janCodeCtrl.clear();
    _arrivalNumberCtrl.clear();
    _productCodeCtrl.clear();
    _productNameCtrl.clear();
  }

  // ─── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.settingsColor1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '絞り込み (${widget.company})',
          style: const TextStyle(
            fontFamily: 'MSPGothic',
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 仕入先番号 From
                  _buildLabel('仕入先番号（開始）'),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    value: _selectedVendorFrom,
                    hint: '開始仕入先を選択',
                    onChanged: (v) => setState(() => _selectedVendorFrom = v),
                  ),
                  const SizedBox(height: 12),

                  // 仕入先番号 To
                  _buildLabel('仕入先番号（終了）'),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    value: _selectedVendorTo,
                    hint: '終了仕入先を選択',
                    onChanged: (v) => setState(() => _selectedVendorTo = v),
                  ),
                  const SizedBox(height: 16),

                  // 商品JANコード
                  _buildLabel('商品JANコード'),
                  const SizedBox(height: 6),
                  _buildScanField(controller: _janCodeCtrl, field: 'janCode',
                      onChanged: _checkJanCode),
                  const SizedBox(height: 16),

                  // 入荷予定番号
                  _buildLabel('入荷予定番号'),
                  const SizedBox(height: 6),
                  _buildTextField(controller: _arrivalNumberCtrl),
                  const SizedBox(height: 16),

                  // 商品番号
                  _buildLabel('商品番号'),
                  const SizedBox(height: 6),
                  _buildScanField(controller: _productCodeCtrl, field: 'productCode'),
                  const SizedBox(height: 16),

                  // 商品名
                  _buildLabel('商品名'),
                  const SizedBox(height: 6),
                  _buildTextField(controller: _productNameCtrl),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Bottom bar ──────────────────────────────────────────
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.light)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildButton(
                      label: '戻る',
                      icon: Icons.arrow_back,
                      color: AppColors.settingsColor7,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildButton(
                      label: 'クリア',
                      icon: Icons.clear_all,
                      color: AppColors.gray,
                      onPressed: _handleClear,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildButton(
                      label: '適用',
                      icon: Icons.check,
                      color: AppColors.settingsColor1,
                      onPressed: _handleApplyFilter,
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

  // ─── Helpers ───────────────────────────────────────────────────

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'MSPGothic',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.grayTextColor,
        ),
      );

  InputDecoration _fieldDecoration() => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.lighter,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.light),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.light),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.settingsColor1, width: 2),
        ),
      );

  Widget _buildTextField({required TextEditingController controller}) =>
      TextField(
        controller: controller,
        style: const TextStyle(fontFamily: 'MSPGothic', fontSize: 15),
        decoration: _fieldDecoration(),
      );

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) =>
      DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: _fieldDecoration(),
        hint: Text(hint,
            style: const TextStyle(fontFamily: 'MSPGothic', fontSize: 14,
                color: AppColors.grayTextColor)),
        style: const TextStyle(fontFamily: 'MSPGothic', fontSize: 15,
            color: AppColors.blackTextColor),
        items: _vendors.map((v) => DropdownMenuItem<String>(
          value: v['id'],
          child: Text(v['name'], overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: onChanged,
      );

  Widget _buildScanField({
    required TextEditingController controller,
    required String field,
    ValueChanged<String>? onChanged,
  }) =>
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontFamily: 'MSPGothic', fontSize: 15),
              decoration: _fieldDecoration(),
              onChanged: onChanged,
              onSubmitted: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.lighter,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: () => _startQRScanner(field),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.light),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.qr_code_scanner,
                    color: AppColors.grayTextColor, size: 22),
              ),
            ),
          ),
        ],
      );

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) =>
      SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 1,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontFamily: 'MSPGothic',
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ),
      );
}
