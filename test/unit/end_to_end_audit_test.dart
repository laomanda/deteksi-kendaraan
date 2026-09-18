import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ridecare/core/database/hive_boxes.dart';
import 'package:ridecare/features/maintenance/data/models/component_model.dart';
import 'package:ridecare/features/maintenance/data/models/maintenance_rule_model.dart';
import 'package:ridecare/features/maintenance/data/models/service_record_model.dart';
import 'package:ridecare/features/maintenance/data/models/vehicle_maintenance_model.dart';
import 'package:ridecare/features/maintenance/domain/maintenance_calculator.dart';
import 'package:ridecare/features/vehicle/data/models/vehicle_model.dart';
import 'package:ridecare/features/vehicle/domain/vehicle_intelligence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<VehicleModel> vehicleBox;
  late Box<dynamic> settingsBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ridecare_e2e_audit_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(VehicleModelAdapter());
    }

    vehicleBox = await Hive.openBox<VehicleModel>(HiveBoxes.vehicles);
    settingsBox = await Hive.openBox<dynamic>(HiveBoxes.settings);
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

  // ==============================================================
  // 1. VEHICLE CATEGORY MAPPING TEST
  // ==============================================================
  group('1. Vehicle Category Mapping Tests', () {
    test('Honda Vario 160 ABS maps to scooter_cvt', () {
      final vario = VehicleModel(
        id: 'v-vario160',
        brand: 'Honda',
        model: 'Vario 160 ABS',
        vehicleType: 'motorcycle',
        year: 2023,
        currentOdometer: 119371,
      );
      final category = VehicleIntelligenceService.resolveCategoryId(vario);
      expect(category, equals('scooter_cvt'));
    });

    test('Honda CB150R maps to motorcycle_manual / sport_motorcycle', () {
      final cbExplicit = VehicleModel(
        id: 'v-cb150r-explicit',
        brand: 'Honda',
        model: 'CB150R',
        vehicleType: 'motorcycle',
        year: 2021,
        vehicleCategoryId: 'motorcycle_manual',
        currentOdometer: 138914,
      );
      expect(
        VehicleIntelligenceService.resolveCategoryId(cbExplicit),
        equals('motorcycle_manual'),
      );

      final cbInferred = VehicleModel(
        id: 'v-cb150r-inferred',
        brand: 'Honda',
        model: 'CB150R',
        vehicleType: 'motorcycle',
        year: 2021,
        currentOdometer: 138914,
      );
      expect(
        VehicleIntelligenceService.resolveCategoryId(cbInferred),
        equals('sport_motorcycle'),
      );
    });

    test('Car category mapping: Automatic, Diesel, Hybrid', () {
      expect(
        VehicleIntelligenceService.inferCategory(
          vehicleType: 'car',
          brand: 'Toyota',
          model: 'Avanza 1.5 G CVT',
          transmission: 'Automatic',
        ),
        equals('car_automatic'),
      );

      expect(
        VehicleIntelligenceService.inferCategory(
          vehicleType: 'car',
          brand: 'Toyota',
          model: 'Fortuner 2.8 VRZ 4x2',
          fuelType: 'Diesel',
        ),
        equals('car_diesel'),
      );

      expect(
        VehicleIntelligenceService.inferCategory(
          vehicleType: 'car',
          brand: 'Toyota',
          model: 'Innova Zenix Q HEV',
          fuelType: 'Hybrid',
        ),
        equals('car_hybrid'),
      );
    });
  });

  // ==============================================================
  // 2. MAINTENANCE GENERATION TEST
  // ==============================================================
  group('2. Maintenance Generation Tests', () {
    test('Vehicle 1: Honda Vario 160 ABS (scooter_cvt) gets CVT components and no manual transmission parts', () {
      final vario = VehicleModel(
        id: 'v-vario',
        brand: 'Honda',
        model: 'Vario 160 ABS',
        vehicleType: 'motorcycle',
        year: 2023,
        vehicleCategoryId: 'scooter_cvt',
        currentOdometer: 119371,
      );

      final items = VehicleIntelligenceService.generateMaintenanceItems(vehicle: vario);
      final keys = items.map((i) => i.itemCategory ?? '').toList();

      // Required CVT components
      expect(keys, contains('engine_oil'));
      expect(keys, contains('cvt_belt'));
      expect(keys, contains('cvt_roller'));
      expect(keys, contains('gear_oil'));

      // Strictly prohibited manual components
      expect(keys, isNot(contains('drive_chain')));
      expect(keys, isNot(contains('clutch_plate')));
      expect(keys, isNot(contains('sprocket')));

      final violations = VehicleIntelligenceService.validateNoIncompatibleComponents(
        categoryId: 'scooter_cvt',
        itemKeys: keys,
      );
      expect(violations, isEmpty);
    });

    test('Vehicle 2: Honda CB150R (motorcycle_manual) gets manual components and no CVT parts', () {
      final cb = VehicleModel(
        id: 'v-cb150r',
        brand: 'Honda',
        model: 'CB150R',
        vehicleType: 'motorcycle',
        year: 2021,
        vehicleCategoryId: 'motorcycle_manual',
        currentOdometer: 138914,
      );

      final items = VehicleIntelligenceService.generateMaintenanceItems(vehicle: cb);
      final keys = items.map((i) => i.itemCategory ?? '').toList();

      // Required motorcycle manual components
      expect(keys, contains('engine_oil'));
      expect(keys, contains('spark_plug'));
      expect(keys, contains('brake_pad'));
      expect(keys, contains('air_filter'));
      expect(keys, contains('sprocket'));
      expect(keys, contains('drive_chain'));
      expect(keys, contains('clutch_plate'));
      expect(keys, contains('battery'));

      // Strictly prohibited CVT components
      expect(keys, isNot(contains('cvt_belt')));
      expect(keys, isNot(contains('cvt_roller')));
      expect(keys, isNot(contains('gear_oil')));

      final violations = VehicleIntelligenceService.validateNoIncompatibleComponents(
        categoryId: 'motorcycle_manual',
        itemKeys: keys,
      );
      expect(violations, isEmpty);
    });
  });

  // ==============================================================
  // 3. INITIAL CONDITION SETUP TEST
  // ==============================================================
  group('3. Initial Condition Setup Tests', () {
    final cb150 = VehicleModel(
      id: 'v-cb150-test',
      brand: 'Honda',
      model: 'CB150R',
      vehicleType: 'motorcycle',
      year: 2021,
      vehicleCategoryId: 'motorcycle_manual',
      currentOdometer: 138914,
    );

    test('Option A: Prediksi Otomatis — CB150R Oli Mesin 3000 interval -> Next 141914, Remaining 3000, Status GOOD', () {
      final items = VehicleIntelligenceService.generateMaintenanceItems(
        vehicle: cb150,
        initialCondition: VehicleInitialCondition.autoPrediction,
      );

      final oilItem = items.firstWhere((it) => it.itemCategory == 'engine_oil');
      final calc = MaintenanceCalculator.calculate(
        currentOdometer: cb150.currentOdometer,
        intervalKm: oilItem.effectiveIntervalKm,
        lastServiceOdometer: oilItem.lastServiceOdometer,
        hasMaintenanceHistory: oilItem.hasServiceHistory,
      );

      expect(calc.nextServiceKm, equals(141914));
      expect(calc.remainingKm, equals(3000));
      expect(calc.healthPercentage, equals(100));
      expect(calc.status, equals('GOOD'));
      expect(calc.isGood, isTrue);
      expect(calc.isOverdue, isFalse);
    });

    test('Option B: Input Riwayat Servis — Last service at 130000 KM calculates from 130000 NOT current_odometer', () {
      final items = VehicleIntelligenceService.generateMaintenanceItems(
        vehicle: cb150,
        initialCondition: VehicleInitialCondition.serviceHistory,
        lastServiceOdometer: 130000,
        lastServiceDate: DateTime(2025, 12, 1),
      );

      final oilItem = items.firstWhere((it) => it.itemCategory == 'engine_oil');
      expect(oilItem.lastServiceOdometer, equals(130000));
      expect(oilItem.hasServiceHistory, isTrue);

      final calc = MaintenanceCalculator.calculate(
        currentOdometer: cb150.currentOdometer, // 138914
        intervalKm: 3000,
        lastServiceOdometer: 130000,
        hasMaintenanceHistory: true,
      );

      // nextService = 130000 + 3000 = 133000
      expect(calc.nextServiceKm, equals(133000));
      // remaining = 133000 - 138914 = -5914
      expect(calc.remainingKm, equals(-5914));
      expect(calc.status, equals('OVERDUE'));
      expect(calc.isOverdue, isTrue);
    });

    test('Option C: Semua Komponen Kondisi Baik — health 100%, status GOOD, baseline = current_odometer', () {
      final items = VehicleIntelligenceService.generateMaintenanceItems(
        vehicle: cb150,
        initialCondition: VehicleInitialCondition.allGood,
      );

      for (final item in items) {
        expect(item.healthPercentage, equals(100));
        expect(item.status, equals('GOOD'));
        expect(item.lastServiceOdometer, equals(138914));

        final calc = MaintenanceCalculator.calculate(
          currentOdometer: cb150.currentOdometer,
          intervalKm: item.effectiveIntervalKm,
          lastServiceOdometer: item.lastServiceOdometer,
          hasMaintenanceHistory: item.hasServiceHistory,
        );

        expect(calc.status, equals('GOOD'));
        expect(calc.healthPercentage, equals(100));
        expect(calc.isOverdue, isFalse);
      }
    });
  });

  // ==============================================================
  // 4. OFFLINE REPOSITORY TEST
  // ==============================================================
  group('4. Offline Repository Tests', () {
    test('Hive local storage persists vehicle and retrieves correctly without network', () async {
      final vehicle = VehicleModel(
        id: 'v-offline-1',
        brand: 'Honda',
        model: 'Vario 160 ABS',
        vehicleType: 'motorcycle',
        year: 2023,
        currentOdometer: 119371,
        vehicleCategoryId: 'scooter_cvt',
        initialCondition: 'auto_prediction',
      );

      await vehicleBox.put(vehicle.id, vehicle);

      final retrieved = vehicleBox.get('v-offline-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.brand, equals('Honda'));
      expect(retrieved.currentOdometer, equals(119371));
      expect(retrieved.vehicleCategoryId, equals('scooter_cvt'));
    });

    test('Offline service records cache updates and loads properly', () async {
      final record = ServiceRecordModel(
        id: 'rec-offline-1',
        vehicleId: 'v-offline-1',
        serviceDate: DateTime(2026, 9, 18),
        odometer: 119500,
        cost: 65000.0,
        maintenanceName: 'Oli Mesin Matic',
      );

      final key = 'service_records_${record.vehicleId}';
      await settingsBox.put(key, [record.toLocalJson()]);

      final cached = settingsBox.get(key) as List;
      expect(cached.length, equals(1));
      final parsed = ServiceRecordModel.fromJson(Map<String, dynamic>.from(cached.first as Map));
      expect(parsed.odometer, equals(119500));
      expect(parsed.maintenanceName, equals('Oli Mesin Matic'));
    });
  });

  // ==============================================================
  // 5. SUPABASE MAPPING TEST
  // ==============================================================
  group('5. Supabase Mapping & Schema Parity Tests', () {
    test('VehicleModel.toJson() conforms to Supabase vehicles table and excludes local-only columns', () {
      final vehicle = VehicleModel(
        id: 'v-supabase-1',
        profileId: 'usr-123',
        brand: 'Honda',
        model: 'CB150R',
        variant: 'StreetFire',
        vehicleType: 'motorcycle',
        year: 2021,
        licensePlate: 'B 1234 ABC',
        engineCc: 150,
        initialOdometer: 138000,
        currentOdometer: 138914,
        photoUrl: 'https://example.com/photo.jpg',
        vehicleCategoryId: 'motorcycle_manual',
        initialCondition: 'autoPrediction',
        fuelType: 'Gasoline',
        transmission: 'Manual',
      );

      final json = vehicle.toJson();

      // Required Supabase 'vehicles' table columns
      expect(json['id'], equals('v-supabase-1'));
      expect(json['profile_id'], equals('usr-123'));
      expect(json['brand'], equals('Honda'));
      expect(json['model'], equals('CB150R'));
      expect(json['variant'], equals('StreetFire'));
      expect(json['vehicle_type'], equals('motorcycle'));
      expect(json['year'], equals(2021));
      expect(json['license_plate'], equals('B 1234 ABC'));
      expect(json['engine_cc'], equals(150));
      expect(json['initial_odometer'], equals(138000));
      expect(json['current_odometer'], equals(138914));
      expect(json['photo_url'], equals('https://example.com/photo.jpg'));
      expect(json['vehicle_category_id'], equals('motorcycle_manual'));

      // MUST NOT contain non-existent columns in vehicles table
      expect(json.containsKey('initial_condition'), isFalse);
      expect(json.containsKey('fuel_type'), isFalse);
      expect(json.containsKey('transmission'), isFalse);

      // Embedded specs table mapping
      final specsJson = vehicle.toSpecsJson();
      expect(specsJson['vehicle_id'], equals('v-supabase-1'));
      expect(specsJson['fuel_type'], equals('Gasoline'));
      expect(specsJson['transmission'], equals('Manual'));
    });

    test('MaintenanceRuleModel & ComponentModel serialization and equality', () {
      const component = ComponentModel(
        id: 'comp-1',
        name: 'Oli Mesin',
        category: 'engine_oil',
        description: 'Pelumasan mesin utama',
      );

      const rule = MaintenanceRuleModel(
        id: 'rule-1',
        profileId: 'motorcycle_manual',
        componentId: 'comp-1',
        description: 'Ganti oli setiap 3000 KM',
        intervalKm: 3000,
        priority: 'high',
        component: component,
      );

      final json = rule.toJson();
      expect(json['profile_id'], equals('motorcycle_manual'));
      expect(json['interval_km'], equals(3000));

      final deserialized = MaintenanceRuleModel.fromJson(json);
      expect(deserialized.id, equals('rule-1'));
      expect(deserialized.intervalKm, equals(3000));
      expect(deserialized.component?.name, equals('Oli Mesin'));
      expect(deserialized == rule, isTrue);
    });

    test('VehicleMaintenanceModel serialization with nested rules', () {
      const vm = VehicleMaintenanceModel(
        id: 'vm-1',
        vehicleId: 'v-1',
        maintenanceId: 'm-1',
        lastServiceOdometer: 138000,
        healthPercentage: 100,
        status: 'GOOD',
        itemName: 'Oli Mesin Manual',
        intervalKm: 3000,
      );

      final json = vm.toJson();
      expect(json['vehicle_id'], equals('v-1'));
      expect(json['last_service_odometer'], equals(138000));
      expect(json['health_percentage'], equals(100));
      expect(json['status'], equals('GOOD'));

      final parsed = VehicleMaintenanceModel.fromJson(json);
      expect(parsed.id, equals('vm-1'));
      expect(parsed.isGood, isTrue);
    });
  });
}
