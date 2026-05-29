part of 'bin_movement_bloc.dart';

abstract class BinMovementState {}

class BinMovementInitial extends BinMovementState {}

class BinMovementLoading extends BinMovementState {}

class BinMovementResetting extends BinMovementState {}

class BinMovementListsLoaded extends BinMovementState {
  final List<BinMovementRow> rows;
  final String hhtInfo;
  BinMovementListsLoaded({required this.rows, required this.hhtInfo});
}

class BinMovementError extends BinMovementState {
  final String message;
  BinMovementError(this.message);
}

// ─── View-model row ───────────────────────────────────────────

class BinMovementRow {
  final String id;
  final String transferNo;
  final String? description;
  final String? productNames;
  final String? fromBin;
  final String? toBin;
  /// -1 = 未処理, 1 = この端末, 3 = 別端末
  final int scanStatus;
  final String? hhtInfoOther;
  final List<InventTransferLine> lines;

  const BinMovementRow({
    required this.id,
    required this.transferNo,
    this.description,
    this.productNames,
    this.fromBin,
    this.toBin,
    required this.scanStatus,
    this.hhtInfoOther,
    this.lines = const [],
  });
}
