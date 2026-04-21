import '../datasources/remote/bin_audit_remote_datasource.dart';
import '../models/stocktake/invent_stocktake_recording.dart';

/// Repository cho 棚卸 (Bin Audit / Stocktake)
/// Wrapper mỏng quanh [BinAuditRemoteDataSource] — BLoC gọi qua đây.
///
/// Note: stocktake và bin_audit dùng cùng endpoint /api/InventStockTakeRecording,
/// nên chỉ cần repo này.
class BinAuditRepository {
  final BinAuditRemoteDataSource _remote;

  BinAuditRepository({required BinAuditRemoteDataSource remote})
      : _remote = remote;

  // ─── List ─────────────────────────────────────────────────────

  Future<List<InventStockTakeRecording>> getRecordings() =>
      _remote.getRecordings();

  // ─── Detail ───────────────────────────────────────────────────

  Future<InventStockTakeRecording> getRecordingById(String id) =>
      _remote.getRecordingById(id);

  // ─── Update ───────────────────────────────────────────────────

  Future<void> updateRangeLines(List<Map<String, dynamic>> lines) =>
      _remote.updateRangeLines(lines);
}
