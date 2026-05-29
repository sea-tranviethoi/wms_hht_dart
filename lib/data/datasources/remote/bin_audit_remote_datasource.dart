import '../../../core/network/dio_client.dart';
import '../../models/stocktake/invent_stocktake_recording.dart';

/// Bin Audit (棚卸) remote data source — Phase 8
///
/// Endpoints:
///   PUT /api/InventStockTakeRecording/GetStockTakeRecordingAsync  → list
///   GET /api/InventStockTakeRecording/GetByIdDTO/{id}             → single (with lines)
///   PUT /api/InventStockTakeRecording/UpdateRangeLineAsync        → batch update lines
class BinAuditRemoteDataSource {
  final DioClient _dioClient;

  BinAuditRemoteDataSource(DioClient dioClient) : _dioClient = dioClient;

  // ─── List ─────────────────────────────────────────────────────

  Future<List<InventStockTakeRecording>> getRecordings() async {
    final res = await _dioClient.dio.put(
      '/api/InventStockTakeRecording/GetStockTakeRecordingAsync',
      data: {},
    );
    return _parseList(res.data)
        .map((m) => InventStockTakeRecording.fromJson(m))
        .toList();
  }

  // ─── Detail ───────────────────────────────────────────────────

  Future<InventStockTakeRecording> getRecordingById(String id) async {
    final res = await _dioClient.dio.get(
      '/api/InventStockTakeRecording/GetByIdDTO/$id',
    );
    final data = _extractSingle(res.data);
    return InventStockTakeRecording.fromJson(data);
  }

  // ─── Update ───────────────────────────────────────────────────

  Future<void> updateRangeLines(List<Map<String, dynamic>> lines) async {
    await _dioClient.dio.put(
      '/api/InventStockTakeRecording/UpdateRangeLineAsync',
      data: lines,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────

  List<Map<String, dynamic>> _parseList(dynamic body) {
    if (body == null) return [];
    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (body is Map) {
      for (final key in [
        'data',
        'items',
        'result',
        'Data',
        'Items',
        'Results',
      ]) {
        final v = body[key];
        if (v is List) {
          return v
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }
    return [];
  }

  Map<String, dynamic> _extractSingle(dynamic body) {
    if (body == null) return {};
    if (body is Map) {
      if (body.containsKey('data') && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data'] as Map);
      }
      return Map<String, dynamic>.from(body);
    }
    return {};
  }
}
