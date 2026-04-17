import 'package:flutter/foundation.dart';

import '../../core/storage/local_storage.dart';
import '../../data/models/warehouse_receipt/receipt_line.dart';
import '../../data/models/warehouse_receipt/receipt_order.dart';
import '../../data/models/warehouse_receipt/receipt_staging.dart';
import '../../data/repositories/warehouse_receipt_repository.dart';

class WarehouseReceiptProvider with ChangeNotifier {
  final WarehouseReceiptRepository _repository;
  final LocalStorage _localStorage;

  WarehouseReceiptProvider(this._repository, this._localStorage);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<ReceiptOrder> _receiptOrders = [];
  List<ReceiptOrder> get receiptOrders => _receiptOrders;

  List<ReceiptLine> _receiptLines = [];
  List<ReceiptLine> get receiptLines => _receiptLines;

  List<ReceiptLine> _currentReceiptLines = [];
  List<ReceiptLine> get currentReceiptLines => _currentReceiptLines;

  ReceiptOrder? _selectedReceipt;
  ReceiptOrder? get selectedReceipt => _selectedReceipt;

  List<OfflineReceiptData> _offlineData = [];
  List<OfflineReceiptData> get offlineData => _offlineData;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _hhtInfo;
  String? get hhtInfo => _hhtInfo;

  /// Initialize - load HHT info and offline data
  Future<void> initialize() async {
    _hhtInfo = await _localStorage.getString('hhtInfo');
    _offlineData = await _repository.getOfflineReceiptDataList();
    notifyListeners();
  }

  /// Get offline data by tenant ID
  List<OfflineReceiptData> getOfflineDataByTenant(int tenantId) {
    return _offlineData.where((data) => data.tenantId == tenantId).toList();
  }

  /// Fetch warehouse receipt orders from API
  Future<void> fetchWarehouseReceiptOrders(int tenantId,
      {String? vendorId,
      String? janCode,
      String? productName,
      String? productCode,
      String? arrivalNumber}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch from API
      final orders = await _repository.getWarehouseReceiptOrders();
      final lines = await _repository.getWarehouseReceiptOrderLines();

      // Filter by tenant, status, and isDeleted
      var filteredOrders = orders
          .where((order) {
            final matchesTenant = order.tenantId == tenantId;
            final isNotDeleted = !order.isDeleted;
            final hasCorrectStatus = order.status == 1;
            
            final shouldInclude = (tenantId == 0 || matchesTenant) && isNotDeleted && hasCorrectStatus;
            
            if (!shouldInclude && orders.indexOf(order) < 10) {
            }
            
            return shouldInclude;
          })
          .toList();


      // Apply additional filters
      if (vendorId != null && vendorId.isNotEmpty) {
        filteredOrders = filteredOrders
            .where((order) => order.supplierId == int.tryParse(vendorId))
            .toList();
      }

      if (arrivalNumber != null && arrivalNumber.isNotEmpty) {
        filteredOrders = filteredOrders
            .where((order) =>
                order.scheduledArrivalNumber
                    ?.toLowerCase()
                    .contains(arrivalNumber.toLowerCase()) ??
                false)
            .toList();
      }

      // Filter by JAN code, productCode, or productName
      if (janCode != null && janCode.isNotEmpty) {
        // Convert JAN code to product code
        final productsJson = await _localStorage.getJson('dataProductsWithInventory');
        final productsList = _asList(productsJson);
        String? productCodeFromJan;
        
        if (productsList.isNotEmpty) {
          for (var product in productsList) {
            if (product['productJanCode'] != null) {
              final janCodes = _asList(product['productJanCode']);
              final found = janCodes.any((jan) => 
                jan['janCode']?.toString().toLowerCase() == janCode.toLowerCase()
              );
              if (found) {
                productCodeFromJan = product['productCode']?.toString();
                break;
              }
            }
          }
        }
        
        if (productCodeFromJan != null) {
          final matchingLines = lines
              .where((line) => line.productCode == productCodeFromJan)
              .toList();
          final receiptNos = matchingLines.map((line) => line.receiptNo).toSet();
          filteredOrders = filteredOrders
              .where((order) => receiptNos.contains(order.receiptNo))
              .toList();
        } else {
          filteredOrders = []; // No product found for this JAN code
        }
      }

      if (productCode != null && productCode.isNotEmpty) {
        final matchingLines = lines
            .where((line) => 
                line.productCode.toLowerCase().contains(productCode.toLowerCase()))
            .toList();
        final receiptNos = matchingLines.map((line) => line.receiptNo).toSet();
        filteredOrders = filteredOrders
            .where((order) => receiptNos.contains(order.receiptNo))
            .toList();
      }

      if (productName != null && productName.isNotEmpty) {
        // Search by product name
        final productsJson = await _localStorage.getJson('dataProducts');
        final productsList = _asList(productsJson);
        List<String> matchingProductCodes = [];
        
        if (productsList.isNotEmpty) {
          for (var product in productsList) {
            final name = product['productName']?.toString().toLowerCase() ?? '';
            if (name.contains(productName.toLowerCase())) {
              final code = product['productCode']?.toString();
              if (code != null) {
                matchingProductCodes.add(code);
              }
            }
          }
        }
        
        if (matchingProductCodes.isNotEmpty) {
          final matchingLines = lines
              .where((line) => matchingProductCodes.contains(line.productCode))
              .toList();
          final receiptNos = matchingLines.map((line) => line.receiptNo).toSet();
          filteredOrders = filteredOrders
              .where((order) => receiptNos.contains(order.receiptNo))
              .toList();
        } else {
          // Also search by product code if name not found
          final matchingLines = lines
              .where((line) => 
                  line.productCode.toLowerCase().contains(productName.toLowerCase()))
              .toList();
          final receiptNos = matchingLines.map((line) => line.receiptNo).toSet();
          filteredOrders = filteredOrders
              .where((order) => receiptNos.contains(order.receiptNo))
              .toList();
        }
      }

      // Get offline scanned data
      _offlineData = await _repository.getOfflineReceiptDataList();
      final offlineScanned = _offlineData;

      // Get suppliers and products from local storage
      final suppliersJson = await _localStorage.getJson('dataSuppliers');
      final productsJson = await _localStorage.getJson('dataProducts');
      final suppliersList = _asList(suppliersJson);
      final productsList = _asList(productsJson);

      // Enrich orders with supplier names and scan status
      _receiptOrders = filteredOrders.map((order) {
        // Find supplier name
        String? supplierName;
        if (suppliersList.isNotEmpty) {
          final supplier = suppliersList.firstWhere(
            (s) => s['id'] == order.supplierId,
            orElse: () => null,
          );
          supplierName = supplier?['supplierName'];
        }

        // Determine scan status
        int scanStatus = -1;
        OfflineReceiptData? scanned;
        try {
          scanned = offlineScanned.firstWhere(
            (s) => s.warehouseReceiptNo == order.receiptNo,
          );
        } catch (e) {
          scanned = null;
        }

        if (scanned != null || order.hhtInfo == _hhtInfo) {
          scanStatus = 2; // Scanned
        } else if (order.hhtInfo != null &&
            order.hhtInfo!.isNotEmpty &&
            order.hhtInfo != _hhtInfo) {
          scanStatus = 3; // Handled by other device
        }

        // Get product names for this receipt
        final orderLines =
            lines.where((line) => line.receiptNo == order.receiptNo).toList();
        String productNames = '';
        if (productsList.isNotEmpty && orderLines.isNotEmpty) {
          for (var line in orderLines) {
            try {
              final product = productsList.firstWhere(
                (p) => p['productCode']?.toString() == line.productCode,
                orElse: () => <String, dynamic>{},
              );
              if (product.isNotEmpty && product['productName'] != null) {
                final productName = product['productName']?.toString() ?? '';
                if (productName.isNotEmpty) {
                  productNames += '$productName, ';
                }
              }
            } catch (e) {
            }
          }
        }

        // Remove trailing comma and space
        if (productNames.isNotEmpty && productNames.length >= 2) {
          productNames = productNames.substring(0, productNames.length - 2);
        }

        return order.copyWith(
          supplierName: supplierName,
          scanStatus: scanStatus,
          productNames: productNames,
        );
      }).toList();

      _receiptLines = lines.where((line) => !line.isDeleted).toList();

      await _repository.saveWarehouseReceiptOrders(_receiptOrders);
      await _repository.saveWarehouseReceiptLines(_receiptLines);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a receipt and load its lines
  Future<void> selectReceipt(ReceiptOrder receipt) async {
    _selectedReceipt = receipt;
    _isLoading = true;
    notifyListeners();

    try {
      // Get lines for this receipt from API (like React Native)
      final lines = await _repository.getWarehouseReceiptOrderLinesByReceiptNo(receipt.receiptNo);

      // Enrich with product names
      final productsJson = await _localStorage.getJson('dataProducts');
      final productsList = _asList(productsJson);
      if (productsList.isNotEmpty) {
        _currentReceiptLines = lines.map((line) {
          final product = productsList.firstWhere(
            (p) => p['productCode']?.toString() == line.productCode,
            orElse: () => <String, dynamic>{},
          );
          return line.copyWith(
            productName: product['productName']?.toString(),
          );
        }).toList();
      } else {
        _currentReceiptLines = lines;
      }

      // Save to local storage (like React Native)
      await _repository.saveWarehouseReceiptLineForReceipt(
        receipt.receiptNo,
        _currentReceiptLines,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check receipt status before navigation (exposed for use in UI)
  Future<bool> checkReceiptStatus(String receiptNo) async {
    try {
      final receiptOrders = await _repository.getWarehouseReceiptOrderByReceiptNo(receiptNo);
      
      if (receiptOrders.isNotEmpty) {
        final hhtInfo = await _localStorage.getString('hhtInfo') ?? '';
        
        final handledByOther = receiptOrders.where((item) {
          return (item.hhtStatus == 0 || item.hhtStatus == 1) &&
              item.hhtInfo != null &&
              item.hhtInfo!.isNotEmpty &&
              item.hhtInfo!.toLowerCase() != hhtInfo.toLowerCase();
        }).toList();
        
        return handledByOther.isNotEmpty;
      }
      return false;
    } catch (e) {
      print('Error checking receipt status: $e');
      return false;
    }
  }

  /// Get repository for direct access (exposed for use in UI)
  WarehouseReceiptRepository get repository => _repository;
  
  /// Get localStorage for direct access (exposed for use in UI)
  LocalStorage get localStorage => _localStorage;

  /// Search receipts by keyword
  Future<void> searchReceipts(String keyword, int tenantId) async {
    if (keyword.isEmpty) {
      await fetchWarehouseReceiptOrders(tenantId);
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Search in receipt numbers and supplier names
      var filtered = _receiptOrders.where((order) {
        return order.receiptNo.toLowerCase().contains(keyword.toLowerCase()) ||
            (order.supplierName
                    ?.toLowerCase()
                    .contains(keyword.toLowerCase()) ??
                false);
      }).toList();

      // If no results, search in product names/codes
      if (filtered.isEmpty) {
        final productsJson = await _localStorage.getJson('dataProducts');
        final productsList = _asList(productsJson);
        if (productsList.isNotEmpty) {
          // Search by product name
          var productMatches = productsList.where((p) =>
              p['productName']
                  ?.toLowerCase()
                  .contains(keyword.toLowerCase()) ??
              false);

          // Search by product code
          if (productMatches.isEmpty) {
            productMatches = productsList.where((p) =>
                p['productCode']
                    ?.toLowerCase()
                    .contains(keyword.toLowerCase()) ??
                false);
          }

          // Search by JAN code
          if (productMatches.isEmpty) {
            productMatches = productsList.where((p) =>
                p['janCode']?.toLowerCase().contains(keyword.toLowerCase()) ??
                false);
          }

          if (productMatches.isNotEmpty) {
            final productCodes =
                productMatches.map((p) => p['productCode']).toList();
            final matchingLines = _receiptLines
                .where((line) => productCodes.contains(line.productCode))
                .toList();
            final receiptNos =
                matchingLines.map((line) => line.receiptNo).toSet();

            filtered = _receiptOrders
                .where((order) => receiptNos.contains(order.receiptNo))
                .toList();
          }
        }
      }

      _receiptOrders = filtered;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Search failed: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sync offline data to server
  Future<bool> syncOfflineData(int tenantId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get offline data for this tenant
      final offlineDataList =
          await _repository.getOfflineReceiptDataByTenant(tenantId);

      if (offlineDataList.isEmpty) {
        _errorMessage = 'No data to sync';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      List<ReceiptStaging> stagingList = [];
      List<ProductErrorImage> errorImagesList = [];

      // Prepare staging data
      for (var offlineData in offlineDataList) {
        for (var scannedLine in offlineData.warehouseReceiptLinesScanned) {
          // Add to staging
          stagingList.add(ReceiptStaging(
            receiptNo: scannedLine.warehouseReceiptNo,
            productCode: scannedLine.productCode,
            unitId: scannedLine.unit,
            orderQty: scannedLine.status > 1 ? 0 : scannedLine.orderQty,
            transQty: scannedLine.actualQty,
            bin: scannedLine.bin,
            lotNo: scannedLine.lotNo,
            expirationDate: scannedLine.expirationDate,
            receiptLineId: scannedLine.id,
            status: scannedLine.status,
            janCode: scannedLine.janCode,
          ));

          // Prepare error images if status > 1
          if (scannedLine.status > 1 &&
              offlineData.dataImage != null &&
              offlineData.dataImage!.isNotEmpty) {
            final errorImages = offlineData.dataImage!
                .asMap()
                .entries
                .map((entry) => ErrorImageData(
                      filePath: '',
                      fileName:
                          '${DateTime.now().toString().split(' ')[0]}_${scannedLine.productCode}_ImgError${entry.key}.png',
                      imageBase64: 'data:image/png;base64,${entry.value.base64}',
                    ))
                .toList();

            errorImagesList.add(ProductErrorImage(
              receiptLineId: scannedLine.id!,
              statusError: scannedLine.status,
              errorImages: errorImages,
            ));
          }

          // Update receipt line
          ReceiptLine? originalLine;
          try {
            originalLine = offlineData.warehouseReceiptLines.firstWhere(
              (line) => line.id == scannedLine.id,
            );
          } catch (e) {
            originalLine = null;
          }

          if (originalLine != null) {
            await _repository.updateWarehouseReceiptOrderLine(
              originalLine.copyWith(
                janCode: scannedLine.janCode,
                updateOperatorId: 'HHT',
              ),
            );
          }
        }
      }

      // Delete existing staging data
      for (var staging in stagingList) {
        final existingStaging =
            await _repository.getWarehouseReceiptStagingByReceiptNo(
          staging.receiptNo,
        );
        for (var existing in existingStaging) {
          await _repository.deleteWarehouseReceiptStaging(existing);
        }
      }

      // Add new staging data
      final stagingSuccess =
          await _repository.addRangeWarehouseReceiptStaging(stagingList);

      // Upload error images
      final imagesSuccess = errorImagesList.isEmpty ||
          await _repository.uploadProductErrorImages(errorImagesList);

      if (stagingSuccess && imagesSuccess) {
        // Update HHT status for each receipt
        for (var staging in stagingList) {
          final receiptOrders =
              await _repository.getWarehouseReceiptOrderByReceiptNo(
            staging.receiptNo,
          );
          if (receiptOrders.isNotEmpty) {
            await _repository.updateHHTStatus(2, receiptOrders.first.id!, 0);
          }
        }

        // Complete warehouse receipt
        await _repository.completeWarehouseReceipt();

        // Remove offline data for this tenant
        await _repository.removeOfflineReceiptDataByTenant(tenantId);
        
        // Refresh offline data
        _offlineData = await _repository.getOfflineReceiptDataList();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Sync failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Sync failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset scanned data for a receipt
  Future<bool> resetScannedData(String receiptNo) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Remove offline data
      await _repository.removeOfflineReceiptData(receiptNo);

      // Update HHT status
      final receiptOrders =
          await _repository.getWarehouseReceiptOrderByReceiptNo(receiptNo);
      if (receiptOrders.isNotEmpty) {
        await _repository.updateHHTStatusEmpty(0, receiptOrders.first.id!, 0);
      }

      // Refresh data
      final tenantId = _selectedReceipt?.tenantId;
      if (tenantId != null) {
        await fetchWarehouseReceiptOrders(tenantId);
      }
      
      // Refresh offline data
      _offlineData = await _repository.getOfflineReceiptDataList();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Reset failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  List<dynamic> _asList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) return data.values.toList();
    return [];
  }
}


