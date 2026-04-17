import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../../core/storage/local_storage.dart';
import '../../data/models/picking/picking_line.dart';
import '../../data/models/picking/picking_list.dart';
import '../../data/models/picking/picking_staging.dart';
import '../../data/repositories/picking_repository.dart';

class PickingProvider with ChangeNotifier {
  final PickingRepository _repository;
  final LocalStorage _localStorage;

  PickingProvider(this._repository, this._localStorage);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<PickingList> _pickingLists = [];
  List<PickingList> get pickingLists => _pickingLists;

  List<PickingLine> _pickingLines = [];
  List<PickingLine> get pickingLines => _pickingLines;

  // Table data: [pickNo, binCount, scanStatus, hhtInfo]
  List<List<dynamic>> _tableData = [];
  List<List<dynamic>> get tableData => _tableData;

  String? _selectedPickNo;
  String? get selectedPickNo => _selectedPickNo;

  List<PickingLine> _currentPickingLines = [];
  List<PickingLine> get currentPickingLines => _currentPickingLines;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _hhtInfo;
  String? get hhtInfo => _hhtInfo;

  /// Initialize - load HHT info
  Future<void> initialize() async {
    _hhtInfo = await _localStorage.getString('hhtInfo');
    notifyListeners();
  }

  /// Fetch picking data for tenant
  Future<void> fetchPickingData(int tenantId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get picking lists (filter: tenantId, status == 2 || status == 13, isDeleted == 0)
      final lists = await _repository.getPickingLists();
      final filteredLists = lists.where((list) {
        return list.tenantId == tenantId &&
            (list.status == 2 || list.status == 13) &&
            !list.isDeleted;
      }).toList();

      // Get all picking staging to count bins per pickNo (like React Native)
      final allStaging = await _repository.getAllPickingStaging();
      final Map<String, int> binCounts = {};
      for (var list in filteredLists) {
        final stagingForPick = allStaging.where((s) =>
            s.pickNo == list.pickNo && !s.isDeleted).toList();
        binCounts[list.pickNo] = stagingForPick.length;
      }

      // Get scanned history
      final scannedHistoryJson =
          await _localStorage.getString('pickingScanned');
      List<Map<String, dynamic>> scannedHistory = [];
      if (scannedHistoryJson != null) {
        scannedHistory = List<Map<String, dynamic>>.from(
            jsonDecode(scannedHistoryJson));
      }

      // Build table data
      _tableData = [];
      for (var list in filteredLists) {
        final pickNo = list.pickNo;
        final binCount = binCounts[pickNo] ?? 0;

        // Check scanned history
        int scanStatus = 0; // 0: not scanned, 1: scanned, 2: handled by other
        String? hhtInfoOther;

        final scannedItem = scannedHistory.firstWhere(
          (item) => item.containsKey(pickNo),
          orElse: () => {},
        );

        if (scannedItem.isNotEmpty) {
          scanStatus = 1; // Scanned
        }

        // Check if handled by other device
        if (list.hhtInfo != null && list.hhtInfo!.isNotEmpty) {
          if (list.hhtInfo!.toLowerCase() == _hhtInfo?.toLowerCase()) {
            scanStatus = 1; // Scanned by this device
          } else {
            scanStatus = 2; // Handled by other device
            hhtInfoOther = list.hhtInfo;
          }
        }

        _tableData.add([pickNo, binCount, scanStatus, hhtInfoOther ?? '']);
      }

      // Sort by pickNo
      _tableData.sort((a, b) => a[0].toString().compareTo(b[0].toString()));

      _pickingLists = filteredLists;

      // Save to local storage
      await _repository.savePickingLists(_pickingLists);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      print('ERROR: Failed to load picking data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a picking list and load its lines
  Future<void> selectPickingList(String pickNo) async {
    _selectedPickNo = pickNo;
    _isLoading = true;
    notifyListeners();

    try {
      final lines = await _repository.getPickingLinesByPickingNo(pickNo);

      // Enrich with product names
      final productsJson = await _localStorage.getJson('dataProducts');
      final productsList = _asList(productsJson);
      if (productsList.isNotEmpty) {
        _currentPickingLines = lines.map((line) {
          final product = productsList.firstWhere(
            (p) => p['productCode']?.toString() == line.productCode,
            orElse: () => <String, dynamic>{},
          );
          return line.copyWith(
            productName: product['productName']?.toString(),
          );
        }).toList();
      } else {
        _currentPickingLines = lines;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search picking lists by keyword
  Future<void> searchPickingLists(String keyword) async {
    if (keyword.isEmpty) {
      // Reload data - need tenantId, but we'll use the first one from _pickingLists
      if (_pickingLists.isNotEmpty) {
        await fetchPickingData(_pickingLists.first.tenantId);
      }
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Filter table data by pickNo
      final filtered = _tableData.where((row) {
        final pickNo = row[0].toString().toLowerCase();
        final searchLower = keyword.toLowerCase();
        return pickNo.contains(searchLower);
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

  /// Check picking list status before navigation
  Future<bool> checkPickingListStatus(String pickNo) async {
    try {
      final lists = await _repository.getPickingListByPickingNo(pickNo);
      if (lists.isEmpty) return false;

      final handledByOther = lists.where((list) {
        return (list.hhtStatus == 0 || list.hhtStatus == 1) &&
            list.hhtInfo != null &&
            list.hhtInfo!.isNotEmpty &&
            list.hhtInfo!.toLowerCase() != _hhtInfo?.toLowerCase();
      }).toList();

      return handledByOther.isNotEmpty;
    } catch (e) {
      print('Error checking picking list status: $e');
      return false;
    }
  }

  /// Get repository for direct access
  PickingRepository get repository => _repository;

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

