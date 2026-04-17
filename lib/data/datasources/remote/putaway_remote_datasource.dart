import '../../../core/network/dio_client.dart';
import '../../models/putaway/putaway_order.dart';
import '../../models/putaway/putaway_line.dart';
import '../../models/putaway/putaway_staging.dart';

/// Remote datasource cho module Putaway
class PutawayRemoteDataSource {
  final DioClient _dioClient;

  PutawayRemoteDataSource(this._dioClient);

  // ─── Orders ───────────────────────────────────────────────────

  /// GET /api/WarehousePutAway
  Future<List<PutawayOrder>> getPutawayOrders() async {
    final res = await _dioClient.dio.get('/api/WarehousePutAway');
    return _parseList(res.data, PutawayOrder.fromJson);
  }

  // ─── Lines ────────────────────────────────────────────────────

  /// GET /api/WarehousePutAwayLine
  Future<List<PutawayLine>> getPutawayLines() async {
    final res = await _dioClient.dio.get('/api/WarehousePutAwayLine');
    return _parseList(res.data, PutawayLine.fromJson);
  }

  /// GET /api/WarehousePutAwayLine/GetByMasterCodeAsync/{putAwayNo}
  Future<List<PutawayLine>> getLinesByNo(String putAwayNo) async {
    final res = await _dioClient.dio.get(
      '/api/WarehousePutAwayLine/GetByMasterCodeAsync/$putAwayNo',
    );
    return _parseList(res.data, PutawayLine.fromJson);
  }

  // ─── Staging ──────────────────────────────────────────────────

  /// GET /api/WarehousePutAwayStaging/GetByMasterCodeAsync/{putAwayNo}
  Future<List<PutawayStaging>> getStagingByNo(String putAwayNo) async {
    final res = await _dioClient.dio.get(
      '/api/WarehousePutAwayStaging/GetByMasterCodeAsync/$putAwayNo',
    );
    return _parseList(res.data, PutawayStaging.fromJson);
  }

  /// POST /api/WarehousePutAwayStaging/AddRange
  Future<bool> addStagingRange(List<PutawayStaging> list) async {
    final res = await _dioClient.dio.post(
      '/api/WarehousePutAwayStaging/AddRange',
      data: list.map((e) => e.toJson()).toList(),
    );
    final data = res.data;
    if (data is Map) return data['succeeded'] == true;
    return res.statusCode == 200;
  }

  /// POST /api/WarehousePutAwayStaging/delete
  Future<bool> deleteStaging(PutawayStaging staging) async {
    final res = await _dioClient.dio.post(
      '/api/WarehousePutAwayStaging/delete',
      data: staging.toJson(),
    );
    return res.statusCode == 200;
  }

  // ─── Complete ─────────────────────────────────────────────────

  /// POST /api/WarehousePutAway/complete-putaway
  Future<bool> completePutaway() async {
    final res = await _dioClient.dio.post(
      '/api/WarehousePutAway/complete-putaway',
    );
    final data = res.data;
    if (data is Map) return data['succeeded'] == true;
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

  // ─── Helper ───────────────────────────────────────────────────

  List<T> _parseList<T>(
      dynamic raw, T Function(Map<String, dynamic>) fromJson) {
    List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map && raw['data'] is List) {
      list = raw['data'] as List;
    } else {
      return [];
    }
    return list.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}
