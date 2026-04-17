part of 'master_bloc.dart';

abstract class MasterState extends Equatable {
  const MasterState();
  @override
  List<Object?> get props => [];
}

class MasterInitial extends MasterState {
  const MasterInitial();
}

class MasterLoading extends MasterState {
  const MasterLoading();
}

class TenantsLoaded extends MasterState {
  final List<Tenant> tenants;
  const TenantsLoaded(this.tenants);
  @override
  List<Object?> get props => [tenants];
}

class LocationsLoaded extends MasterState {
  final List<Location> locations;
  const LocationsLoaded(this.locations);
  @override
  List<Object?> get props => [locations];
}

class MasterError extends MasterState {
  final String message;
  const MasterError(this.message);
  @override
  List<Object?> get props => [message];
}
