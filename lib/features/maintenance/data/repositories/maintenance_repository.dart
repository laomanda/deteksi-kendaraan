import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/hive_registrar.dart';
import '../models/maintenance_item_model.dart';
import '../models/service_log_model.dart';

class MaintenanceRepository {
  Box<MaintenanceItemModel> get _box => HiveRegistrar.maintenanceBox;
  Box<ServiceLogModel> get _historyBox => HiveRegistrar.serviceHistoryBox;

  List<MaintenanceItemModel> getItemsForVehicle(String vehicleId) {
    return _box.values
        .where((item) => item.vehicleId == vehicleId)
        .toList();
  }

  Future<void> saveItems(List<MaintenanceItemModel> items) async {
    final map = <String, MaintenanceItemModel>{
      for (final item in items) item.id: item,
    };
    await _box.putAll(map);
  }

  Future<void> updateItem(MaintenanceItemModel item) async {
    await _box.put(item.id, item);
  }

  Future<void> deleteItemsForVehicle(String vehicleId) async {
    final keysToDelete = _box.values
        .where((item) => item.vehicleId == vehicleId)
        .map((item) => item.id)
        .toList();
    await _box.deleteAll(keysToDelete);

    final historyKeysToDelete = _historyBox.values
        .where((log) => log.vehicleId == vehicleId)
        .map((log) => log.id)
        .toList();
    await _historyBox.deleteAll(historyKeysToDelete);
  }

  List<ServiceLogModel> getServiceHistoryForVehicle(String vehicleId) {
    final logs = _historyBox.values
        .where((log) => log.vehicleId == vehicleId)
        .toList();
    // Sort descending by date
    logs.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    return logs;
  }

  Future<ServiceLogModel> recordService({
    required String vehicleId,
    required String componentType,
    required double serviceKm,
    required DateTime serviceDate,
    required double cost,
    required String notes,
  }) async {
    const uuid = Uuid();
    final log = ServiceLogModel(
      id: uuid.v4(),
      vehicleId: vehicleId,
      componentType: componentType,
      serviceKm: serviceKm,
      serviceDate: serviceDate,
      cost: cost,
      notes: notes,
    );

    // Save log entry
    await _historyBox.put(log.id, log);

    // Update maintenance item
    final items = getItemsForVehicle(vehicleId);
    final target = items.where((it) => it.componentType == componentType);
    if (target.isNotEmpty) {
      final item = target.first;
      item.lastServiceKm = serviceKm;
      item.lastServiceDate = serviceDate;
      await item.save();
    }

    return log;
  }
}
