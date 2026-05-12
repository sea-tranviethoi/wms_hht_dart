part of 'bundle_bloc.dart';

abstract class BundleState {}

class BundleInitial extends BundleState {}

class BundleLoading extends BundleState {}

class BundleListsLoaded extends BundleState {
  final List<BundleRow> rows;
  final String hhtInfo;

  BundleListsLoaded({required this.rows, required this.hhtInfo});
}

class BundleLinesLoaded extends BundleState {
  final String transNo;
  final List<BundleLine> lines;

  BundleLinesLoaded({required this.transNo, required this.lines});
}

class BundleSyncing extends BundleState {}

class BundleSynced extends BundleState {
  final String transNo;
  BundleSynced(this.transNo);
}

class BundleError extends BundleState {
  final String message;
  BundleError(this.message);
}

// ─── View model ───────────────────────────────────────────────

class BundleRow {
  final String transNo;
  final String productName;
  final int countLine;
  /// 0 = not scanned, 1 = this device, 2 = other device
  final int scanStatus;
  final String hhtInfoOther;

  const BundleRow({
    required this.transNo,
    this.productName = '',
    required this.countLine,
    this.scanStatus = 0,
    this.hhtInfoOther = '',
  });
}
