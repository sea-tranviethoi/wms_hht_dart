part of 'bin_movement_bloc.dart';

abstract class BinMovementEvent {}

class FetchBinMovementLists extends BinMovementEvent {
  final String hhtInfo;
  FetchBinMovementLists({required this.hhtInfo});
}

class SearchBinMovementLists extends BinMovementEvent {
  final String keyword;
  SearchBinMovementLists(this.keyword);
}

class ResetBinMovementStatus extends BinMovementEvent {
  final BinMovementRow row;
  ResetBinMovementStatus(this.row);
}

class ResetBinMovementState extends BinMovementEvent {}
