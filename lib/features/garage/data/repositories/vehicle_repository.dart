import 'package:hive/hive.dart';
import '../../../../core/database/hive_registrar.dart';
import '../models/vehicle_model.dart';

class VehicleRepository {
  Box<VehicleModel> get _box => HiveRegistrar.vehiclesBox;
  Box<dynamic> get _settingsBox => HiveRegistrar.settingsBox;

  static const String _activeVehicleKey = 'active_vehicle_id';

  List<VehicleModel> getAllVehicles() {
    return _box.values.toList();
  }

  VehicleModel? getVehicleById(String id) {
    return _box.get(id);
  }

  Future<void> saveVehicle(VehicleModel vehicle) async {
    await _box.put(vehicle.id, vehicle);
    // If no active vehicle is selected yet, make this the active one
    if (getActiveVehicleId() == null) {
      await setActiveVehicleId(vehicle.id);
    }
  }

  Future<void> updateOdometer(String vehicleId, double newKm) async {
    final vehicle = _box.get(vehicleId);
    if (vehicle != null) {
      if (newKm >= vehicle.currentKilometer) {
        vehicle.currentKilometer = newKm;
        await vehicle.save();
      }
    }
  }

  Future<void> deleteVehicle(String id) async {
    await _box.delete(id);
    if (getActiveVehicleId() == id) {
      final remaining = getAllVehicles();
      if (remaining.isNotEmpty) {
        await setActiveVehicleId(remaining.first.id);
      } else {
        await _settingsBox.delete(_activeVehicleKey);
      }
    }
  }

  String? getActiveVehicleId() {
    final id = _settingsBox.get(_activeVehicleKey) as String?;
    if (id != null && _box.containsKey(id)) {
      return id;
    }
    // Fallback to first available vehicle
    if (_box.isNotEmpty) {
      final firstId = _box.values.first.id;
      _settingsBox.put(_activeVehicleKey, firstId);
      return firstId;
    }
    return null;
  }

  Future<void> setActiveVehicleId(String id) async {
    await _settingsBox.put(_activeVehicleKey, id);
  }

  VehicleModel? getActiveVehicle() {
    final activeId = getActiveVehicleId();
    if (activeId == null) return null;
    return getVehicleById(activeId);
  }
}
