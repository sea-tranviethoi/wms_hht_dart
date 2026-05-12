part of 'bin_audit_bloc.dart';

abstract class BinAuditState {}

class BinAuditInitial extends BinAuditState {}

class BinAuditLoading extends BinAuditState {}

class BinAuditListLoaded extends BinAuditState {
  final List<BinAuditRow> rows;
  BinAuditListLoaded({required this.rows});
}

class BinAuditError extends BinAuditState {
  final String message;
  BinAuditError(this.message);
}

// ─── View-model row ───────────────────────────────────────────

class BinAuditRow {
  final String id;
  final String stockTakeNo;
  final int? recordNo;
  final String? location;
  final String? personInCharge;
  final DateTime? transactionDate;
  /// '0' = pending (未処理), '1' = done (完了)
  final String? status;

  const BinAuditRow({
    required this.id,
    required this.stockTakeNo,
    this.recordNo,
    this.location,
    this.personInCharge,
    this.transactionDate,
    this.status,
  });

  bool get isPending {
    if (status == null) return false;
    final s = status!.trim();
    return s == '0' || int.tryParse(s) == 0;
  }

  bool get isDone {
    if (status == null) return false;
    final s = status!.trim();
    return s == '1' || int.tryParse(s) == 1;
  }
}
