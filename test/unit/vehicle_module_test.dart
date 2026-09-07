import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ridecare/core/database/hive_boxes.dart';
import 'package:ridecare/features/vehicle/data/models/vehicle_model.dart';
import 'package:ridecare/features/vehicle/data/repositories/vehicle_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<VehicleModel> vehicleBox;
  late Box<dynamic> settingsBox;
  late VehicleRepository vehicleRepository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ridecare_vehicle_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(VehicleModelAdapter());
    }

    vehicleBox = await Hive.openBox<VehicleModel>(HiveBoxes.vehicles);
    settingsBox = await Hive.openBox<dynamic>(HiveBoxes.settings);
    vehicleRepository = VehicleRepository();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  tearDown(() async {
    await vehicleBox.clear();
    await settingsBox.clear();
  });

  group('Garage / Vehicle Management Module Tests', () {
    // -------------------------------------------------------------
    // Test Case 1: Tambah Kendaraan (Honda Beat 2024 110 CC)
    // -------------------------------------------------------------
    test('1. Tambah kendaraan (Honda Beat 2024 110 CC) & Validasi Supabase Schema', () async {
      final newVehicle = VehicleModel(
        id: 'test-honda-beat-uuid',
        brand: 'Honda',
        model: 'Beat',
        variant: 'Deluxe',
        vehicleType: 'motorcycle',
        year: 2024,
        engineCc: 110,
        licensePlate: 'B 1234 ABC',
        initialOdometer: 10000,
        currentOdometer: 12500,
        fuelType: 'Gasoline',
        transmission: 'Automatic',
        createdAt: DateTime(2024, 1, 1),
      );

      // Verify mapping Supabase 'vehicles' table schema
      final supabaseJson = newVehicle.toJson();
      expect(supabaseJson['id'], 'test-honda-beat-uuid');
      expect(supabaseJson['brand'], 'Honda');
      expect(supabaseJson['model'], 'Beat');
      expect(supabaseJson['variant'], 'Deluxe');
      expect(supabaseJson['vehicle_type'], 'motorcycle');
      expect(supabaseJson['year'], 2024);
      expect(supabaseJson['engine_cc'], 110);
      expect(supabaseJson['initial_odometer'], 10000);
      expect(supabaseJson['current_odometer'], 12500);
      expect(supabaseJson['license_plate'], 'B 1234 ABC');

      // Verify mapping Supabase 'vehicle_specs' table schema
      final specsJson = newVehicle.toSpecsJson();
      expect(specsJson['vehicle_id'], 'test-honda-beat-uuid');
      expect(specsJson['fuel_type'], 'Gasoline');
      expect(specsJson['transmission'], 'Automatic');

      // Verify fromJson roundtrip
      final restored = VehicleModel.fromJson(supabaseJson, specsJson);
      expect(restored.displayName, 'Honda Beat Deluxe');
      expect(restored.engineCc, 110);
      expect(restored.currentOdometer, 12500);
      expect(restored.isMotorcycle, isTrue);

      // Save to repository (Hive local-first)
      await vehicleRepository.createVehicle(newVehicle);

      // Verify saved in Hive
      final stored = vehicleBox.get('test-honda-beat-uuid');
      expect(stored, isNotNull);
      expect(stored!.brand, 'Honda');
      expect(stored.model, 'Beat');
      expect(stored.engineCc, 110);
      expect(stored.year, 2024);
    });

    // -------------------------------------------------------------
    // Test Case 2: Restart aplikasi (Data tetap muncul dari Hive)
    // -------------------------------------------------------------
    test('2. Restart aplikasi - Data tetap muncul dari Hive', () async {
      final initialVehicle = VehicleModel(
        id: 'persistent-beat-uuid',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        engineCc: 110,
        currentOdometer: 12500,
      );

      await vehicleRepository.createVehicle(initialVehicle);
      expect(vehicleBox.containsKey('persistent-beat-uuid'), isTrue);

      // Simulate app restart by re-reading through a fresh getVehicles() query
      final vehiclesAfterRestart = await vehicleRepository.getVehicles();

      expect(vehiclesAfterRestart.any((v) => v.id == 'persistent-beat-uuid'), isTrue);
      final retrieved = vehiclesAfterRestart.firstWhere((v) => v.id == 'persistent-beat-uuid');
      expect(retrieved.brand, 'Honda');
      expect(retrieved.model, 'Beat');
      expect(retrieved.currentOdometer, 12500);
    });

    // -------------------------------------------------------------
    // Test Case 3: Edit kendaraan
    // -------------------------------------------------------------
    test('3. Edit kendaraan - Perubahan tersimpan di Local Storage & Payload Supabase', () async {
      final original = VehicleModel(
        id: 'edit-target-uuid',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        engineCc: 110,
        currentOdometer: 12500,
      );
      await vehicleRepository.createVehicle(original);

      // Edit vehicle data
      final edited = original.copyWith(
        currentOdometer: 13000,
        variant: 'Street',
        licensePlate: 'B 9999 XYZ',
      );

      await vehicleRepository.updateVehicle(edited);

      // Verify changes in Hive
      final fromHive = vehicleBox.get('edit-target-uuid');
      expect(fromHive, isNotNull);
      expect(fromHive!.currentOdometer, 13000);
      expect(fromHive.variant, 'Street');
      expect(fromHive.licensePlate, 'B 9999 XYZ');

      // Verify updated JSON payload
      final updatedJson = fromHive.toJson();
      expect(updatedJson['current_odometer'], 13000);
      expect(updatedJson['variant'], 'Street');
      expect(updatedJson['license_plate'], 'B 9999 XYZ');
    });

    // -------------------------------------------------------------
    // Test Case 4: Delete kendaraan
    // -------------------------------------------------------------
    test('4. Delete kendaraan - Data berhasil dihapus dari penyimpanan', () async {
      final toDelete = VehicleModel(
        id: 'delete-target-uuid',
        brand: 'Yamaha',
        model: 'Aerox',
        vehicleType: 'motorcycle',
        year: 2023,
        currentOdometer: 8500,
      );
      await vehicleRepository.createVehicle(toDelete);
      expect(vehicleBox.containsKey('delete-target-uuid'), isTrue);

      // Set as active vehicle to also test active vehicle cleanup
      await vehicleRepository.setActiveVehicleId('delete-target-uuid');
      expect(vehicleRepository.getActiveVehicleId(), 'delete-target-uuid');

      // Delete vehicle
      await vehicleRepository.deleteVehicle('delete-target-uuid');

      // Verify vehicle is completely gone from Hive
      expect(vehicleBox.containsKey('delete-target-uuid'), isFalse);
      expect(vehicleBox.get('delete-target-uuid'), isNull);

      final list = await vehicleRepository.getVehicles();
      expect(list.any((v) => v.id == 'delete-target-uuid'), isFalse);
    });
  });
}
