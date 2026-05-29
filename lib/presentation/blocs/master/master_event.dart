part of 'master_bloc.dart';

abstract class MasterEvent {}

/// Load the list of tenants
class FetchTenants extends MasterEvent {}

/// Load the list of locations
class FetchLocations extends MasterEvent {}
