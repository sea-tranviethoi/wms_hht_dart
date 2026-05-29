import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/remote/picking_remote_datasource.dart';
import '../../../data/models/picking/picking_line.dart';
import '../../../data/models/picking/picking_staging.dart';

part 'picking_event.dart';
part 'picking_state.dart';

/// BLoC for the Picking module — replaces PickingProvider
class PickingBloc extends Bloc<PickingEvent, PickingState> {
  final PickingRemoteDataSource _remote;

  // Cache the full list for client-side search
  List<PickingRow> _allRows = [];
  int _tenantId = 0;
  String _hhtInfo = '';

  PickingBloc({required PickingRemoteDataSource remote})
      : _remote = remote,
        super(const PickingInitial()) {
    on<FetchPickingLists>(_onFetchPickingLists);
    on<SearchPickingLists>(_onSearchPickingLists);
    on<SelectPickingList>(_onSelectPickingList);
    on<SyncPickingData>(_onSyncPickingData);
    on<ResetPickingState>(_onReset);
  }

  // ─── Fetch list ───────────────────────────────────────────────

  Future<void> _onFetchPickingLists(
    FetchPickingLists event,
    Emitter<PickingState> emit,
  ) async {
    emit(const PickingLoading());
    _tenantId = event.tenantId;
    _hhtInfo = event.hhtInfo;

    try {
      // Load lists + staging in parallel
      final results = await Future.wait([
        _remote.getPickingLists(),
        _remote.getAllStaging(),
      ]);

      final allLists = results[0] as List;
      final allStaging = results[1] as List;

      // Filter: tenantId, status ∈ {2, 13}, not deleted
      final filtered = allLists.where((l) {
        return l.tenantId == event.tenantId &&
            (l.status == 2 || l.status == 13) &&
            !l.isDeleted;
      }).toList();

      // Count bins per pickNo from staging
      final binCounts = <String, int>{};
      for (final l in filtered) {
        final count = allStaging
            .where((s) => s.pickNo == l.pickNo && !s.isDeleted)
            .length;
        binCounts[l.pickNo] = count;
      }

      // Build rows with scanStatus
      _allRows = filtered.map((l) {
        int scanStatus = 0;
        String hhtInfoOther = '';

        if (l.hhtInfo != null && (l.hhtInfo as String).isNotEmpty) {
          final hi = (l.hhtInfo as String).toLowerCase();
          if (hi == event.hhtInfo.toLowerCase()) {
            scanStatus = 1; // This device
          } else {
            scanStatus = 2; // Other device
            hhtInfoOther = l.hhtInfo as String;
          }
        }

        return PickingRow(
          pickNo: l.pickNo as String,
          binCount: binCounts[l.pickNo] ?? 0,
          scanStatus: scanStatus,
          hhtInfoOther: hhtInfoOther,
        );
      }).toList()
        ..sort((a, b) => a.pickNo.compareTo(b.pickNo));

      emit(PickingListsLoaded(
        rows: List.from(_allRows),
        tenantId: event.tenantId,
        hhtInfo: event.hhtInfo,
      ));
    } catch (e) {
      emit(PickingError('ピッキングデータの取得に失敗しました: $e'));
    }
  }

  // ─── Search ───────────────────────────────────────────────────

  void _onSearchPickingLists(
    SearchPickingLists event,
    Emitter<PickingState> emit,
  ) {
    final kw = event.keyword.toLowerCase();
    final filtered = kw.isEmpty
        ? _allRows
        : _allRows
            .where((r) => r.pickNo.toLowerCase().contains(kw))
            .toList();
    emit(PickingListsLoaded(
      rows: List.from(filtered),
      tenantId: _tenantId,
      hhtInfo: _hhtInfo,
    ));
  }

  // ─── Select picking list → load lines ─────────────────────────

  Future<void> _onSelectPickingList(
    SelectPickingList event,
    Emitter<PickingState> emit,
  ) async {
    emit(const PickingLoading());
    try {
      final lines = await _remote.getPickingLinesByNo(event.pickNo);
      emit(PickingLinesLoaded(pickNo: event.pickNo, lines: lines));
    } catch (e) {
      emit(PickingError('ピッキング明細の取得に失敗しました: $e'));
    }
  }

  // ─── Sync data → server ───────────────────────────────────────

  Future<void> _onSyncPickingData(
    SyncPickingData event,
    Emitter<PickingState> emit,
  ) async {
    emit(const PickingSyncing());
    try {
      // 1. Build PickingStaging records
      final stagingList = event.stagingList.map((p) => PickingStaging(
            pickNo: event.pickNo,
            productCode: p.productCode,
            bin: p.bin,
            lotNo: p.lotNo,
            pickQty: p.pickQty,
            actualQty: p.actualQty,
            status: 1,
            shipmentLineId: p.shipmentLineId,
            unitId: p.unitId,
            unit: p.unit,
          )).toList();

      // 2. Delete old staging + add new
      final existingStaging = await _remote.getStagingByNo(event.pickNo);
      final toDelete =
          existingStaging.where((s) => s.id != null).toList();
      if (toDelete.isNotEmpty) {
        await _remote.deleteStagingRange(toDelete);
      }
      await _remote.addStagingRange(stagingList);

      // 3. Complete picking
      await _remote.completePicking(event.pickNo);

      emit(PickingSynced(event.pickNo));
    } catch (e) {
      emit(PickingError('データ同期に失敗しました: $e'));
    }
  }

  void _onReset(ResetPickingState event, Emitter<PickingState> emit) {
    _allRows = [];
    emit(const PickingInitial());
  }
}
