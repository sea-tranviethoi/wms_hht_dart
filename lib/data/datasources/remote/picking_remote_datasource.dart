import '../../../core/network/dio_client.dart';
import '../../models/picking/picking_list.dart';
import '../../models/picking/picking_line.dart';
import '../../models/picking/picking_staging.dart';

/// Remote datasource cho module Picking
/// Port từ services/picking.js + PickingRepository (ApiClient version)
class PickingRemoteDataSource {
  final DioClient _dioClient;

  PickingRemoteDataSource(this._dioClient);

  // ─── Picking Lists ────────────────────────────────────────────

  /// GET /api/WarehousePickingList → tất cả picking lists
  Future<List<PickingList>> getPickingLists() async {
    final res = await _dioClient.dio.get('/api/WarehousePickingList');
    return _parseList(res.data, PickingList.fromJson);
  }

  /// GET /api/WarehousePickingList/GetByMasterCodeAsync/{pickNo}
  Future<List<PickingList>> getPickingListByNo(String pickNo) async {
    final res = await _dioClient.dio.get(
      '/api/WarehousePickingList/GetByMasterCodeAsync/$pickNo',
    );
    return _parseList(res.data, PickingList.fromJson);
  }

  // ─── Picking Lines ────────────────────────────────────────────

  /// GET /api/WarehousePickingLine/GetPickingLineDTOAsync/{pickNo}
  Future<List<PickingLine>> getPickingLinesByNo(String pickNo) async {
    final res = await _dioClient.dio.get(
      '/api/WarehousePickingLine/GetPickingLineDTOAsync/$pickNo',
    );
    return _parseList(res.data, PickingLine.fromJson);
  }

  // ─── Picking Staging ──────────────────────────────────────────

  /// GET /api/WarehousePickingStaging → tất cả staging
  Future<List<PickingStaging>> getAllStaging() async {
    final res = await _dioClient.dio.get('/api/WarehousePickingStaging');
    return _parseList(res.data, PickingStaging.fromJson);
  }

  /// GET /api/WarehousePickingStaging/GetByMasterCodeAsync/{pickNo}
  Future<List<PickingStaging>> getStagingByNo(String pickNo) async {
    final res = await _dioClient.dio.get(
      '/api/WarehousePickingStaging/GetByMasterCodeAsync/$pickNo',
    );
    return _parseList(res.data, PickingStaging.fromJson);
  }

  /// POST /api/WarehousePickingStaging/AddRange
  Future<bool> addStagingRange(List<PickingStaging> list) async {
    final res = await _dioClient.dio.post(
      '/api/WarehousePickingStaging/AddRange',
      data: list.map((e) => e.toJson()).toList(),
    );
    final data = res.data;
    if (data is Map) return data['succeeded'] == true;
    return res.statusCode == 200;
  }

  /// POST /api/WarehousePickingStaging/DeleteRange
  Future<bool> deleteStagingRange(List<PickingStaging> items) async {
    final res = await _dioClient.dio.post(
      '/api/WarehousePickingStaging/DeleteRange',
      data: items.map((e) => e.toJson()).toList(),
    );
    return res.statusCode == 200;
  }

  // ─── Common ───────────────────────────────────────────────────

  /// POST /api/Common/UpdateHHTStatusAsync
  Future<bool> updateHHTStatus({
    required int status,
    required int masterId,
    required int detailId,
    String? hhtInfo,
  }) async {
    final res = await _dioClient.dio.post(
      '/api/Common/UpdateHHTStatusAsync',
      data: {
        'status': status,
        'masterId': masterId,
        'detailId': detailId,
        if (hhtInfo != null) 'hhtInfo': hhtInfo,
      },
    );
    return res.statusCode == 200;
  }

  /// POST /api/WarehousePickingList/complete-pickings
  Future<bool> completePicking(String pickNo) async {
    final res = await _dioClient.dio.post(
      '/api/WarehousePickingList/complete-pickings',
      data: [pickNo],
    );
    final data = res.data;
    if (data is Map) return data['succeeded'] == true;
    return res.statusCode == 200;
  }

  // ─── Helper ───────────────────────────────────────────────────

  List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
    List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map && raw['data'] is List) {
      list = raw['data'] as List;
    } else {
      return [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }
}
