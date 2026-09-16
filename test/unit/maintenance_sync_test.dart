import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ridecare/core/database/hive_boxes.dart';
import 'package:ridecare/core/database/hive_registrar.dart';
import 'package:ridecare/features/maintenance/data/models/maintenance_item_model.dart';
import 'package:ridecare/features/maintenance/data/models/service_log_model.dart';
import 'package:ridecare/features/maintenance/data/models/vehicle_maintenance_model.dart';
import 'package:ridecare/features/maintenance/data/repositories/maintenance_repository.dart';
import 'package:ridecare/features/maintenance/domain/maintenance_prediction_service.dart';
import 'package:ridecare/features/maintenance/presentation/controllers/maintenance_status_controller.dart';
import 'package:ridecare/features/maintenance/providers/maintenance_intelligence_providers.dart';
import 'package:ridecare/features/maintenance/providers/maintenance_prediction_providers.dart';
import 'package:ridecare/features/ride_tracking/data/models/gps_point_model.dart';
import 'package:ridecare/features/ride_tracking/data/models/ride_session_model.dart';
import 'package:ridecare/features/vehicle/data/models/vehicle_model.dart';
import 'package:ridecare/features/vehicle/data/repositories/vehicle_repository.dart';
import 'package:ridecare/features/garage/presentation/controllers/active_vehicle_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late VehicleRepository vehicleRepository;
  late MaintenanceRepository maintenanceRepository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ridecare_sync_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(VehicleModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MaintenanceItemModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(ServiceLogModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(RideSessionModelAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(GpsPointModelAdapter());

    await Hive.openBox<VehicleModel>(HiveBoxes.vehicles);
    await Hive.openBox<MaintenanceItemModel>(HiveBoxes.maintenance);
    await Hive.openBox<ServiceLogModel>(HiveBoxes.serviceHistory);
    await Hive.openBox<RideSessionModel>(HiveBoxes.rides);
    await Hive.openBox<dynamic>(HiveBoxes.settings);

    vehicleRepository = VehicleRepository();
    maintenanceRepository = MaintenanceRepository();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  tearDown(() async {
    await HiveRegistrar.settingsBox.clear();
    await HiveRegistrar.vehiclesBox.clear();
    await HiveRegistrar.ridesBox.clear();
    await HiveRegistrar.serviceHistoryBox.clear();
    await HiveRegistrar.maintenanceBox.clear();
  });

  group('Maintenance Single Source of Truth Synchronization Tests', () {
    test('Tab Kesehatan & Dasbor match 100%: Overdue Radiator Coolant at 13.813 KM', () async {
      // 1. Create vehicle "ikan 168" at 13.813 KM
      final vehicle = VehicleModel(
        id: 'ikan-168',
        brand: 'ikan',
        model: '168',
        year: 2025,
        licensePlate: 'B 168 IK',
        currentOdometer: 13813,
        vehicleType: 'motorcycle',
        vehicleCategoryId: 'sport_motorcycle',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await vehicleRepository.createVehicle(vehicle);
      await vehicleRepository.setActiveVehicleId(vehicle.id);

      // 2. Generate maintenance items (lastServiceOdometer = 0)
      final items = await maintenanceRepository.getVehicleMaintenance(
        vehicle.id,
        vehicleType: vehicle.vehicleType,
        vehicleCategoryId: vehicle.vehicleCategoryId,
        currentOdometer: vehicle.currentOdometer,
      );

      expect(items.isNotEmpty, isTrue);

      // Verify Radiator Coolant is in items with 12000 km interval
      final coolantItem = items.firstWhere(
        (it) => it.itemCategory == 'radiator_coolant' || it.maintenanceId.contains('coolant'),
      );
      expect(coolantItem.lastServiceOdometer, equals(0));
      expect(coolantItem.intervalKm, equals(12000));

      // 3. Prediction service calculation
      final predictions = MaintenancePredictionService.predictVehicleMaintenance(
        vehicle: vehicle,
        items: items,
      );

      final coolantPred = predictions.firstWhere(
        (p) => p.category == 'radiator_coolant' || p.componentName.toLowerCase().contains('coolant'),
      );
      expect(coolantPred.status, equals('OVERDUE'));
      expect(coolantPred.currentHealth, equals(0.0));
      expect(coolantPred.remainingKm, equals(0));

      // 4. Test ProviderContainer: maintenanceStatusProvider must yield matching 0% status
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set active vehicle
      await container.read(activeVehicleProvider.notifier).setActiveVehicle(vehicle.id);

      // Read maintenanceStatusProvider
      final maintenanceStatus = await container.read(maintenanceStatusProvider.future);

      final coolantResult = maintenanceStatus.results.firstWhere(
        (r) => r.item.componentType.contains('coolant') || r.item.componentType.contains('radiator'),
      );

      // Crucial: Must be 0% and critical, NOT 100%!
      expect(coolantResult.healthPercentage, equals(0.0));
      expect(coolantResult.fraction, equals(0.0));
      expect(coolantResult.isCritical, isTrue);
      expect(coolantResult.remainingKm, equals(0.0));

      // 5. Test recording service on Radiator Coolant
      await container.read(maintenanceStatusProvider.notifier).recordService(
            componentType: coolantResult.item.componentType,
            serviceKm: 13813.0,
            serviceDate: DateTime.now(),
            cost: 0.0,
            notes: 'Servis radiator coolant selesai',
          );

      // 6. After recording service, verify immediate synchronization
      final updatedStatus = await container.read(maintenanceStatusProvider.future);
      final updatedCoolant = updatedStatus.results.firstWhere(
        (r) => r.item.componentType.contains('coolant') || r.item.componentType.contains('radiator'),
      );

      expect(updatedCoolant.healthPercentage, equals(100.0));
      expect(updatedCoolant.fraction, equals(1.0));
      expect(updatedCoolant.isOptimal, isTrue);
      expect(updatedCoolant.isCritical, isFalse);

      // Check underlying VehicleMaintenanceModel in repo
      final updatedVmList = await maintenanceRepository.getVehicleMaintenance(vehicle.id);
      final updatedCoolantVm = updatedVmList.firstWhere(
        (it) => it.itemCategory == 'radiator_coolant' || it.maintenanceId.contains('coolant'),
      );
      expect(updatedCoolantVm.lastServiceOdometer, equals(13813));
      expect(updatedCoolantVm.healthPercentage, equals(100));
    });
  });
}
