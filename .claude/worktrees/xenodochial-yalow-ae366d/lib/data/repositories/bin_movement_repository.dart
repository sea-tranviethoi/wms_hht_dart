import '../datasources/remote/bin_movement_remote_datasource.dart';
import '../models/bin_movement/invent_transfer.dart';
import '../models/bin_movement/invent_transfer_line.dart';

/// Repository cho 棚移動 (Bin Movement)
/// Wrapper mỏng quanh [BinMovementRemoteDataSource] — BLoC gọi qua đây.
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

  // ─── Staging ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getStagingByNo(String transferNo) =>
      _remote.getStagingByNo(transferNo);

  Future<bool> addStagingRange(List<Map<String, dynamic>> stagingList) =>
      _remote.addStagingRange(stagingList);

  Future<bool> deleteStaging(Map<String, dynamic> staging) =>
      _remote.deleteStaging(staging);

  // ─── Complete ─────────────────────────────────────────────────

  Future<bool> completeTransfer() => _remote.completeTransfer();

  // ─── HHT Status ───────────────────────────────────────────────

  Future<bool> updateHHTStatus({
    required int status,
    required int masterId,
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
