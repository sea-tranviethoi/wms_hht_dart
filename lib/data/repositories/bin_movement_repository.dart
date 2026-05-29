import '../datasources/remote/bin_movement_remote_datasource.dart';
import '../models/bin_movement/invent_transfer.dart';
import '../models/bin_movement/invent_transfer_line.dart';

/// Repository for 棚移動 (Bin Movement)
/// Thin wrapper around [BinMovementRemoteDataSource] — the BLoC calls this.
class BinMovementRepository {
  final BinMovementRemoteDataSource _remote;

  BinMovementRepository({required BinMovementRemoteDataSource remote})
      : _remote = remote;

  // ─── Transfers ────────────────────────────────────────────────

  Future<List<InventTransfer>> getTransfers() => _remote.getTransfers();

  Future<List<InventTransfer>> getTransfersByNo(String transferNo) =>
      _remote.getTransfersByNo(transferNo);

  // ─── Lines ────────────────────────────────────────────────────

  Future<List<InventTransferLine>> getLines() => _remote.getLines();

  Future<List<InventTransferLine>> getLinesByTransferNo(String transferNo) =>
      _remote.getLinesByTransferNo(transferNo);

  // ─── Update line ──────────────────────────────────────────────

  Future<bool> updateLine(Map<String, dynamic> line) =>
      _remote.updateLine(line);

  // ─── Complete ─────────────────────────────────────────────────

  Future<bool> completeTransfer(String id) => _remote.completeTransfer(id);

  // ─── HHT Status ───────────────────────────────────────────────

  Future<bool> updateHHTStatus({
    required int status,
    required String masterId,
    required int detailId,
    String? hhtInfo,
  }) =>
      _remote.updateHHTStatus(
        status: status,
        masterId: masterId,
        detailId: detailId,
        hhtInfo: hhtInfo,
      );
}
