import 'package:dio/dio.dart';
import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/local_storage.dart';
import '../models/picking/picking_line.dart';
import '../models/picking/picking_list.dart';
import '../models/picking/picking_staging.dart';

class PickingRepository {
  final ApiClient _apiClient;
  final LocalStorage _localStorage;

  PickingRepository(this._apiClient, this._localStorage);

  /// Get all picking lists
  Future<List<PickingList>> getPickingLists() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.pickingList);

      List<dynamic> dataList = [];
      if (response.data is List) {
        dataList = response.data;
      } else if (response.data is Map && response.data['data'] != null) {
        dataList = response.data['data'];
      }

      if (response.statusCode == 200 && dataList.isNotEmpty) {
        return dataList.map((json) => PickingList.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching picking lists: $e');
      return [];
    }
  }

  /// Get picking list by picking number
  Future<List<PickingList>> getPickingListByPickingNo(String pickNo) async {
    try {
      final url =
          ApiEndpoints.pickingListByPickingNo.replaceAll('{pickNo}', pickNo);
      final response = await _apiClient.dio.get(url);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => PickingList.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching picking list by picking no: $e');
      return [];
    }
  }

  /// Get all picking lines
  Future<List<PickingLine>> getPickingLines() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.pickingLines);

      List<dynamic> dataList = [];
      if (response.data is List) {
        dataList = response.data;
      } else if (response.data is Map && response.data['data'] != null) {
        dataList = response.data['data'];
      }

      if (response.statusCode == 200 && dataList.isNotEmpty) {
        return dataList.map((json) => PickingLine.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching picking lines: $e');
      return [];
    }
  }

  /// Get picking lines by picking number
  Future<List<PickingLine>> getPickingLinesByPickingNo(String pickNo) async {
    try {
      final url =
          ApiEndpoints.pickingLinesByPickingNo.replaceAll('{pickNo}', pickNo);
      final response = await _apiClient.dio.get(url);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => PickingLine.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching picking lines by picking no: $e');
      return [];
    }
  }

  /// Get all picking staging
  Future<List<PickingStaging>> getAllPickingStaging() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.pickingStaging);

      List<dynamic> dataList = [];
      if (response.data is List) {
        dataList = response.data;
      } else if (response.data is Map && response.data['data'] != null) {
        dataList = response.data['data'];
      }

      if (response.statusCode == 200 && dataList.isNotEmpty) {
        return dataList.map((json) => PickingStaging.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching all picking staging: $e');
      return [];
    }
  }

  /// Get picking staging by picking number
  Future<List<PickingStaging>> getPickingStagingByPickingNo(
      String pickNo) async {
    try {
      final url = ApiEndpoints.pickingStagingByPickingNo
          .replaceAll('{pickNo}', pickNo);
      final response = await _apiClient.dio.get(url);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => PickingStaging.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching picking staging by picking no: $e');
      return [];
    }
  }

  /// Add range of picking staging
  Future<bool> addRangePickingStaging(
      List<PickingStaging> stagingList) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.pickingStagingAddRange,
        data: stagingList.map((e) => e.toJson()).toList(),
      );

      return response.statusCode == 200 &&
          response.data != null &&
          response.data['succeeded'] == true;
    } catch (e) {
      print('Error adding range of picking staging: $e');
      return false;
    }
  }

  /// Complete picking
  Future<bool> completePicking() async {
    try {
      final response = await _apiClient.dio.post(ApiEndpoints.completePicking);

      return response.statusCode == 200 &&
          response.data != null &&
          response.data['succeeded'] == true;
    } catch (e) {
      print('Error completing picking: $e');
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
          'hhtInfo': '',
        },
      );

      return response.statusCode == 200 && response.data != null;
    } catch (e) {
      print('Error updating HHT status to empty: $e');
      return false;
    }
  }

  // --- Local Storage Operations ---

  static const String _pickingListsKey = 'pickingLists';
  static const String _pickingLinesKey = 'pickingLines';

  Future<void> savePickingLists(List<PickingList> lists) async {
    final String jsonString = jsonEncode(lists.map((e) => e.toJson()).toList());
    await _localStorage.saveString(_pickingListsKey, jsonString);
  }

  Future<List<PickingList>> getLocalPickingLists() async {
    final String? jsonString = await _localStorage.getString(_pickingListsKey);
    if (jsonString != null) {
      final List<dynamic> data = jsonDecode(jsonString);
      return data.map((json) => PickingList.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> savePickingLines(List<PickingLine> lines) async {
    final String jsonString = jsonEncode(lines.map((e) => e.toJson()).toList());
    await _localStorage.saveString(_pickingLinesKey, jsonString);
  }

  Future<List<PickingLine>> getLocalPickingLines() async {
    final String? jsonString = await _localStorage.getString(_pickingLinesKey);
    if (jsonString != null) {
      final List<dynamic> data = jsonDecode(jsonString);
      return data.map((json) => PickingLine.fromJson(json)).toList();
    }
    return [];
  }
}

