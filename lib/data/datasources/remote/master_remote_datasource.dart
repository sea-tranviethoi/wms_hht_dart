import '../../../core/network/dio_client.dart';
import '../../models/tenant.dart';
import '../../models/master/location.dart';

/// Remote data source for Master Data
/// Ported from services/masterData.js (tenants, locations, …)
class MasterRemoteDataSource {
  final DioClient _dioClient;

  MasterRemoteDataSource(this._dioClient);

  // ─── Tenants ──────────────────────────────────────────────────

  /// GET /api/Tenants → list of tenants
  Future<List<Tenant>> getTenants() async {
    final res = await _dioClient.dio.get('/api/Tenants');
    final data = res.data;

    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    } else {
      return [];
    }
    return list.map((e) => Tenant.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ─── Locations ────────────────────────────────────────────────

  /// GET /api/Locations → list of warehouse locations
  Future<List<Location>> getLocations() async {
    final res = await _dioClient.dio.get('/api/Locations');
    final data = res.data;

    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    } else {
      return [];
    }
    return list
        .map((e) => Location.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
