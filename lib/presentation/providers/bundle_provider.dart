import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../../core/storage/local_storage.dart';
import '../../data/models/bundle/bundle.dart';
import '../../data/models/bundle/bundle_line.dart';
import '../../data/repositories/bundle_repository.dart';

class BundleProvider with ChangeNotifier {
  final BundleRepository _repository;
  final LocalStorage _localStorage;

  BundleProvider(this._repository, this._localStorage);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Bundle> _bundles = [];
  List<Bundle> get bundles => _bundles;

  List<BundleLine> _bundleLines = [];
  List<BundleLine> get bundleLines => _bundleLines;

  // Table data: [transNo, countLine, id, scanStatus, hhtInfo, productName]
  List<List<dynamic>> _tableData = [];
  List<List<dynamic>> get tableData => _tableData;

  String? _selectedTransNo;
  String? get selectedTransNo => _selectedTransNo;

  List<BundleLine> _currentBundleLines = [];
  List<BundleLine> get currentBundleLines => _currentBundleLines;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _hhtInfo;
  String? get hhtInfo => _hhtInfo;

  /// Initialize - load HHT info
  Future<void> initialize() async {
    _hhtInfo = await _localStorage.getString('hhtInfo');
    notifyListeners();
  }

  /// Fetch bundle data
  Future<void> fetchBundleData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get bundles (filter: status == 0)
      final bundles = await _repository.getBundles();
      final filteredBundles =
          bundles.where((bundle) => bundle.status == 0).toList();

      // Get products from local storage
      final productsJson = await _localStorage.getJson('dataProducts');
      final productsList = _asList(productsJson);

      // Get scanned history
      final scannedHistoryJson =
          await _localStorage.getString('bundleScanned');
      List<Map<String, dynamic>> scannedHistory = [];
      if (scannedHistoryJson != null) {
        scannedHistory = List<Map<String, dynamic>>.from(
            jsonDecode(scannedHistoryJson));
      }

      // Build table data
      _tableData = [];
      for (var bundle in filteredBundles) {
        // Get bundle lines to count
        final lines =
            await _repository.getBundleLinesByTransNo(bundle.transNo);
        final countLine = lines.length;

        // Get first product name for display
        String productName = '';
        if (lines.isNotEmpty && productsList.isNotEmpty) {
          final firstProduct = lines.first;
          final product = productsList.firstWhere(
            (p) => p['productCode']?.toString() == firstProduct.productCode,
            orElse: () => <String, dynamic>{},
          );
          productName = product['productName']?.toString() ?? '';
        }

        // Check scanned history
        int scanStatus = 0; // 0: not scanned, 1: scanned, 2: handled by other
        String? hhtInfoOther;

        final scannedItem = scannedHistory.firstWhere(
          (item) => item.containsKey(bundle.transNo),
          orElse: () => {},
        );

        if (scannedItem.isNotEmpty) {
          scanStatus = 1; // Scanned
        }

        // Check if handled by other device
        if (bundle.hhtInfo != null && bundle.hhtInfo!.isNotEmpty) {
          if (bundle.hhtInfo!.toLowerCase() == _hhtInfo?.toLowerCase()) {
            scanStatus = 1; // Scanned by this device
          } else {
            scanStatus = 2; // Handled by other device
            hhtInfoOther = bundle.hhtInfo;
          }
        }

        _tableData.add([
          bundle.transNo,
          countLine,
          bundle.id ?? 0,
          scanStatus,
          hhtInfoOther ?? '',
          productName,
        ]);
      }

      // Sort by transNo
      _tableData.sort((a, b) => a[0].toString().compareTo(b[0].toString()));

      _bundles = filteredBundles;

      // Save to local storage
      await _repository.saveBundles(_bundles);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      print('ERROR: Failed to load bundle data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a bundle and load its lines
  Future<void> selectBundle(String transNo) async {
    _selectedTransNo = transNo;
    _isLoading = true;
    notifyListeners();

    try {
      final lines = await _repository.getBundleLinesByTransNo(transNo);

      // Enrich with product names
      final productsJson = await _localStorage.getJson('dataProducts');
      final productsList = _asList(productsJson);
      if (productsList.isNotEmpty) {
        _currentBundleLines = lines.map((line) {
          final product = productsList.firstWhere(
            (p) => p['productCode']?.toString() == line.productCode,
            orElse: () => <String, dynamic>{},
          );
          return line.copyWith(
            productName: product['productName']?.toString(),
          );
        }).toList();
      } else {
        _currentBundleLines = lines;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search bundles by keyword
  Future<void> searchBundles(String keyword) async {
    if (keyword.isEmpty) {
      await fetchBundleData();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Filter table data by transNo
      final filtered = _tableData.where((row) {
        final transNo = row[0].toString().toLowerCase();
        final searchLower = keyword.toLowerCase();
        return transNo.contains(searchLower);
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

  /// Get repository for direct access
  BundleRepository get repository => _repository;

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

