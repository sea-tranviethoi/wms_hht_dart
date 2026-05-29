part of 'bundle_bloc.dart';

abstract class BundleEvent {}

/// Load the list of bundles
class FetchBundleLists extends BundleEvent {
  final String hhtInfo;
  FetchBundleLists({this.hhtInfo = ''});
}

/// Filter the list by keyword
class SearchBundleLists extends BundleEvent {
  final String keyword;
  SearchBundleLists(this.keyword);
}

/// Select one bundle → load its lines
class SelectBundle extends BundleEvent {
  final String transNo;
  SelectBundle(this.transNo);
}

/// Sync bundle data to server
///
/// [payload] is an InventBundleDTO object (contains the inventBundleLines field).
class SyncBundleData extends BundleEvent {
  final String transNo;
  final Map<String, dynamic> payload;

  SyncBundleData({
    required this.transNo,
    required this.payload,
  });
}

/// Reset state
class ResetBundleState extends BundleEvent {}
