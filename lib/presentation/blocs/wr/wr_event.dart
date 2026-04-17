part of 'wr_bloc.dart';

abstract class WREvent {}

class FetchWRLists extends WREvent {
  final String hhtInfo;
  final int tenantId;
  final String? vendorId;
  final String? productCode;
  final String? productName;
  final String? janCode;
  final String? arrivalNumber;

  FetchWRLists({
    required this.hhtInfo,
    required this.tenantId,
    this.vendorId,
    this.productCode,
    this.productName,
    this.janCode,
    this.arrivalNumber,
  });
}

class SearchWRLists extends WREvent {
  final String keyword;
  SearchWRLists(this.keyword);
}

class ResetWRStatus extends WREvent {
  final WRRow row;
  ResetWRStatus(this.row);
}

class ResetWRState extends WREvent {}
