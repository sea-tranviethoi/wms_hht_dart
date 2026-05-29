import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/tenant.dart';
import '../../../data/models/master/location.dart';
import '../../../data/repositories/master_repository.dart';

part 'master_event.dart';
part 'master_state.dart';

/// BLoC managing Master Data (tenants, locations)
/// Used by TenantSelectionScreen and LocationSelectionScreen
class MasterBloc extends Bloc<MasterEvent, MasterState> {
  final MasterRepository _repository;

  MasterBloc({required MasterRepository repository})
      : _repository = repository,
        super(const MasterInitial()) {
    on<FetchTenants>(_onFetchTenants);
    on<FetchLocations>(_onFetchLocations);
  }

  Future<void> _onFetchTenants(
    FetchTenants event,
    Emitter<MasterState> emit,
  ) async {
    emit(const MasterLoading());
    try {
      final tenants = await _repository.getTenants();
      emit(TenantsLoaded(tenants));
    } catch (e) {
      emit(MasterError('テナント情報の取得に失敗しました: $e'));
    }
  }

  Future<void> _onFetchLocations(
    FetchLocations event,
    Emitter<MasterState> emit,
  ) async {
    emit(const MasterLoading());
    try {
      final locations = await _repository.getLocations();
      emit(LocationsLoaded(locations));
    } catch (e) {
      emit(MasterError('ロケーション情報の取得に失敗しました: $e'));
    }
  }
}
