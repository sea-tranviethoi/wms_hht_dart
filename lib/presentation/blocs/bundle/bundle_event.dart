part of 'bundle_bloc.dart';

abstract class BundleEvent {}

/// Load danh sách bundles
class FetchBundleLists extends BundleEvent {
  final String hhtInfo;
  FetchBundleLists({this.hhtInfo = ''});
}

/// Lọc danh sách theo keyword
class SearchBundleLists extends BundleEvent {
  final String keyword;
  SearchBundleLists(this.keyword);
}

/// Chọn 1 bundle → load lines
class SelectBundle extends BundleEvent {
  final String transNo;
  SelectBundle(this.transNo);
}

/// Sync bundle data to server
///
/// [payload] là object InventBundleDTO (chứa field inventBundleLines).
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
