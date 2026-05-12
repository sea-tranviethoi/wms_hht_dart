part of 'putaway_bloc.dart';

abstract class PutawayState {}

class PutawayInitial extends PutawayState {}

class PutawayLoading extends PutawayState {}

class PutawayListsLoaded extends PutawayState {
  final List<PutawayRow> rows;
  final String hhtInfo;

  PutawayListsLoaded({required this.rows, required this.hhtInfo});
}

class PutawayError extends PutawayState {
  final String message;
  PutawayError(this.message);
}

// ─── View model ───────────────────────────────────────────────

class PutawayRow {
  final String productCode;
  final String productName;
  final double totalQty;
  final double scannedQty;
  /// -1 = not scanned, 1 = this device, 3 = other device
  final int scanStatus;
  final String hhtInfoOther;
  final int receiptLineId;
  final List<PutawayLine> lines;

  const PutawayRow({
    required this.productCode,
    this.productName = '',
    required this.totalQty,
    this.scannedQty = 0,
    this.scanStatus = -1,
    this.hhtInfoOther = '',
    this.receiptLineId = 0,
    this.lines = const [],
  });
}
