import 'package:hive_flutter/hive_flutter.dart';
import 'hive_boxes.dart';
import '../../features/garage/data/models/vehicle_model.dart';
import '../../features/maintenance/data/models/maintenance_item_model.dart';
import '../../features/maintenance/data/models/service_log_model.dart';
import '../../features/ride_tracking/data/models/gps_point_model.dart';
import '../../features/ride_tracking/data/models/ride_session_model.dart';

/// Initializes Hive database and registers TypeAdapters (PRD Section 13)
class HiveRegistrar {
  HiveRegistrar._();

  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Register TypeAdapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(VehicleModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MaintenanceItemModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ServiceLogModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(RideSessionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(GpsPointModelAdapter());
    }

    // Open persistent Hive boxes
    await Hive.openBox<VehicleModel>(HiveBoxes.vehicles);
    await Hive.openBox<MaintenanceItemModel>(HiveBoxes.maintenance);
    await Hive.openBox<ServiceLogModel>(HiveBoxes.serviceHistory);
    await Hive.openBox<RideSessionModel>(HiveBoxes.rides);
    await Hive.openBox<dynamic>(HiveBoxes.settings);

    _isInitialized = true;
  }

  static Box<VehicleModel> get vehiclesBox =>
      Hive.box<VehicleModel>(HiveBoxes.vehicles);

  static Box<MaintenanceItemModel> get maintenanceBox =>
      Hive.box<MaintenanceItemModel>(HiveBoxes.maintenance);

  static Box<ServiceLogModel> get serviceHistoryBox =>
      Hive.box<ServiceLogModel>(HiveBoxes.serviceHistory);

  static Box<RideSessionModel> get ridesBox =>
      Hive.box<RideSessionModel>(HiveBoxes.rides);

  static Box<dynamic> get settingsBox =>
      Hive.box<dynamic>(HiveBoxes.settings);
}
