part of 'bin_audit_bloc.dart';

abstract class BinAuditEvent {}

class FetchBinAuditList extends BinAuditEvent {}

class SearchBinAuditList extends BinAuditEvent {
  final String keyword;
  SearchBinAuditList(this.keyword);
}

class ResetBinAuditState extends BinAuditEvent {}
