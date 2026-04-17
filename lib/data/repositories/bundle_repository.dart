import 'package:dio/dio.dart';
import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/local_storage.dart';
import '../models/bundle/bundle.dart';
import '../models/bundle/bundle_line.dart';

class BundleRepository {
  final ApiClient _apiClient;
  final LocalStorage _localStorage;

  BundleRepository(this._apiClient, this._localStorage);

  /// Get all bundles
  Future<List<Bundle>> getBundles() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.bundle);

      List<dynamic> dataList = [];
      if (response.data is List) {
        dataList = response.data;
      } else if (response.data is Map && response.data['data'] != null) {
        dataList = response.data['data'];
      }

      if (response.statusCode == 200 && dataList.isNotEmpty) {
        return dataList.map((json) => Bundle.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching bundles: $e');
      return [];
    }
  }

  /// Get bundle by trans number
  Future<Bundle?> getBundleByTransNo(String transNo) async {
    try {
      final url = ApiEndpoints.bundleByTransNo.replaceAll('{transNo}', transNo);
      final response = await _apiClient.dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        return Bundle.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error fetching bundle by trans no: $e');
      return null;
    }
  }

  /// Get all bundle lines
  Future<List<BundleLine>> getBundleLines() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.bundleLines);

      List<dynamic> dataList = [];
      if (response.data is List) {
        dataList = response.data;
      } else if (response.data is Map && response.data['data'] != null) {
        dataList = response.data['data'];
      }

      if (response.statusCode == 200 && dataList.isNotEmpty) {
        return dataList.map((json) => BundleLine.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching bundle lines: $e');
      return [];
    }
  }

  /// Get bundle lines by trans number
  Future<List<BundleLine>> getBundleLinesByTransNo(String transNo) async {
    try {
      final url =
          ApiEndpoints.bundleLinesByTransNo.replaceAll('{TransNo}', transNo);
      final response = await _apiClient.dio.get(url);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => BundleLine.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching bundle lines by trans no: $e');
      return [];
    }
  }

  /// Add range of bundle lines
  Future<bool> addRangeBundleLines(List<BundleLine> lines) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.bundleLineAddRange,
        data: lines.map((e) => e.toJson()).toList(),
      );

      return response.statusCode == 200 &&
          response.data != null &&
          response.data['succeeded'] == true;
    } catch (e) {
      print('Error adding range of bundle lines: $e');
      return false;
    }
  }

  /// Upload from handheld
  Future<bool> uploadFromHandheld(List<Map<String, dynamic>> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.bundleUploadFromHandheld,
        data: data,
      );

      return response.statusCode == 200 &&
          response.data != null &&
          response.data['succeeded'] == true;
    } catch (e) {
      print('Error uploading from handheld: $e');
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

  static const String _bundlesKey = 'bundles';
  static const String _bundleLinesKey = 'bundleLines';

  Future<void> saveBundles(List<Bundle> bundles) async {
    final String jsonString =
        jsonEncode(bundles.map((e) => e.toJson()).toList());
    await _localStorage.saveString(_bundlesKey, jsonString);
  }

  Future<List<Bundle>> getLocalBundles() async {
    final String? jsonString = await _localStorage.getString(_bundlesKey);
    if (jsonString != null) {
      final List<dynamic> data = jsonDecode(jsonString);
      return data.map((json) => Bundle.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> saveBundleLines(List<BundleLine> lines) async {
    final String jsonString = jsonEncode(lines.map((e) => e.toJson()).toList());
    await _localStorage.saveString(_bundleLinesKey, jsonString);
  }

  Future<List<BundleLine>> getLocalBundleLines() async {
    final String? jsonString = await _localStorage.getString(_bundleLinesKey);
    if (jsonString != null) {
      final List<dynamic> data = jsonDecode(jsonString);
      return data.map((json) => BundleLine.fromJson(json)).toList();
    }
    return [];
  }
}

