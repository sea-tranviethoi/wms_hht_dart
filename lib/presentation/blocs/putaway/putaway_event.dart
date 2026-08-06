part of 'putaway_bloc.dart';

abstract class PutawayEvent {}

/// Load the putaway list (all tenants)
class FetchPutawayLists extends PutawayEvent {
  final String hhtInfo;
  FetchPutawayLists({this.hhtInfo = ''});
}

/// Filter the list by keyword
class SearchPutawayLists extends PutawayEvent {
  final String keyword;
  SearchPutawayLists(this.keyword);
}

/// Reset state
class ResetPutawayState extends PutawayEvent {}
