import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/bin_movement/invent_transfer.dart';
import '../../../data/models/bin_movement/invent_transfer_line.dart';
import '../../../data/repositories/bin_movement_repository.dart';

part 'bin_movement_event.dart';
part 'bin_movement_state.dart';

class BinMovementBloc extends Bloc<BinMovementEvent, BinMovementState> {
  final BinMovementRepository _repository;

  List<BinMovementRow> _allRows = [];
  String _hhtInfo = '';

  BinMovementBloc({required BinMovementRepository repository})
      : _repository = repository,
        super(BinMovementInitial()) {
    on<FetchBinMovementLists>(_onFetch);
    on<SearchBinMovementLists>(_onSearch);
    on<ResetBinMovementStatus>(_onResetStatus);
    on<ResetBinMovementState>(_onReset);
  }

  // ─── Fetch ────────────────────────────────────────────────────

  Future<void> _onFetch(
    FetchBinMovementLists event,
    Emitter<BinMovementState> emit,
  ) async {
    emit(BinMovementLoading());
    _hhtInfo = event.hhtInfo;

    try {
      final results = await Future.wait([
        _repository.getTransfers(),
        _repository.getLines(),
      ]);

      final allTransfers = results[0] as List<InventTransfer>;
      final allLines = results[1] as List<InventTransferLine>;

      // Filter: status==0 (pending), not deleted
      final filtered = allTransfers
          .where((t) => !t.isDeleted && t.status == 0)
          .toList();

      // Build rows
      _allRows = filtered.map((transfer) {
        // Lines belonging to this transfer
        final lines = allLines
            .where((l) =>
                !l.isDeleted && l.transferNo == transfer.transferNo)
            .toList();

        // Compute scanStatus
        int scanStatus = -1;
        if (_hhtInfo.isNotEmpty &&
            transfer.hhtInfo != null &&
            transfer.hhtInfo!.toLowerCase() == _hhtInfo.toLowerCase()) {
          scanStatus = 1;
        } else if (transfer.hhtInfo != null &&
            transfer.hhtInfo!.isNotEmpty) {
          scanStatus = 3;
        }

        // Collect product names from lines
        final names = lines
            .map((l) => l.productName ?? l.productCode)
            .where((n) => n.isNotEmpty)
            .toSet()
            .join(', ');

        return BinMovementRow(
          id: transfer.id ?? 0,
          transferNo: transfer.transferNo,
          description: transfer.description,
          productNames: names.isNotEmpty ? names : null,
          fromBin: transfer.fromBin,
          toBin: transfer.toBin,
          scanStatus: scanStatus,
          hhtInfoOther: transfer.hhtInfo,
          lines: lines,
        );
      }).toList();

      emit(BinMovementListsLoaded(
        rows: List.from(_allRows),
        hhtInfo: _hhtInfo,
      ));
    } catch (e) {
      emit(BinMovementError('棚移動データの取得に失敗しました: $e'));
    }
  }

  // ─── Search ───────────────────────────────────────────────────

  void _onSearch(
    SearchBinMovementLists event,
    Emitter<BinMovementState> emit,
  ) {
    final kw = event.keyword.toLowerCase();
    final filtered = kw.isEmpty
        ? _allRows
        : _allRows.where((r) {
            return r.transferNo.toLowerCase().contains(kw) ||
                (r.description?.toLowerCase().contains(kw) ?? false) ||
                (r.productNames?.toLowerCase().contains(kw) ?? false) ||
                (r.fromBin?.toLowerCase().contains(kw) ?? false) ||
                (r.toBin?.toLowerCase().contains(kw) ?? false);
          }).toList();

    emit(BinMovementListsLoaded(
      rows: List.from(filtered),
      hhtInfo: _hhtInfo,
    ));
  }

  // ─── Reset status ─────────────────────────────────────────────

  Future<void> _onResetStatus(
    ResetBinMovementStatus event,
    Emitter<BinMovementState> emit,
  ) async {
    if (event.row.id <= 0) return;
    emit(BinMovementResetting());
    try {
      await _repository.updateHHTStatus(
        status: 0,
        masterId: event.row.id,
        detailId: 0,
        hhtInfo: '',
      );
      add(FetchBinMovementLists(hhtInfo: _hhtInfo));
    } catch (e) {
      emit(BinMovementError(e.toString()));
    }
  }

  void _onReset(ResetBinMovementState event, Emitter<BinMovementState> emit) {
    _allRows = [];
    emit(BinMovementInitial());
  }
}
