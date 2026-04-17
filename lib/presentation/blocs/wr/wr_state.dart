part of 'wr_bloc.dart';

abstract class WRState {}

class WRInitial extends WRState {}

class WRLoading extends WRState {}

class WRResetting extends WRState {}

class WRListsLoaded extends WRState {
  final List<WRRow> rows;
  final String hhtInfo;

  WRListsLoaded({required this.rows, required this.hhtInfo});
}

class WRError extends WRState {
  final String message;
  WRError(this.message);
}

class WRResetDone extends WRState {}

// ─── View model row ───────────────────────────────────────────

class WRRow {
  final int id;
  final String receiptNo;
  final String? supplierName;
  final String? productNames;
  final int scanStatus; // -1=not scanned, 2=this device, 3=other device
  final String? hhtInfoOther; // hhtInfo value from API (other device user)

  const WRRow({
    required this.id,
    required this.receiptNo,
    this.supplierName,
    this.productNames,
    required this.scanStatus,
    this.hhtInfoOther,
  });
}
