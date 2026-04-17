import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/remote/bin_audit_remote_datasource.dart';

part 'bin_audit_event.dart';
part 'bin_audit_state.dart';

class BinAuditBloc extends Bloc<BinAuditEvent, BinAuditState> {
  final BinAuditRemoteDataSource _remote;
  List<BinAuditRow> _allRows = [];

  BinAuditBloc({required BinAuditRemoteDataSource remote})
      : _remote = remote,
        super(BinAuditInitial()) {
    on<FetchBinAuditList>(_onFetch);
    on<SearchBinAuditList>(_onSearch);
    on<ResetBinAuditState>(_onReset);
  }

  // ─── Fetch ────────────────────────────────────────────────────

  Future<void> _onFetch(
    FetchBinAuditList event,
    Emitter<BinAuditState> emit,
  ) async {
    emit(BinAuditLoading());
    try {
      final recordings = await _remote.getRecordings();

      // Sort: largest stockTakeNo number first (descending)
      recordings.sort((a, b) {
        final aNo = _extractLastNumber(a.stockTakeNo ?? '');
        final bNo = _extractLastNumber(b.stockTakeNo ?? '');
        if (aNo != null && bNo != null) return bNo.compareTo(aNo);
        return (b.stockTakeNo ?? '').compareTo(a.stockTakeNo ?? '');
      });

      _allRows = recordings
          .where((r) => r.id != null && r.id!.isNotEmpty)
          .map(
            (r) => BinAuditRow(
              id: r.id!,
              stockTakeNo: r.stockTakeNo ?? '',
              recordNo: r.recordNo,
              location: r.location,
              personInCharge: r.personInCharge,
              transactionDate: r.transactionDate,
              status: r.status,
            ),
          )
          .toList();

      emit(BinAuditListLoaded(rows: List.from(_allRows)));
    } catch (e) {
      emit(BinAuditError('棚卸データの取得に失敗しました: $e'));
    }
  }

  // ─── Search ───────────────────────────────────────────────────

  void _onSearch(
    SearchBinAuditList event,
    Emitter<BinAuditState> emit,
  ) {
    final kw = event.keyword.toLowerCase();
    final filtered = kw.isEmpty
        ? _allRows
        : _allRows.where((r) {
            return r.stockTakeNo.toLowerCase().contains(kw) ||
                (r.location?.toLowerCase().contains(kw) ?? false) ||
                (r.personInCharge?.toLowerCase().contains(kw) ?? false) ||
                (r.recordNo?.toString().contains(kw) ?? false);
          }).toList();
    emit(BinAuditListLoaded(rows: List.from(filtered)));
  }

  // ─── Reset ────────────────────────────────────────────────────

  void _onReset(ResetBinAuditState event, Emitter<BinAuditState> emit) {
    _allRows = [];
    emit(BinAuditInitial());
  }

  // ─── Helpers ─────────────────────────────────────────────────

  int? _extractLastNumber(String s) {
    final matches = RegExp(r'\d+').allMatches(s);
    if (matches.isEmpty) return null;
    return int.tryParse(matches.last.group(0) ?? '');
  }
}
