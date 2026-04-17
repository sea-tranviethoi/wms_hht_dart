import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/tenant.dart';

class TenantRepository {
  final ApiClient _apiClient;

  TenantRepository(this._apiClient);

  /// Get all tenants
  Future<List<Tenant>> getTenants() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.tenants);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Tenant.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching tenants: $e');
      return [];
    }
  }

  /// Get tenant by ID
  Future<Tenant?> getTenantById(int id) async {
    try {
      final url = ApiEndpoints.tenantsById.replaceAll('{id}', id.toString());
      final response = await _apiClient.dio.get(url);

      if (response.statusCode == 200 && response.data['data'] != null) {
        return Tenant.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('Error fetching tenant by id: $e');
      return null;
    }
  }
}

