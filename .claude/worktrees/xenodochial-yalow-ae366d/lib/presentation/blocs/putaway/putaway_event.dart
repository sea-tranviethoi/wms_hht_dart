part of 'putaway_bloc.dart';

abstract class PutawayEvent {}

/// Load danh sách putaway (tất cả tenants)
class FetchPutawayLists extends PutawayEvent {
  final String hhtInfo;
  FetchPutawayLists({this.hhtInfo = ''});
}

/// Lọc danh sách theo keyword
class SearchPutawayLists extends PutawayEvent {
  final String keyword;
  SearchPutawayLists(this.keyword);
}

/// Reset state
class ResetPutawayState extends PutawayEvent {}
