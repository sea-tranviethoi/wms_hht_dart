import '../../../core/network/dio_client.dart';
import '../../models/bundle/bundle.dart';
import '../../models/bundle/bundle_line.dart';

/// Remote data source for the Bundle module (事前セット)
class BundleRemoteDataSource {
  final DioClient _dioClient;

  BundleRemoteDataSource(this._dioClient);

  // ─── Bundles ──────────────────────────────────────────────────

  /// GET /api/InventBundle
  Future<List<Bundle>> getBundles() async {
    final res = await _dioClient.dio.get('/api/InventBundle');
    return _parseList(res.data, Bundle.fromJson);
  }

  // ─── Bundle Lines ─────────────────────────────────────────────

  /// GET /api/InventBundleLine/GetProductsByTransNo/{transNo}
  Future<List<BundleLine>> getLinesByTransNo(String transNo) async {
    final res = await _dioClient.dio.get(
      '/api/InventBundleLine/GetProductsByTransNo/$transNo',
    );
    return _parseList(res.data, BundleLine.fromJson);
  }

  // ─── Sync ─────────────────────────────────────────────────────

  /// POST /api/InventBundle/UploadFromHandheldAsync
  ///
  /// The server binds a single `InventBundleDTO` (object), NOT an array.
  /// The lines are in the `inventBundleLines` field.
  Future<bool> uploadFromHandheld(Map<String, dynamic> data) async {
    final res = await _dioClient.dio.post(
      '/api/InventBundle/UploadFromHandheldAsync',
      data: data,
    );
    final body = res.data;
    if (body is Map) return body['succeeded'] == true;
    return res.statusCode == 200;
  }

  // ─── Common ───────────────────────────────────────────────────

  /// POST /api/Common/UpdateHHTStatusAsync
  Future<bool> updateHHTStatus({
    required int status,
    required int masterId,
    required int detailId,
    String? hhtInfo,
  }) async {
    final res = await _dioClient.dio.post(
      '/api/Common/UpdateHHTStatusAsync',
      data: {
        'status': status,
        'masterId': masterId,
        'detailId': detailId,
        if (hhtInfo != null) 'hhtInfo': hhtInfo,
      },
    );
    return res.statusCode == 200;
  }

  // ─── Helper ───────────────────────────────────────────────────

  List<T> _parseList<T>(
      dynamic raw, T Function(Map<String, dynamic>) fromJson) {
    List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map && raw['data'] is List) {
      list = raw['data'] as List;
    } else {
      return [];
    }
    return list.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}
