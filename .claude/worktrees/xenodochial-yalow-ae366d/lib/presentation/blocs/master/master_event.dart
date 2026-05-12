part of 'master_bloc.dart';

abstract class MasterEvent {}

/// Load danh sách tenant
class FetchTenants extends MasterEvent {}

/// Load danh sách location
class FetchLocations extends MasterEvent {}
