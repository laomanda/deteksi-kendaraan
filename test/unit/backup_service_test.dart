import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ridecare/core/database/hive_boxes.dart';
import 'package:ridecare/core/database/hive_registrar.dart';
import 'package:ridecare/features/maintenance/data/models/maintenance_item_model.dart';
import 'package:ridecare/features/maintenance/data/models/service_log_model.dart';
import 'package:ridecare/features/ride_tracking/data/models/gps_point_model.dart';
import 'package:ridecare/features/ride_tracking/data/models/ride_session_model.dart';
import 'package:ridecare/features/vehicle/data/models/vehicle_model.dart';
import 'package:ridecare/shared/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ridecare_backup_test_');
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
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await HiveRegistrar.settingsBox.clear();
    await HiveRegistrar.vehiclesBox.clear();
    await HiveRegistrar.ridesBox.clear();
    await HiveRegistrar.serviceHistoryBox.clear();
    await HiveRegistrar.maintenanceBox.clear();
  });

  group('BackupService Import and Export Unit Tests', () {
    test('importDatabase successfully imports vehicles, maintenance, service logs, and rides', () async {
      final sampleBackup = {
        'app': 'RideCare',
        'version': '1.0.0-PROD',
        'exportedAt': DateTime.now().toIso8601String(),
        'vehicles': [
          {
            'id': 'veh_test_1',
            'brand': 'Honda',
            'model': 'Vario 160',
            'vehicle_type': 'motorcycle',
            'license_plate': 'B 1234 ABC',
            'current_odometer': 15000,
            'initial_odometer': 0,
            'year': 2023,
            'engine_cc': 160,
            'created_at': DateTime.now().toIso8601String(),
          }
        ],
        'maintenance': [],
        'service_history': [
          {
            'id': 'srv_test_1',
            'vehicleId': 'veh_test_1',
            'serviceDate': DateTime.now().toIso8601String(),
            'odometerAtService': 14500,
            'replacedComponents': ['Oli Mesin'],
            'serviceType': 'Ganti Oli',
            'createdAt': DateTime.now().toIso8601String(),
          }
        ],
        'rides': [
          {
            'id': 'ride_test_1',
            'vehicleId': 'veh_test_1',
            'startTime': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
            'endTime': DateTime.now().toIso8601String(),
            'distanceKm': 12.5,
            'avgSpeedKmh': 35.0,
            'maxSpeedKmh': 60.0,
            'path': [],
          }
        ],
        'vehicle_maintenance': {
          'vehicle_maintenance_veh_test_1': [
            {
              'id': 'item_oli',
              'name': 'Oli Mesin',
              'currentLifeKm': 1500,
              'maxLifeKm': 2000,
              'lastServiceOdometer': 14500,
              'lastServiceDate': DateTime.now().toIso8601String(),
            }
          ]
        }
      };

      final jsonString = jsonEncode(sampleBackup);
      final result = await BackupService.importDatabase(jsonString);

      expect(result.success, isTrue);
      expect(result.vehiclesCount, equals(1));
      expect(result.servicesCount, equals(1));
      expect(result.ridesCount, equals(1));

      // Verify Hive state
      expect(HiveRegistrar.vehiclesBox.containsKey('veh_test_1'), isTrue);
      final vehicle = HiveRegistrar.vehiclesBox.get('veh_test_1');
      expect(vehicle?.brand, equals('Honda'));
      expect(vehicle?.model, equals('Vario 160'));
      expect(vehicle?.displayName, equals('Honda Vario 160'));
      expect(vehicle?.currentOdometer, equals(15000));

      expect(HiveRegistrar.serviceHistoryBox.containsKey('srv_test_1'), isTrue);
      expect(HiveRegistrar.ridesBox.containsKey('ride_test_1'), isTrue);

      // Verify active vehicle was automatically set
      expect(HiveRegistrar.settingsBox.get('active_vehicle_id'), equals('veh_test_1'));

      // Verify cache restored
      final cachedMaintenance = HiveRegistrar.settingsBox.get('vehicle_maintenance_veh_test_1');
      expect(cachedMaintenance, isNotNull);
    });

    test('importDatabase returns failure for invalid JSON structure', () async {
      const invalidJson = '{"foo": "bar"}';
      final result = await BackupService.importDatabase(invalidJson);

      expect(result.success, isFalse);
      expect(result.vehiclesCount, equals(0));
    });

    test('importDatabase returns failure for non-JSON content', () async {
      const corruptData = 'THIS_IS_NOT_JSON';
      final result = await BackupService.importDatabase(corruptData);

      expect(result.success, isFalse);
    });

    test('factoryReset clears all boxes', () async {
      final sampleVehicle = VehicleModel(
        id: 'veh_reset_1',
        brand: 'Yamaha',
        model: 'NMAX',
        vehicleType: 'motorcycle',
        year: 2022,
        currentOdometer: 20000,
        createdAt: DateTime.now(),
      );

      await HiveRegistrar.vehiclesBox.put(sampleVehicle.id, sampleVehicle);
      await HiveRegistrar.settingsBox.put('active_vehicle_id', sampleVehicle.id);
      expect(HiveRegistrar.vehiclesBox.isNotEmpty, isTrue);

      await BackupService.factoryReset();

      expect(HiveRegistrar.vehiclesBox.isEmpty, isTrue);
      expect(HiveRegistrar.settingsBox.isEmpty, isTrue);
    });
  });
}
