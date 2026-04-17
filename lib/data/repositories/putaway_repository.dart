import 'package:dio/dio.dart';
import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/local_storage.dart';
import '../models/putaway/putaway_line.dart';
import '../models/putaway/putaway_order.dart';
import '../models/putaway/putaway_staging.dart';

class PutawayRepository {
  final ApiClient _apiClient;
  final LocalStorage _localStorage;

  PutawayRepository(this._apiClient, this._localStorage);

  /// Get all putaway orders
  Future<List<PutawayOrder>> getPutawayOrders() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.putaway);

      List<dynamic> dataList = [];
      if (response.data is List) {
        dataList = response.data;
      } else if (response.data is Map && response.data['data'] != null) {
        dataList = response.data['data'];
      }

      if (response.statusCode == 200 && dataList.isNotEmpty) {
        return dataList.map((json) => PutawayOrder.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching putaway orders: $e');
      return [];
    }
  }

  /// Get putaway order by putaway number
  Future<List<PutawayOrder>> getPutawayOrderByPutawayNo(
      String putAwayNo) async {
    try {
      final url =
          ApiEndpoints.putawayByPutawayNo.replaceAll('{putAwayNo}', putAwayNo);
      final response = await _apiClient.dio.get(url);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => PutawayOrder.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching putaway order by putaway no: $e');
      return [];
    }
  }

  /// Get all putaway lines
  Future<List<PutawayLine>> getPutawayLines() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.putawayLines);

      List<dynamic> dataList = [];
      if (response.data is List) {
        dataList = response.data;
      } else if (response.data is Map && response.data['data'] != null) {
        dataList = response.data['data'];
      }

      if (response.statusCode == 200 && dataList.isNotEmpty) {
        return dataList.map((json) => PutawayLine.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching putaway lines: $e');
      return [];
    }
  }

  /// Get putaway lines by putaway number
  Future<List<PutawayLine>> getPutawayLinesByPutawayNo(
      String putAwayNo) async {
    try {
      final url = ApiEndpoints.putawayLinesByPutawayNo
          .replaceAll('{putAwayNo}', putAwayNo);
      final response = await _apiClient.dio.get(url);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => PutawayLine.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching putaway lines by putaway no: $e');
      return [];
    }
  }

  /// Get putaway staging by putaway number
  Future<List<PutawayStaging>> getPutawayStagingByPutawayNo(
      String putAwayNo) async {
    try {
      final url = ApiEndpoints.putawayStagingByPutawayNo
          .replaceAll('{putAwayNo}', putAwayNo);
      final response = await _apiClient.dio.get(url);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => PutawayStaging.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching putaway staging by putaway no: $e');
      return [];
    }
  }

  /// Delete putaway staging
  Future<bool> deletePutawayStaging(PutawayStaging staging) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.putawayStagingDelete,
        data: staging.toJson(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting putaway staging: $e');
      return false;
    }
  }

  /// Add range of putaway staging
  Future<bool> addRangePutawayStaging(
      List<PutawayStaging> stagingList) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.putawayStagingAddRange,
        data: stagingList.map((e) => e.toJson()).toList(),
      );

      return response.statusCode == 200 &&
          response.data != null &&
          response.data['succeeded'] == true;
    } catch (e) {
      print('Error adding range of putaway staging: $e');
      return false;
    }
  }

  /// Complete putaway
  Future<bool> completePutaway() async {
    try {
      final response =
          await _apiClient.dio.post(ApiEndpoints.completePutaway);

      return response.statusCode == 200 &&
          response.data != null &&
          response.data['succeeded'] == true;
    } catch (e) {
      print('Error completing putaway: $e');
      return false;
    }
  }

  /// Update HHT status
  Future<bool> updateHHTStatus(int status, int masterId, int detailId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.updateHHTStatus,
        data: {
          'status': status,
          'masterId': masterId,
          'detailId': detailId,
        },
      );

      return response.statusCode == 200 && response.data != null;
    } catch (e) {
      print('Error updating HHT status: $e');
      return false;
    }
  }

  /// Update HHT status to empty
  Future<bool> updateHHTStatusEmpty(
      int status, int masterId, int detailId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.updateHHTStatus,
        data: {
          'status': status,
          'masterId': masterId,
          'detailId': detailId,
          'hhtInfo': '', // Set hhtInfo to empty
        },
      );

      return response.statusCode == 200 && response.data != null;
    } catch (e) {
      print('Error updating HHT status to empty: $e');
      return false;
    }
  }

  // --- Local Storage Operations ---

  static const String _putawayOrdersKey = 'putawayOrders';
  static const String _putawayLinesKey = 'putawayLines';
  static const String _offlineDataKey = 'offlinePutawayData';

  Future<void> savePutawayOrders(List<PutawayOrder> orders) async {
    final String jsonString =
        jsonEncode(orders.map((e) => e.toJson()).toList());
    await _localStorage.saveString(_putawayOrdersKey, jsonString);
  }

  Future<List<PutawayOrder>> getLocalPutawayOrders() async {
    final String? jsonString = await _localStorage.getString(_putawayOrdersKey);
    if (jsonString != null) {
      final List<dynamic> data = jsonDecode(jsonString);
      return data.map((json) => PutawayOrder.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> savePutawayLines(List<PutawayLine> lines) async {
    final String jsonString = jsonEncode(lines.map((e) => e.toJson()).toList());
    await _localStorage.saveString(_putawayLinesKey, jsonString);
  }

  Future<List<PutawayLine>> getLocalPutawayLines() async {
    final String? jsonString = await _localStorage.getString(_putawayLinesKey);
    if (jsonString != null) {
      final List<dynamic> data = jsonDecode(jsonString);
      return data.map((json) => PutawayLine.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> savePutawayLinesForProduct(
      String productCode, List<PutawayLine> lines) async {
    final String key = '${_putawayLinesKey}_$productCode';
    final String jsonString = jsonEncode(lines.map((e) => e.toJson()).toList());
    await _localStorage.saveString(key, jsonString);
  }

  Future<List<PutawayLine>> getPutawayLinesForProduct(
      String productCode) async {
    final String key = '${_putawayLinesKey}_$productCode';
    final String? jsonString = await _localStorage.getString(key);
    if (jsonString != null) {
      final List<dynamic> data = jsonDecode(jsonString);
      return data.map((json) => PutawayLine.fromJson(json)).toList();
    }
    return [];
  }
}

