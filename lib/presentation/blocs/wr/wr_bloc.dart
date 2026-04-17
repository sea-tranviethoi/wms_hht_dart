import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/remote/wr_remote_datasource.dart';
import '../../../data/models/warehouse_receipt/receipt_line.dart';
import '../../../data/models/warehouse_receipt/receipt_order.dart';

part 'wr_event.dart';
part 'wr_state.dart';

class WRBloc extends Bloc<WREvent, WRState> {
  final WRRemoteDataSource _remote;

  List<WRRow> _allRows = [];
  String _hhtInfo = '';
  int _tenantId = 0;

  WRBloc({required WRRemoteDataSource remote})
      : _remote = remote,
        super(WRInitial()) {
    on<FetchWRLists>(_onFetch);
    on<SearchWRLists>(_onSearch);
    on<ResetWRStatus>(_onResetStatus);
    on<ResetWRState>(_onReset);
  }

  // ─── Handlers ─────────────────────────────────────────────────

  Future<void> _onFetch(FetchWRLists event, Emitter<WRState> emit) async {
    emit(WRLoading());
    try {
      _hhtInfo = event.hhtInfo;
      _tenantId = event.tenantId;

      final results = await Future.wait([
        _remote.getOrders(),
        _remote.getLines(),
      ]);
      final orders = results[0] as List<ReceiptOrder>;
      final lines = results[1] as List<ReceiptLine>;

      // Filter: active, not deleted, tenant matches
      var filtered = orders.where((o) {
        if (o.isDeleted) return false;
        if (o.status != 1) return false;
        if (event.tenantId != 0 && o.tenantId != event.tenantId) return false;
        return true;
      }).toList();

      // Optional filter: vendor
      if (event.vendorId != null && event.vendorId!.isNotEmpty) {
        final vid = int.tryParse(event.vendorId!);
        if (vid != null) {
          filtered = filtered.where((o) => o.supplierId == vid).toList();
        }
      }

      // Optional filter: arrival number
      if (event.arrivalNumber != null && event.arrivalNumber!.isNotEmpty) {
        final kw = event.arrivalNumber!.toLowerCase();
        filtered = filtered
            .where((o) =>
                o.scheduledArrivalNumber?.toLowerCase().contains(kw) ?? false)
            .toList();
      }

      // Optional filter: product code
      if (event.productCode != null && event.productCode!.isNotEmpty) {
        final kw = event.productCode!.toLowerCase();
        final nos = lines
            .where((l) => l.productCode.toLowerCase().contains(kw))
            .map((l) => l.receiptNo)
            .toSet();
        filtered = filtered.where((o) => nos.contains(o.receiptNo)).toList();
      }

      // Optional filter: product name (search in productNames field)
      if (event.productName != null && event.productName!.isNotEmpty) {
        final kw = event.productName!.toLowerCase();
        filtered = filtered
            .where((o) =>
                o.productNames?.toLowerCase().contains(kw) ?? false)
            .toList();
      }

      // Build view-model rows
      _allRows = filtered.map((o) {
        int scanStatus = -1;
        if (_hhtInfo.isNotEmpty && o.hhtInfo == _hhtInfo) {
          scanStatus = 2; // scanned by this device
        } else if (o.hhtInfo != null && o.hhtInfo!.isNotEmpty) {
          scanStatus = 3; // handled by other device
        }

        return WRRow(
          id: o.id ?? 0,
          receiptNo: o.receiptNo,
          supplierName: o.supplierName,
          productNames: o.productNames,
          scanStatus: scanStatus,
          hhtInfoOther: o.hhtInfo,
        );
      }).toList();

      emit(WRListsLoaded(rows: _allRows, hhtInfo: _hhtInfo));
    } catch (e) {
      emit(WRError(e.toString()));
    }
  }

  void _onSearch(SearchWRLists event, Emitter<WRState> emit) {
    if (event.keyword.isEmpty) {
      emit(WRListsLoaded(rows: _allRows, hhtInfo: _hhtInfo));
      return;
    }
    final kw = event.keyword.toLowerCase();
    final filtered = _allRows.where((r) {
      return r.receiptNo.toLowerCase().contains(kw) ||
          (r.supplierName?.toLowerCase().contains(kw) ?? false) ||
          (r.productNames?.toLowerCase().contains(kw) ?? false);
    }).toList();
    emit(WRListsLoaded(rows: filtered, hhtInfo: _hhtInfo));
  }

  Future<void> _onResetStatus(
      ResetWRStatus event, Emitter<WRState> emit) async {
    if (event.row.id <= 0) return;
    emit(WRResetting());
    try {
      await _remote.updateHHTStatus(
        status: 0,
        receiptId: event.row.id,
        flag: 0,
        hhtInfo: '',
      );
      // Reload the list
      add(FetchWRLists(hhtInfo: _hhtInfo, tenantId: _tenantId));
    } catch (e) {
      emit(WRError(e.toString()));
    }
  }

  void _onReset(ResetWRState event, Emitter<WRState> emit) {
    _allRows = [];
    emit(WRInitial());
  }
}
