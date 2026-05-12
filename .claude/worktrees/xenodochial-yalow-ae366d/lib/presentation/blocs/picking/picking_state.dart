part of 'picking_bloc.dart';

abstract class PickingState extends Equatable {
  const PickingState();
  @override
  List<Object?> get props => [];
}

class PickingInitial extends PickingState {
  const PickingInitial();
}

class PickingLoading extends PickingState {
  const PickingLoading();
}

/// State cho PickingListScreen
class PickingListsLoaded extends PickingState {
  final List<PickingRow> rows;
  final int tenantId;
  final String hhtInfo;

  const PickingListsLoaded({
    required this.rows,
    required this.tenantId,
    required this.hhtInfo,
  });

  @override
  List<Object?> get props => [rows, tenantId];
}

/// State cho PickingItemsScreen
class PickingLinesLoaded extends PickingState {
  final String pickNo;
  final List<PickingLine> lines;

  const PickingLinesLoaded({required this.pickNo, required this.lines});

  @override
  List<Object?> get props => [pickNo, lines];
}

class PickingSyncing extends PickingState {
  const PickingSyncing();
}

class PickingSynced extends PickingState {
  final String pickNo;
  const PickingSynced(this.pickNo);
  @override
  List<Object?> get props => [pickNo];
}

class PickingError extends PickingState {
  final String message;
  const PickingError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── View Model ───────────────────────────────────────────────

/// Row data cho PickingListScreen
class PickingRow extends Equatable {
  final String pickNo;
  final int binCount;

  /// 0 = not scanned, 1 = scanned by this device, 2 = handled by other device
  final int scanStatus;
  final String hhtInfoOther;

  const PickingRow({
    required this.pickNo,
    required this.binCount,
    required this.scanStatus,
    this.hhtInfoOther = '',
  });

  @override
  List<Object?> get props => [pickNo, binCount, scanStatus];
}
