import '../../../core/network/dio_client.dart';
import '../../models/bin_movement/invent_transfer.dart';
import '../../models/bin_movement/invent_transfer_line.dart';

class BinMovementRemoteDataSource {
  final DioClient _dioClient;

  BinMovementRemoteDataSource(DioClient dioClient) : _dioClient = dioClient;

  // ─── Transfers ────────────────────────────────────────────────

  /// GET /api/InventTransfer
  Future<List<InventTransfer>> getTransfers() async {
    final res = await _dioClient.dio.get('/api/InventTransfer');
    return _parseList(res.data, InventTransfer.fromJson);
  }

  /// GET /api/InventTransfer/GetByMasterCodeAsync/{transferNo}
  Future<List<InventTransfer>> getTransfersByNo(String transferNo) async {
    final res = await _dioClient.dio.get(
      '/api/InventTransfer/GetByMasterCodeAsync/$transferNo',
    );
    return _parseList(res.data, InventTransfer.fromJson);
  }

  // ─── Lines ────────────────────────────────────────────────────

  /// GET /api/InventTransferLine
  Future<List<InventTransferLine>> getLines() async {
    final res = await _dioClient.dio.get('/api/InventTransferLine');
    return _parseList(res.data, InventTransferLine.fromJson);
  }

  /// GET /api/InventTransferLine/GetByMasterCodeAsync/{transferNo}
  Future<List<InventTransferLine>> getLinesByTransferNo(
      String transferNo) async {
    final res = await _dioClient.dio.get(
      '/api/InventTransferLine/GetByMasterCodeAsync/$transferNo',
    );
    return _parseList(res.data, InventTransferLine.fromJson);
  }

  // ─── Staging ──────────────────────────────────────────────────

  /// GET /api/InventTransferStaging/GetByMasterCodeAsync/{transferNo}
  Future<List<Map<String, dynamic>>> getStagingByNo(String transferNo) async {
    final res = await _dioClient.dio.get(
      '/api/InventTransferStaging/GetByMasterCodeAsync/$transferNo',
    );
    return _parseListRaw(res.data);
  }

  /// POST /api/InventTransferStaging/AddRange
  Future<bool> addStagingRange(List<Map<String, dynamic>> stagingList) async {
    final res = await _dioClient.dio.post(
      '/api/InventTransferStaging/AddRange',
      data: stagingList,
    );
    final data = res.data;
    if (data is Map) return data['succeeded'] == true;
    return res.statusCode == 200;
  }

  /// POST /api/InventTransferStaging/delete
  Future<bool> deleteStaging(Map<String, dynamic> staging) async {
    final res = await _dioClient.dio.post(
      '/api/InventTransferStaging/delete',
      data: staging,
    );
    return res.statusCode == 200;
  }

  // ─── Complete ─────────────────────────────────────────────────

  /// POST /api/InventTransfer/complete-transfer
  Future<bool> completeTransfer() async {
    final res = await _dioClient.dio.post(
      '/api/InventTransfer/complete-transfer',
    );
    final data = res.data;
    if (data is Map) return data['succeeded'] == true;
    return res.statusCode == 200;
  }

  // ─── HHT Status ───────────────────────────────────────────────

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

  // ─── Helpers ──────────────────────────────────────────────────

  List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
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

  List<Map<String, dynamic>> _parseListRaw(dynamic raw) {
    List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map && raw['data'] is List) {
      list = raw['data'] as List;
    } else {
      return [];
    }
    return list.whereType<Map<String, dynamic>>().toList();
  }
}
