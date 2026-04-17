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
class SyncBundleData extends BundleEvent {
  final String transNo;
  final int bundleId;
  final List<Map<String, dynamic>> lines;

  SyncBundleData({
    required this.transNo,
    required this.bundleId,
    required this.lines,
  });
}

/// Reset state
class ResetBundleState extends BundleEvent {}
