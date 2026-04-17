import '../datasources/remote/master_remote_datasource.dart';
import '../models/tenant.dart';
import '../models/master/location.dart';

/// Repository cho Master Data (tenants + locations)
/// Giao tiếp giữa BLoC và data source
class MasterRepository {
  final MasterRemoteDataSource _remote;

  MasterRepository({required MasterRemoteDataSource remote})
      : _remote = remote;

  /// Lấy danh sách tenant từ server
  Future<List<Tenant>> getTenants() => _remote.getTenants();

  /// Lấy danh sách location từ server
  Future<List<Location>> getLocations() => _remote.getLocations();
}
