import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../../shared/providers/repository_providers.dart';

class ActiveVehicleNotifier extends Notifier<VehicleModel?> {
  late final VehicleRepository _repository;

  @override
  VehicleModel? build() {
    _repository = ref.watch(vehicleRepositoryProvider);
    return _repository.getActiveVehicle();
  }

  Future<void> setActiveVehicle(String id) async {
    await _repository.setActiveVehicleId(id);
    state = _repository.getVehicleById(id);
  }

  Future<void> updateOdometer(double newKm) async {
    final current = state;
    if (current == null) return;
    if (newKm >= current.currentKilometer) {
      await _repository.updateOdometer(current.id, newKm);
      state = _repository.getVehicleById(current.id);
    }
  }

  void refresh() {
    state = _repository.getActiveVehicle();
  }
}

final activeVehicleProvider =
    NotifierProvider<ActiveVehicleNotifier, VehicleModel?>(() {
  return ActiveVehicleNotifier();
});

final vehicleListProvider = Provider<List<VehicleModel>>((ref) {
  // Watch active vehicle so when a vehicle is added/updated, the list refreshes
  ref.watch(activeVehicleProvider);
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.getAllVehicles();
});
