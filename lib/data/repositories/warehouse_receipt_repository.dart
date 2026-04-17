
import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/local_storage.dart';
import '../models/warehouse_receipt/receipt_line.dart';
import '../models/warehouse_receipt/receipt_order.dart';
import '../models/warehouse_receipt/receipt_staging.dart';

class WarehouseReceiptRepository {
  final ApiClient _apiClient;
  final LocalStorage _localStorage;

  WarehouseReceiptRepository(this._apiClient, this._localStorage);

  /// Get all warehouse receipt orders
  Future<List<ReceiptOrder>> getWarehouseReceiptOrders() async {
    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.warehouseReceiptOrder);
      
      List<dynamic> dataList = [];
      if (response.data is List) {
        dataList = response.data;
      } else if (response.data is Map && response.data['data'] != null) {
        dataList = response.data['data'];
      }
      
      if (response.statusCode == 200 && dataList.isNotEmpty) {
        final orders = dataList.map((json) => ReceiptOrder.fromJson(json)).toList();
        return orders;
      }
      return [];
    } catch (e) {
      print('Error fetching warehouse receipt orders: $e');
      return [];
    }
  }

  /// Get warehouse receipt order by receipt number
  Future<List<ReceiptOrder>> getWarehouseReceiptOrderByReceiptNo(
      String receiptNo) async {
    try {
      final url = ApiEndpoints.warehouseReceiptOrderByReceiptNo
          .replaceAll('{receiptNo}', receiptNo);
      final response = await _apiClient.dio.get(url);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ReceiptOrder.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching warehouse receipt order by receipt no: $e');
      return [];
    }
  }

  /// Get all warehouse receipt order lines
  Future<List<ReceiptLine>> getWarehouseReceiptOrderLines() async {
    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.warehouseReceiptOrderLine);

      List<dynamic> dataList = [];
      if (response.data is List) {
        dataList = response.data;
      } else if (response.data is Map && response.data['data'] != null) {
        dataList = response.data['data'];
      }

      if (response.statusCode == 200 && dataList.isNotEmpty) {
        return dataList.map((json) => ReceiptLine.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching warehouse receipt order lines: $e');
      return [];
    }
  }

  /// Get warehouse receipt order lines by receipt number
  Future<List<ReceiptLine>> getWarehouseReceiptOrderLinesByReceiptNo(
      String receiptNo) async {
    try {
      final url = ApiEndpoints.warehouseReceiptOrderLineByReceiptNo
          .replaceAll('{receiptNo}', receiptNo);
      final response = await _apiClient.dio.get(url);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ReceiptLine.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching warehouse receipt order lines by receipt no: $e');
      return [];
    }
  }

  /// Update warehouse receipt order line
  Future<bool> updateWarehouseReceiptOrderLine(ReceiptLine line) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.warehouseReceiptOrderLineUpdate,
        data: line.toJson(),
      );

      return response.statusCode == 200 && response.data != null;
    } catch (e) {
      print('Error updating warehouse receipt order line: $e');
      return false;
    }
  }

  /// Get warehouse receipt staging by receipt number
  Future<List<ReceiptStaging>> getWarehouseReceiptStagingByReceiptNo(
      String receiptNo) async {
    try {
      final url = ApiEndpoints.warehouseReceiptStagingByReceiptNo
          .replaceAll('{receiptNo}', receiptNo);
      final response = await _apiClient.dio.get(url);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ReceiptStaging.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching warehouse receipt staging by receipt no: $e');
      return [];
    }
  }

  /// Delete warehouse receipt staging
  Future<bool> deleteWarehouseReceiptStaging(ReceiptStaging staging) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.warehouseReceiptStagingDelete,
        data: staging.toJson(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting warehouse receipt staging: $e');
      return false;
    }
  }

  /// Add range of warehouse receipt staging
  Future<bool> addRangeWarehouseReceiptStaging(
      List<ReceiptStaging> stagingList) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.warehouseReceiptStagingAddRange,
        data: stagingList.map((e) => e.toJson()).toList(),
      );

      return response.statusCode == 200 &&
          response.data != null &&
          response.data['succeeded'] == true;
    } catch (e) {
      print('Error adding range warehouse receipt staging: $e');
      return false;
    }
  }

  /// Upload product error images
  Future<bool> uploadProductErrorImages(
      List<ProductErrorImage> errorImages) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.warehouseReceiptStagingUploadImage,
        data: errorImages.map((e) => e.toJson()).toList(),
      );

      return response.statusCode == 200 &&
          response.data != null &&
          response.data['succeeded'] == true;
    } catch (e) {
      print('Error uploading product error images: $e');
      return false;
    }
  }

  /// Complete warehouse receipt
  Future<bool> completeWarehouseReceipt() async {
    try {
      final response =
          await _apiClient.dio.post(ApiEndpoints.completeWarehouseReceipt);

      return response.statusCode == 200;
    } catch (e) {
      print('Error completing warehouse receipt: $e');
      return false;
    }
  }

  /// Update HHT status
  Future<bool> updateHHTStatus(int status, int receiptId, int flag) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.updateHHTStatus,
        data: {
          'status': status,
          'receiptId': receiptId,
          'flag': flag,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating HHT status: $e');
      return false;
    }
  }

  /// Update HHT status to empty
  Future<bool> updateHHTStatusEmpty(int status, int receiptId, int flag) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.updateHHTStatus,
        data: {
          'status': status,
          'receiptId': receiptId,
          'flag': flag,
          'hhtInfo': '',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating HHT status to empty: $e');
      return false;
    }
  }

  // ==================== LOCAL STORAGE ====================

  /// Save offline scanned receipt data
  Future<void> saveOfflineReceiptData(OfflineReceiptData data) async {
    try {
      final existingData = await getOfflineReceiptDataList();
      existingData.add(data);
      await _localStorage.saveJson(
        'WHReceiptLineScanned',
        existingData.map((e) => e.toJson()).toList(),
      );
    } catch (e) {
      print('Error saving offline receipt data: $e');
    }
  }

  /// Get all offline scanned receipt data
  Future<List<OfflineReceiptData>> getOfflineReceiptDataList() async {
    try {
      final data = await _localStorage.getJson('WHReceiptLineScanned');
      if (data != null && data is List) {
        return data.map((json) => OfflineReceiptData.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting offline receipt data list: $e');
      return [];
    }
  }

  /// Get offline scanned receipt data by tenant ID
  Future<List<OfflineReceiptData>> getOfflineReceiptDataByTenant(
      int tenantId) async {
    try {
      final allData = await getOfflineReceiptDataList();
      return allData.where((data) => data.tenantId == tenantId).toList();
    } catch (e) {
      print('Error getting offline receipt data by tenant: $e');
      return [];
    }
  }

  /// Remove offline scanned receipt data by receipt number
  Future<void> removeOfflineReceiptData(String receiptNo) async {
    try {
      final existingData = await getOfflineReceiptDataList();
      existingData
          .removeWhere((data) => data.warehouseReceiptNo == receiptNo);
      await _localStorage.saveJson(
        'WHReceiptLineScanned',
        existingData.map((e) => e.toJson()).toList(),
      );
    } catch (e) {
      print('Error removing offline receipt data: $e');
    }
  }

  /// Remove offline scanned receipt data by tenant ID
  Future<void> removeOfflineReceiptDataByTenant(int tenantId) async {
    try {
      final existingData = await getOfflineReceiptDataList();
      existingData.removeWhere((data) => data.tenantId == tenantId);
      await _localStorage.saveJson(
        'WHReceiptLineScanned',
        existingData.map((e) => e.toJson()).toList(),
      );
    } catch (e) {
      print('Error removing offline receipt data by tenant: $e');
    }
  }

  /// Clear all offline scanned receipt data
  Future<void> clearOfflineReceiptData() async {
    try {
      await _localStorage.remove('WHReceiptLineScanned');
    } catch (e) {
      print('Error clearing offline receipt data: $e');
    }
  }

  /// Save warehouse receipt orders to local storage
  Future<void> saveWarehouseReceiptOrders(List<ReceiptOrder> orders) async {
    try {
      await _localStorage.saveJson(
        'dataWarehouseReceipt',
        orders.map((e) => e.toJson()).toList(),
      );
    } catch (e) {
      print('Error saving warehouse receipt orders: $e');
    }
  }

  /// Get warehouse receipt orders from local storage
  Future<List<ReceiptOrder>> getWarehouseReceiptOrdersFromLocal() async {
    try {
      final data = await _localStorage.getJson('dataWarehouseReceipt');
      if (data != null && data is List) {
        return data.map((json) => ReceiptOrder.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting warehouse receipt orders from local: $e');
      return [];
    }
  }

  /// Save warehouse receipt lines to local storage
  Future<void> saveWarehouseReceiptLines(List<ReceiptLine> lines) async {
    try {
      await _localStorage.saveJson(
        'dataReceiptLines',
        lines.map((e) => e.toJson()).toList(),
      );
    } catch (e) {
      print('Error saving warehouse receipt lines: $e');
    }
  }

  /// Get warehouse receipt lines from local storage
  Future<List<ReceiptLine>> getWarehouseReceiptLinesFromLocal() async {
    try {
      final data = await _localStorage.getJson('dataReceiptLines');
      if (data != null && data is List) {
        return data.map((json) => ReceiptLine.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting warehouse receipt lines from local: $e');
      return [];
    }
  }

  /// Save warehouse receipt line for specific receipt
  Future<void> saveWarehouseReceiptLineForReceipt(
      String receiptNo, List<ReceiptLine> lines) async {
    try {
      await _localStorage.saveJson(
        'dataWarehouseReceiptLine',
        lines.map((e) => e.toJson()).toList(),
      );
    } catch (e) {
      print('Error saving warehouse receipt line for receipt: $e');
    }
  }

  /// Get warehouse receipt line for specific receipt
  Future<List<ReceiptLine>> getWarehouseReceiptLineForReceipt() async {
    try {
      final data = await _localStorage.getJson('dataWarehouseReceiptLine');
      if (data != null && data is List) {
        return data.map((json) => ReceiptLine.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting warehouse receipt line for receipt: $e');
      return [];
    }
  }
}


