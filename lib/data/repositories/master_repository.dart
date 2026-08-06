import '../datasources/remote/master_remote_datasource.dart';
import '../models/tenant.dart';
import '../models/master/location.dart';

/// Repository for Master Data (tenants + locations)
/// Acts as the bridge between the BLoC and the data source
class MasterRepository {
  final MasterRemoteDataSource _remote;

  MasterRepository({required MasterRemoteDataSource remote})
      : _remote = remote;

  /// Fetches the list of tenants from the server
  Future<List<Tenant>> getTenants() => _remote.getTenants();

  /// Fetches the list of locations from the server
  Future<List<Location>> getLocations() => _remote.getLocations();
}
