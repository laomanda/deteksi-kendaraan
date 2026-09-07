import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/vehicle_model.dart';
import '../data/repositories/vehicle_repository.dart';
import '../../shared/providers/repository_providers.dart';
import '../../garage/presentation/controllers/active_vehicle_controller.dart';

export '../../shared/providers/repository_providers.dart';
export '../../garage/presentation/controllers/active_vehicle_controller.dart';

/// StateNotifier managing vehicle list state (Loading, Data, Error)
class VehicleNotifier extends StateNotifier<AsyncValue<List<VehicleModel>>> {
  final VehicleRepository _repository;
  final Ref _ref;

  VehicleNotifier(this._repository, this._ref)
      : super(_repository.getAllVehicles().isNotEmpty
            ? AsyncValue.data(_repository.getAllVehicles())
            : const AsyncValue.loading()) {
    loadVehicles();
  }

  /// Loads vehicles with offline-first Hive precedence and remote sync
  Future<void> loadVehicles({bool forceRemote = false}) async {
    final localList = _repository.getAllVehicles();
    if (localList.isNotEmpty && state.value == null) {
      state = AsyncValue.data(localList);
    } else if (state.value == null) {
      state = const AsyncValue.loading();
    }

    try {
      final remoteList = await _repository.getVehicles(forceRemote: forceRemote);
      if (!mounted) return;
      state = AsyncValue.data(remoteList);
      _ref.read(activeVehicleProvider.notifier).refresh();
    } catch (e, st) {
      if (!mounted) return;
      if (localList.isNotEmpty) {
        state = AsyncValue.data(localList);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Refreshes vehicle list
  Future<void> refresh() async => loadVehicles();

  /// Adds a new vehicle and automatically updates the state
  Future<VehicleModel> addVehicle(VehicleModel vehicle) async {
    try {
      final created = await _repository.createVehicle(vehicle);
      final currentList = state.value ?? _repository.getAllVehicles();
      final updatedList = [...currentList.where((v) => v.id != created.id), created];
      state = AsyncValue.data(updatedList);
      _ref.read(activeVehicleProvider.notifier).refresh();
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Updates an existing vehicle and automatically updates the state
  Future<VehicleModel> updateVehicle(VehicleModel vehicle) async {
    try {
      final updated = await _repository.updateVehicle(vehicle);
      final currentList = state.value ?? _repository.getAllVehicles();
      final updatedList = currentList.map((v) => v.id == updated.id ? updated : v).toList();
      state = AsyncValue.data(updatedList);
      _ref.read(activeVehicleProvider.notifier).refresh();
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Deletes a vehicle by ID and automatically updates the state
  Future<void> deleteVehicle(String id) async {
    try {
      await _repository.deleteVehicle(id);
      final currentList = state.value ?? _repository.getAllVehicles();
      final updatedList = currentList.where((v) => v.id != id).toList();
      state = AsyncValue.data(updatedList);
      _ref.read(activeVehicleProvider.notifier).refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Riverpod provider exposing the vehicle list AsyncValue
final vehicleProvider =
    StateNotifierProvider<VehicleNotifier, AsyncValue<List<VehicleModel>>>((ref) {
  final repo = ref.watch(vehicleRepositoryProvider);
  return VehicleNotifier(repo, ref);
});

/// Alias for vehicleProvider
final vehicleListProvider = vehicleProvider;
