import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../../core/storage/local_storage.dart';
import '../../data/models/putaway/putaway_line.dart';
import '../../data/models/putaway/putaway_order.dart';
import '../../data/models/putaway/putaway_staging.dart';
import '../../data/repositories/putaway_repository.dart';

class PutawayProvider with ChangeNotifier {
  final PutawayRepository _repository;
  final LocalStorage _localStorage;

  PutawayProvider(this._repository, this._localStorage);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<PutawayOrder> _putawayOrders = [];
  List<PutawayOrder> get putawayOrders => _putawayOrders;

  List<PutawayLine> _putawayLines = [];
  List<PutawayLine> get putawayLines => _putawayLines;

  // Grouped by product code: Map<String, List<PutawayLine>>
  Map<String, List<PutawayLine>> _groupedLines = {};
  Map<String, List<PutawayLine>> get groupedLines => _groupedLines;

  // Table data: [productCode, totalQty, scanStatus, scannedQty, hhtInfo, productName, receiptLineId]
  List<List<dynamic>> _tableData = [];
  List<List<dynamic>> get tableData => _tableData;

  String? _selectedProductCode;
  String? get selectedProductCode => _selectedProductCode;

  List<PutawayLine> _currentPutawayLines = [];
  List<PutawayLine> get currentPutawayLines => _currentPutawayLines;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _hhtInfo;
  String? get hhtInfo => _hhtInfo;

  /// Initialize - load HHT info
  Future<void> initialize() async {
    _hhtInfo = await _localStorage.getString('hhtInfo');
    notifyListeners();
  }

  /// Fetch putaway data and group by product code
  Future<void> fetchPutawayData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get putaway orders (filter: isDeleted = false, status = 0)
      final orders = await _repository.getPutawayOrders();
      final filteredOrders = orders
          .where((order) => !order.isDeleted && order.status == 0)
          .toList();

      // Get putaway lines (filter: isDeleted = false)
      final lines = await _repository.getPutawayLines();
      final filteredLines = lines.where((line) => !line.isDeleted).toList();

      // Filter lines that match putaway orders
      final putawayNos = filteredOrders.map((o) => o.putAwayNo).toSet();
      final matchingLines = filteredLines
          .where((line) => putawayNos.contains(line.putAwayNo))
          .toList();

      // Group by product code
      _groupedLines = {};
      for (var line in matchingLines) {
        if (!_groupedLines.containsKey(line.productCode)) {
          _groupedLines[line.productCode] = [];
        }
        _groupedLines[line.productCode]!.add(line);
      }

      // Get products from local storage
      final productsJson = await _localStorage.getJson('dataProducts');
      final productsList = _asList(productsJson);

      // Get scanned history
      final scannedHistoryJson =
          await _localStorage.getString('historyPutawayScanned');
      List<Map<String, dynamic>> scannedHistory = [];
      if (scannedHistoryJson != null) {
        scannedHistory = List<Map<String, dynamic>>.from(
            jsonDecode(scannedHistoryJson));
      }

      // Build table data
      _tableData = [];
      for (var entry in _groupedLines.entries) {
        final productCode = entry.key;
        final linesForProduct = entry.value;

        // Calculate total journalQty
        final totalQty = linesForProduct.fold<double>(
            0.0, (sum, line) => sum + line.journalQty);

        // Get receiptLineId (from first line that has it)
        final receiptLineId = linesForProduct
            .firstWhere((l) => l.receiptLineId != null,
                orElse: () => linesForProduct.first)
            .receiptLineId;

        // Check scanned history
        int scanStatus = -1; // -1: not scanned, 1: scanned, 3: handled by other
        double scannedQty = 0.0;
        String? hhtInfoOther;

        final scannedItem = scannedHistory.firstWhere(
          (item) => item['ProductCode'] == productCode,
          orElse: () => {},
        );

        if (scannedItem.isNotEmpty) {
          scannedQty = (scannedItem['TransQty'] ?? 0.0).toDouble();
          scanStatus = 1; // Scanned
        }

        // Check if handled by other device
        final lineWithHhtInfo = linesForProduct.firstWhere(
          (l) => l.hhtInfo != null && l.hhtInfo!.isNotEmpty,
          orElse: () => linesForProduct.first,
        );

        if (lineWithHhtInfo.hhtInfo != null &&
            lineWithHhtInfo.hhtInfo!.isNotEmpty) {
          if (lineWithHhtInfo.hhtInfo!.toLowerCase() ==
              _hhtInfo?.toLowerCase()) {
            scanStatus = 1; // Scanned by this device
          } else {
            scanStatus = 3; // Handled by other device
            hhtInfoOther = lineWithHhtInfo.hhtInfo;
          }
        }

        // Get product name
        String productName = '';
        if (productsList.isNotEmpty) {
          final product = productsList.firstWhere(
            (p) => p['productCode']?.toString() == productCode,
            orElse: () => <String, dynamic>{},
          );
          productName = product['productName']?.toString() ?? '';
        }

        _tableData.add([
          productCode,
          totalQty,
          scanStatus,
          scannedQty,
          hhtInfoOther ?? '',
          productName,
          receiptLineId ?? 0,
        ]);
      }

      // Sort by product code
      _tableData.sort((a, b) => a[0].toString().compareTo(b[0].toString()));

      _putawayOrders = filteredOrders;
      _putawayLines = matchingLines;

      // Save to local storage
      await _repository.savePutawayOrders(_putawayOrders);
      await _repository.savePutawayLines(_putawayLines);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      print('ERROR: Failed to load putaway data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a product and load its lines
  Future<void> selectProduct(String productCode) async {
    _selectedProductCode = productCode;
    _isLoading = true;
    notifyListeners();

    try {
      final lines = _groupedLines[productCode] ?? [];

      // Enrich with product names
      final productsJson = await _localStorage.getJson('dataProducts');
      final productsList = _asList(productsJson);
      if (productsList.isNotEmpty) {
        _currentPutawayLines = lines.map((line) {
          final product = productsList.firstWhere(
            (p) => p['productCode']?.toString() == line.productCode,
            orElse: () => <String, dynamic>{},
          );
          return line.copyWith(
            productName: product['productName']?.toString(),
          );
        }).toList();
      } else {
        _currentPutawayLines = lines;
      }

      // Save to local storage
      await _repository.savePutawayLinesForProduct(productCode, _currentPutawayLines);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search products by keyword
  Future<void> searchProducts(String keyword) async {
    if (keyword.isEmpty) {
      await fetchPutawayData();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Filter table data by product code or product name
      final filtered = _tableData.where((row) {
        final productCode = row[0].toString().toLowerCase();
        final productName = row[5].toString().toLowerCase();
        final searchLower = keyword.toLowerCase();
        return productCode.contains(searchLower) ||
            productName.contains(searchLower);
      }).toList();

      _tableData = filtered;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Search failed: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check product status before navigation
  Future<bool> checkProductStatus(String productCode) async {
    try {
      final lines = _groupedLines[productCode] ?? [];
      if (lines.isEmpty) return false;

      final handledByOther = lines.where((line) {
        return line.hhtInfo != null &&
            line.hhtInfo!.isNotEmpty &&
            line.hhtInfo!.toLowerCase() != _hhtInfo?.toLowerCase();
      }).toList();

      return handledByOther.isNotEmpty;
    } catch (e) {
      print('Error checking product status: $e');
      return false;
    }
  }

  /// Get repository for direct access
  PutawayRepository get repository => _repository;

  /// Get localStorage for direct access
  LocalStorage get localStorage => _localStorage;

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

