import '../datasources/remote/bin_audit_remote_datasource.dart';
import '../models/stocktake/invent_stocktake_recording.dart';

/// Repository for 棚卸 (Bin Audit / Stocktake)
/// Thin wrapper around [BinAuditRemoteDataSource] — the BLoC calls this.
///
/// Note: stocktake and bin_audit share the same endpoint /api/InventStockTakeRecording,
/// so only this repository is needed.
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
