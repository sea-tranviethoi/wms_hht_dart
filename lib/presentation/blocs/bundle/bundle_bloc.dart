import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/remote/bundle_remote_datasource.dart';
import '../../../data/models/bundle/bundle_line.dart';

part 'bundle_event.dart';
part 'bundle_state.dart';

/// BLoC cho module Bundle (事前セット) — thay thế BundleProvider
class BundleBloc extends Bloc<BundleEvent, BundleState> {
  final BundleRemoteDataSource _remote;

  // Cache rows để search client-side
  List<BundleRow> _allRows = [];
  String _hhtInfo = '';

  BundleBloc({required BundleRemoteDataSource remote})
      : _remote = remote,
        super(BundleInitial()) {
    on<FetchBundleLists>(_onFetchBundleLists);
    on<SearchBundleLists>(_onSearchBundleLists);
    on<SelectBundle>(_onSelectBundle);
    on<SyncBundleData>(_onSyncBundleData);
    on<ResetBundleState>(_onReset);
  }

  // ─── Fetch list ───────────────────────────────────────────────

  Future<void> _onFetchBundleLists(
    FetchBundleLists event,
    Emitter<BundleState> emit,
  ) async {
    emit(BundleLoading());
    _hhtInfo = event.hhtInfo;

    try {
      final bundles = await _remote.getBundles();

      // Filter: status == 0, !isDeleted
      final filtered = bundles.where((b) => b.status == 0 && !b.isDeleted).toList();

      _allRows = await Future.wait(filtered.map((b) async {
        // Get line count + first product name
        final lines = await _remote.getLinesByTransNo(b.transNo);
        final productName = lines.isNotEmpty
            ? (lines.first.productName ?? lines.first.productCode)
            : '';

        int scanStatus = 0;
        String hhtInfoOther = '';

        if (b.hhtInfo != null && b.hhtInfo!.isNotEmpty) {
          if (b.hhtInfo!.toLowerCase() == _hhtInfo.toLowerCase()) {
            scanStatus = 1;
          } else {
            scanStatus = 2;
            hhtInfoOther = b.hhtInfo!;
          }
        }

        return BundleRow(
          transNo: b.transNo,
          productName: productName,
          countLine: lines.length,
          scanStatus: scanStatus,
          hhtInfoOther: hhtInfoOther,
        );
      }));

      _allRows.sort((a, b) => a.transNo.compareTo(b.transNo));

      emit(BundleListsLoaded(
        rows: List.from(_allRows),
        hhtInfo: _hhtInfo,
      ));
    } catch (e) {
      emit(BundleError('事前セットデータの取得に失敗しました: $e'));
    }
  }

  // ─── Search ───────────────────────────────────────────────────

  void _onSearchBundleLists(
    SearchBundleLists event,
    Emitter<BundleState> emit,
  ) {
    final kw = event.keyword.toLowerCase();
    final filtered = kw.isEmpty
        ? _allRows
        : _allRows
            .where((r) => r.transNo.toLowerCase().contains(kw) ||
                r.productName.toLowerCase().contains(kw))
            .toList();

    emit(BundleListsLoaded(
      rows: List.from(filtered),
      hhtInfo: _hhtInfo,
    ));
  }

  // ─── Select bundle → load lines ───────────────────────────────

  Future<void> _onSelectBundle(
    SelectBundle event,
    Emitter<BundleState> emit,
  ) async {
    emit(BundleLoading());
    try {
      final lines = await _remote.getLinesByTransNo(event.transNo);
      emit(BundleLinesLoaded(transNo: event.transNo, lines: lines));
    } catch (e) {
      emit(BundleError('事前セット明細の取得に失敗しました: $e'));
    }
  }

  // ─── Sync data → server ───────────────────────────────────────

  Future<void> _onSyncBundleData(
    SyncBundleData event,
    Emitter<BundleState> emit,
  ) async {
    emit(BundleSyncing());
    try {
      await _remote.uploadFromHandheld(event.payload);
      emit(BundleSynced(event.transNo));
    } catch (e) {
      emit(BundleError('データ同期に失敗しました: $e'));
    }
  }

  void _onReset(ResetBundleState event, Emitter<BundleState> emit) {
    _allRows = [];
    emit(BundleInitial());
  }
}
