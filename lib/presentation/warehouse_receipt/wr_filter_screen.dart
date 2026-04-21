import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme_config.dart';
import '../../core/di/injection.dart';
import '../../core/storage/local_storage.dart';
import '../../l10n/app_strings.dart';

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
  final TextEditingController _vendorFromController = TextEditingController();
  final TextEditingController _vendorToController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productCodeController = TextEditingController();
  final TextEditingController _janCodeController = TextEditingController();
  final TextEditingController _arrivalNumberController = TextEditingController();

  List<Map<String, dynamic>> _vendors = [];
  String? _selectedVendorFrom;
  String? _selectedVendorTo;
  String? _janCodeProductCode; // Store product code from JAN code
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    try {
      final localStorage = LocalStorage(sl<SharedPreferences>());
      final suppliersJson = await localStorage.getJson('dataSuppliers');
      
      if (suppliersJson != null) {
        final suppliersList = _asList(suppliersJson);
        setState(() {
          _vendors = suppliersList.map<Map<String, dynamic>>((s) {
            return {
              'id': s['id']?.toString() ?? '',
              'name': s['supplierName'] ?? '',
            };
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
    if (janCode.isEmpty) {
      setState(() {
        _janCodeProductCode = null;
      });
      return;
    }

    try {
      final localStorage = LocalStorage(sl<SharedPreferences>());
      final productsJson = await localStorage.getJson('dataProductsWithInventory');
      
      if (productsJson != null) {
        final productsList = _asList(productsJson);
        String? foundProductCode;
        
        for (var product in productsList) {
          if (product['productJanCode'] != null) {
            final janCodes = _asList(product['productJanCode']);
            final found = janCodes.any((jan) => 
              jan['janCode']?.toString().toLowerCase() == janCode.toLowerCase()
            );
            if (found) {
              foundProductCode = product['productCode']?.toString();
              break;
            }
          }
        }
        
        if (foundProductCode != null) {
          setState(() {
            _janCodeProductCode = foundProductCode;
          });
        } else {
          // Show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('プロダクトコードが存在しません'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _janCodeProductCode = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking JAN code: $e');
    }
  }

  void _startQRScanner(String field) {
    setState(() {
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
                      _handleScannedBarcode(barcode.rawValue!, field);
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

  void _handleScannedBarcode(String scannedData, String field) {
    if (field == 'janCode') {
      _janCodeController.text = scannedData;
      _checkJanCode(scannedData);
    } else if (field == 'productCode') {
      _productCodeController.text = scannedData;
    }
  }

  void _handleApplyFilter() {
    final filters = <String, dynamic>{
      'tenantId': widget.tenantId,
    };

    if (_selectedVendorFrom != null && _selectedVendorFrom!.isNotEmpty) {
      filters['vendorId'] = _selectedVendorFrom;
    }
    if (_productNameController.text.isNotEmpty) {
      filters['productName'] = _productNameController.text;
    }
    if (_productCodeController.text.isNotEmpty) {
      filters['productCode'] = _productCodeController.text;
    }
    if (_janCodeController.text.isNotEmpty) {
      // Use product code from JAN code if available
      if (_janCodeProductCode != null) {
        filters['janCode'] = _janCodeProductCode;
      } else {
        filters['janCode'] = _janCodeController.text;
      }
    }
    if (_arrivalNumberController.text.isNotEmpty) {
      filters['arrivalNumber'] = _arrivalNumberController.text;
    }

    Navigator.pop(context, filters);
  }

  void _handleClear() {
    setState(() {
      _selectedVendorFrom = null;
      _selectedVendorTo = null;
      _productNameController.clear();
      _productCodeController.clear();
      _janCodeController.clear();
      _arrivalNumberController.clear();
      _janCodeProductCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final strings = AppStrings.of(context);
            return Text('${strings.filterTitle} (${widget.company})');
          },
        ),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Supplier/Vendor (From ~ To)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orange_light,
                border: Border.all(color: AppColors.Settings_Colors_3, width: 2),
              ),
              child: const Text(
                '仕入先番号',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedVendorFrom,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.headerColor, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.headerColor, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    hint: const Text('Select Supplier'),
                    items: _vendors.map((vendor) {
                      return DropdownMenuItem<String>(
                        value: vendor['id'],
                        child: Text(vendor['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedVendorFrom = value;
                      });
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '~',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedVendorTo,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.headerColor, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.headerColor, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    hint: const Text('Select Vendor'),
                    items: _vendors.map((vendor) {
                      return DropdownMenuItem<String>(
                        value: vendor['id'],
                        child: Text(vendor['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedVendorTo = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // JAN Code
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orange_light,
                border: Border.all(color: AppColors.Settings_Colors_3, width: 2),
              ),
              child: const Text(
                '商品JANコード',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: TextField(
                    controller: _janCodeController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.headerColor, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.headerColor, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (value) {
                      _checkJanCode(value);
                    },
                    onSubmitted: (value) {
                      _checkJanCode(value);
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () => _startQRScanner('janCode'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Arrival Number
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orange_light,
                border: Border.all(color: AppColors.Settings_Colors_3, width: 2),
              ),
              child: const Text(
                '入荷予定番号',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _arrivalNumberController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.headerColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.headerColor, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
            const SizedBox(height: 24),

            // Product Code
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orange_light,
                border: Border.all(color: AppColors.Settings_Colors_3, width: 2),
              ),
              child: const Text(
                '商品番号',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: TextField(
                    controller: _productCodeController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.headerColor, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.headerColor, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () => _startQRScanner('productCode'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Product Name
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orange_light,
                border: Border.all(color: AppColors.Settings_Colors_3, width: 2),
              ),
              child: const Text(
                '商品名',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _productNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.headerColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.headerColor, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.btn_red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Builder(
                      builder: (context) {
                        final strings = AppStrings.of(context);
                        return Text(
                          strings.cancel,
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleClear,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Builder(
                      builder: (context) {
                        final strings = AppStrings.of(context);
                        return Text(
                          strings.clear,
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleApplyFilter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.btn_blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Builder(
                      builder: (context) {
                        final strings = AppStrings.of(context);
                        return Text(
                          strings.apply,
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _vendorFromController.dispose();
    _vendorToController.dispose();
    _productNameController.dispose();
    _productCodeController.dispose();
    _janCodeController.dispose();
    _arrivalNumberController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }
}
