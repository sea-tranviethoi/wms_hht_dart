import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/remote/putaway_remote_datasource.dart';
import '../../../data/models/putaway/putaway_line.dart';

part 'putaway_event.dart';
part 'putaway_state.dart';

/// BLoC cho module Putaway — thay thế PutawayProvider
class PutawayBloc extends Bloc<PutawayEvent, PutawayState> {
  final PutawayRemoteDataSource _remote;

  // Cache toàn bộ rows để search client-side
  List<PutawayRow> _allRows = [];
  String _hhtInfo = '';

  PutawayBloc({required PutawayRemoteDataSource remote})
      : _remote = remote,
        super(PutawayInitial()) {
    on<FetchPutawayLists>(_onFetchPutawayLists);
    on<SearchPutawayLists>(_onSearchPutawayLists);
    on<ResetPutawayState>(_onReset);
  }

  // ─── Fetch ────────────────────────────────────────────────────

  Future<void> _onFetchPutawayLists(
    FetchPutawayLists event,
    Emitter<PutawayState> emit,
  ) async {
    emit(PutawayLoading());
    _hhtInfo = event.hhtInfo;

    try {
      // Load orders + lines in parallel
      final results = await Future.wait([
        _remote.getPutawayOrders(),
        _remote.getPutawayLines(),
      ]);

      final allOrders = results[0] as List;
      final allLines  = results[1] as List;

      // Filter orders: !isDeleted && status == 0
      final filteredOrders = allOrders
          .where((o) => !o.isDeleted && o.status == 0)
          .toList();

      final putawayNos = filteredOrders.map((o) => o.putAwayNo as String).toSet();

      // Filter lines matching those orders
      final matchingLines = (allLines as List<PutawayLine>)
          .where((l) => !l.isDeleted && putawayNos.contains(l.putAwayNo))
          .toList();

      // Group lines by productCode
      final groupedLines = <String, List<PutawayLine>>{};
      for (final line in matchingLines) {
        groupedLines.putIfAbsent(line.productCode, () => []).add(line);
      }

      // Build rows
      _allRows = groupedLines.entries.map((entry) {
        final productCode = entry.key;
        final lines = entry.value;

        final totalQty = lines.fold<double>(0, (s, l) => s + l.journalQty);
        final scannedQty = lines.fold<double>(
            0, (s, l) => s + (l.transQty ?? 0));

        int scanStatus = -1;
        String hhtInfoOther = '';

        // Find hhtInfo from lines (non-empty)
        final lineWithHht = lines.firstWhere(
          (l) => l.hhtInfo != null && l.hhtInfo!.isNotEmpty,
          orElse: () => lines.first,
        );

        if (lineWithHht.hhtInfo != null &&
            lineWithHht.hhtInfo!.isNotEmpty) {
          if (lineWithHht.hhtInfo!.toLowerCase() ==
              _hhtInfo.toLowerCase()) {
            scanStatus = 1;
          } else {
            scanStatus = 3;
            hhtInfoOther = lineWithHht.hhtInfo!;
          }
        }

        final receiptLineId = lines
            .firstWhere((l) => l.receiptLineId != null,
                orElse: () => lines.first)
            .receiptLineId ?? 0;

        // Product name from the first line that has it
        final productName = lines
            .firstWhere((l) => l.productName != null,
                orElse: () => lines.first)
            .productName ?? '';

        return PutawayRow(
          productCode: productCode,
          productName: productName,
          totalQty: totalQty,
          scannedQty: scannedQty,
          scanStatus: scanStatus,
          hhtInfoOther: hhtInfoOther,
          receiptLineId: receiptLineId,
          lines: lines,
        );
      }).toList()
        ..sort((a, b) => a.productCode.compareTo(b.productCode));

      emit(PutawayListsLoaded(
        rows: List.from(_allRows),
        hhtInfo: _hhtInfo,
      ));
    } catch (e) {
      emit(PutawayError('棚上げデータの取得に失敗しました: $e'));
    }
  }

  // ─── Search ───────────────────────────────────────────────────

  void _onSearchPutawayLists(
    SearchPutawayLists event,
    Emitter<PutawayState> emit,
  ) {
    final kw = event.keyword.toLowerCase();
    final filtered = kw.isEmpty
        ? _allRows
        : _allRows.where((r) {
            return r.productCode.toLowerCase().contains(kw) ||
                r.productName.toLowerCase().contains(kw);
          }).toList();

    emit(PutawayListsLoaded(
      rows: List.from(filtered),
      hhtInfo: _hhtInfo,
    ));
  }

  void _onReset(ResetPutawayState event, Emitter<PutawayState> emit) {
    _allRows = [];
    emit(PutawayInitial());
  }
}
