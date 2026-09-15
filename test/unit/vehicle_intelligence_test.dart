import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ridecare/core/constants/component_catalog.dart';
import 'package:ridecare/core/database/hive_boxes.dart';
import 'package:ridecare/features/maintenance/data/models/maintenance_template_model.dart';
import 'package:ridecare/features/maintenance/data/repositories/maintenance_repository.dart';
import 'package:ridecare/features/vehicle/data/models/vehicle_category_model.dart';
import 'package:ridecare/features/vehicle/data/models/vehicle_model.dart';
import 'package:ridecare/features/vehicle/data/repositories/vehicle_repository.dart';
import 'package:ridecare/features/vehicle/domain/vehicle_intelligence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<VehicleModel> vehicleBox;
  late Box<dynamic> settingsBox;
  late VehicleRepository vehicleRepository;
  late MaintenanceRepository maintenanceRepository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ridecare_intelligence_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(VehicleModelAdapter());
    }

    vehicleBox = await Hive.openBox<VehicleModel>(HiveBoxes.vehicles);
    await Hive.openBox<dynamic>(HiveBoxes.maintenance);
    settingsBox = await Hive.openBox<dynamic>(HiveBoxes.settings);

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
    await vehicleBox.clear();
    await settingsBox.clear();
  });

  group('Vehicle Intelligence Layer - Domain & Filtering Tests', () {
    // -------------------------------------------------------------
    // Scenario 1: Vario 160 (Motor Matic CVT)
    // -------------------------------------------------------------
    test('Scenario 1: Vario 160 (scooter_cvt) - Mendapat CVT & Oli Gardan, TANPA Rantai & Kopling Manual', () {
      const categoryId = 'scooter_cvt';
      final templates = VehicleIntelligenceService.getTemplatesForVehicle(categoryId);
      final itemKeys = templates.map((t) => t.itemKey).toList();

      // Harap ada komponen CVT Matic
      expect(itemKeys, contains('engine_oil'));
      expect(itemKeys, contains('cvt_belt'));
      expect(itemKeys, contains('cvt_roller'));
      expect(itemKeys, contains('gear_oil'));

      // HARUS DITOLAK: Komponen motor manual / rantai
      expect(itemKeys, isNot(contains('drive_chain')));
      expect(itemKeys, isNot(contains('clutch_plate')));

      // Validasi incompatibilitas otomatis
      final violations = VehicleIntelligenceService.validateNoIncompatibleComponents(
        categoryId: categoryId,
        itemKeys: itemKeys,
      );
      expect(violations, isEmpty, reason: 'Tidak boleh ada komponen motor manual pada motor matic CVT');

      // Validasi ComponentCatalog untuk input kondisi awal
      final catalog = ComponentCatalog.getCatalogForCategory(categoryId, vehicleType: 'motorcycle');
      final catalogKeys = catalog.map((c) => c.key).toList();
      expect(catalogKeys, contains('cvt_belt'));
      expect(catalogKeys, contains('gear_oil'));
      expect(catalogKeys, isNot(contains('drive_chain')));
      expect(catalogKeys, isNot(contains('clutch_plate')));
    });

    // -------------------------------------------------------------
    // Scenario 2: CB150R (Motor Manual / Sport)
    // -------------------------------------------------------------
    test('Scenario 2: CB150R (motorcycle_manual / sport_motorcycle) - Mendapat Rantai & Kopling, TANPA CVT', () {
      const categoryId = 'sport_motorcycle';
      final templates = VehicleIntelligenceService.getTemplatesForVehicle(categoryId);
      final itemKeys = templates.map((t) => t.itemKey).toList();

      // Harap ada komponen manual / kopling
      expect(itemKeys, contains('engine_oil'));
      expect(itemKeys, contains('drive_chain'));
      expect(itemKeys, contains('clutch_plate'));
      expect(itemKeys, contains('radiator_coolant'));

      // HARUS DITOLAK: Komponen CVT Matic
      expect(itemKeys, isNot(contains('cvt_belt')));
      expect(itemKeys, isNot(contains('cvt_roller')));
      expect(itemKeys, isNot(contains('gear_oil')));

      // Validasi incompatibilitas otomatis
      final violations = VehicleIntelligenceService.validateNoIncompatibleComponents(
        categoryId: categoryId,
        itemKeys: itemKeys,
      );
      expect(violations, isEmpty, reason: 'Tidak boleh ada komponen matic CVT pada motor sport manual');

      // Validasi ComponentCatalog
      final catalog = ComponentCatalog.getCatalogForCategory(categoryId, vehicleType: 'motorcycle');
      final catalogKeys = catalog.map((c) => c.key).toList();
      expect(catalogKeys, contains('drive_chain'));
      expect(catalogKeys, contains('clutch_plate'));
      expect(catalogKeys, isNot(contains('cvt_belt')));
      expect(catalogKeys, isNot(contains('gear_oil')));
    });

    // -------------------------------------------------------------
    // Scenario 3: Avanza AT (Mobil Matic)
    // -------------------------------------------------------------
    test('Scenario 3: Avanza AT (car_automatic) - Mendapat ATF/CVTF, TANPA Kopling Manual & Komponen Motor', () {
      const categoryId = 'car_automatic';
      final templates = VehicleIntelligenceService.getTemplatesForVehicle(categoryId);
      final itemKeys = templates.map((t) => t.itemKey).toList();

      // Harap ada komponen mobil matic
      expect(itemKeys, contains('engine_oil'));
      expect(itemKeys, contains('at_fluid'));
      expect(itemKeys, contains('oil_filter'));
      expect(itemKeys, contains('brake_pad'));

      // HARUS DITOLAK: Kampas kopling manual & transmisi manual
      expect(itemKeys, isNot(contains('clutch_plate')));
      expect(itemKeys, isNot(contains('mt_fluid')));
      // HARUS DITOLAK: Komponen motor
      expect(itemKeys, isNot(contains('drive_chain')));
      expect(itemKeys, isNot(contains('cvt_roller')));

      // Validasi incompatibilitas otomatis
      final violations = VehicleIntelligenceService.validateNoIncompatibleComponents(
        categoryId: categoryId,
        itemKeys: itemKeys,
      );
      expect(violations, isEmpty, reason: 'Mobil matic tidak boleh mendapatkan kampas kopling manual');

      // Validasi ComponentCatalog mobil matic
      final catalog = ComponentCatalog.getCatalogForCategory(categoryId, vehicleType: 'car');
      final catalogKeys = catalog.map((c) => c.key).toList();
      expect(catalogKeys, contains('at_fluid'));
      expect(catalogKeys, isNot(contains('clutch_plate')));
      expect(catalogKeys, isNot(contains('mt_fluid')));
    });

    // -------------------------------------------------------------
    // Scenario 4: Legacy Vehicle Heuristic Fallback
    // -------------------------------------------------------------
    test('Scenario 4: Kendaraan Legacy (tanpa vehicleCategoryId) - Fallback berhasil tanpa crash', () {
      // Motor matic lama yang belum punya vehicleCategoryId
      final legacyVario = VehicleModel(
        id: 'legacy-vario-id',
        brand: 'Honda',
        model: 'Vario 160',
        vehicleType: 'motorcycle',
        transmission: 'Automatic',
        fuelType: 'Gasoline',
        currentOdometer: 10000,
        year: 2023,
      );

      // Category harus terdeteksi sebagai scooter_cvt via heuristic
      final detectedCategory = VehicleIntelligenceService.resolveCategoryId(legacyVario);
      expect(detectedCategory, 'scooter_cvt');

      // Generate items untuk kendaraan legacy
      final items = VehicleIntelligenceService.generateMaintenanceItems(
        vehicle: legacyVario,
        categoryId: detectedCategory,
      );

      expect(items.isNotEmpty, isTrue);
      final itemKeys = items.map((i) => i.itemKey).toList();
      expect(itemKeys, contains('cvt_belt'));
      expect(itemKeys, contains('cvt_roller'));
      expect(itemKeys, isNot(contains('drive_chain')));

      // Mobil manual lama
      final legacyAvanzaManual = VehicleModel(
        id: 'legacy-avanza-manual',
        brand: 'Toyota',
        model: 'Avanza G',
        vehicleType: 'car',
        transmission: 'Manual',
        fuelType: 'Gasoline',
        currentOdometer: 45000,
        year: 2021,
      );

      final carCategory = VehicleIntelligenceService.resolveCategoryId(legacyAvanzaManual);
      expect(carCategory, 'car_manual');

      final carItems = VehicleIntelligenceService.generateMaintenanceItems(
        vehicle: legacyAvanzaManual,
        categoryId: carCategory,
      );
      final carItemKeys = carItems.map((i) => i.itemKey).toList();
      expect(carItemKeys, contains('clutch_plate'));
      expect(carItemKeys, contains('mt_fluid'));
      expect(carItemKeys, isNot(contains('at_fluid')));
    });

    // -------------------------------------------------------------
    // Scenario 5: Offline-First & Isolasi Kategori
    // -------------------------------------------------------------
    test('Scenario 5: Offline-first & Template Isolation antar kategori', () async {
      // Verify static defaults exist without any database connection
      final categories = VehicleCategoryModel.defaultCategories;
      expect(categories.length, greaterThanOrEqualTo(7));

      final allTemplates = MaintenanceTemplateModel.defaultTemplates;
      expect(allTemplates.length, greaterThan(30));

      // Test diesel car has solar filter
      final dieselTemplates = VehicleIntelligenceService.getTemplatesForVehicle('car_diesel');
      final dieselKeys = dieselTemplates.map((t) => t.itemKey).toList();
      expect(dieselKeys, contains('fuel_filter'));

      // Test hybrid car has inverter coolant and auxiliary battery
      final hybridTemplates = VehicleIntelligenceService.getTemplatesForVehicle('car_hybrid');
      final hybridKeys = hybridTemplates.map((t) => t.itemKey).toList();
      expect(hybridKeys, contains('inverter_coolant'));
      expect(hybridKeys, contains('aux_battery'));

      // Create vehicle through repository in local Hive and verify auto-generation
      final testScooter = VehicleModel(
        id: 'hive-scooter-test',
        brand: 'Yamaha',
        model: 'Fazzio',
        vehicleType: 'motorcycle',
        vehicleCategoryId: 'scooter_cvt',
        currentOdometer: 5000,
        year: 2023,
      );

      await vehicleRepository.createVehicle(testScooter);

      // Verify vehicle saved with category
      final saved = vehicleBox.get('hive-scooter-test');
      expect(saved, isNotNull);
      expect(saved!.vehicleCategoryId, 'scooter_cvt');

      // Verify maintenance items were automatically populated for scooter_cvt
      final maintList = await maintenanceRepository.getVehicleMaintenance(
        'hive-scooter-test',
        vehicleCategoryId: 'scooter_cvt',
      );

      expect(maintList, isNotEmpty);
      final savedKeys = maintList.map((m) => m.itemKey).toList();
      expect(savedKeys, contains('cvt_belt'));
      expect(savedKeys, contains('cvt_roller'));
      expect(savedKeys, isNot(contains('drive_chain')));
    });

    // =============================================================
    // PART 7: AUTOMATED AUDIT TESTS
    // =============================================================
    group('PART 7: AUTOMATED QUALITY AUDIT TESTS', () {
      // -----------------------------------------------------------
      // TEST 1: Vario 160 (scooter_cvt)
      // -----------------------------------------------------------
      test('TEST 1: Vario 160 - Ada CVT Belt & Roller, TIDAK ADA Chain & Sprocket & Kopling Manual', () {
        final vario = VehicleModel(
          id: 'audit-vario-160',
          brand: 'Honda',
          model: 'Vario 160',
          vehicleType: 'motorcycle',
          vehicleCategoryId: 'scooter_cvt',
          transmission: 'Automatic',
          fuelType: 'Gasoline',
          currentOdometer: 12000,
          year: 2023,
        );

        final items = VehicleIntelligenceService.generateMaintenanceItems(
          vehicle: vario,
          categoryId: 'scooter_cvt',
        );
        final itemKeys = items.map((i) => i.itemKey).toSet();

        // HARUS ADA:
        expect(itemKeys, contains('engine_oil'));
        expect(itemKeys, contains('gear_oil'));
        expect(itemKeys, contains('cvt_belt'));
        expect(itemKeys, contains('cvt_roller'));
        expect(itemKeys, contains('brake_pad'));
        expect(itemKeys, contains('tires'));
        expect(itemKeys, contains('battery'));
        expect(itemKeys, contains('air_filter'));
        expect(itemKeys, contains('spark_plug'));

        // TIDAK BOLEH ADA:
        expect(itemKeys, isNot(contains('drive_chain')));
        expect(itemKeys, isNot(contains('sprocket')));
        expect(itemKeys, isNot(contains('clutch_plate')));
      });

      // -----------------------------------------------------------
      // TEST 2: CB150R (sport_motorcycle)
      // -----------------------------------------------------------
      test('TEST 2: CB150R - Ada Chain, Sprocket & Clutch, TIDAK ADA CVT Belt & Roller', () {
        final cb150r = VehicleModel(
          id: 'audit-cb150r',
          brand: 'Honda',
          model: 'CB150R Streetfire',
          vehicleType: 'motorcycle',
          vehicleCategoryId: 'sport_motorcycle',
          transmission: 'Manual',
          fuelType: 'Gasoline',
          currentOdometer: 8000,
          year: 2022,
        );

        final items = VehicleIntelligenceService.generateMaintenanceItems(
          vehicle: cb150r,
          categoryId: 'sport_motorcycle',
        );
        final itemKeys = items.map((i) => i.itemKey).toSet();

        // HARUS ADA:
        expect(itemKeys, contains('engine_oil'));
        expect(itemKeys, contains('drive_chain'));
        expect(itemKeys, contains('sprocket'));
        expect(itemKeys, contains('clutch_plate'));
        expect(itemKeys, contains('radiator_coolant'));
        expect(itemKeys, contains('brake_pad'));
        expect(itemKeys, contains('tires'));
        expect(itemKeys, contains('battery'));
        expect(itemKeys, contains('air_filter'));
        expect(itemKeys, contains('spark_plug'));

        // TIDAK BOLEH ADA:
        expect(itemKeys, isNot(contains('cvt_belt')));
        expect(itemKeys, isNot(contains('cvt_roller')));
        expect(itemKeys, isNot(contains('gear_oil')));
      });

      // -----------------------------------------------------------
      // TEST 3: Avanza Automatic (car_automatic)
      // -----------------------------------------------------------
      test('TEST 3: Avanza Automatic - Ada AT Fluid, TIDAK ADA Clutch Manual & MT Fluid', () {
        final avanzaAt = VehicleModel(
          id: 'audit-avanza-at',
          brand: 'Toyota',
          model: 'Avanza 1.5 G CVT',
          vehicleType: 'car',
          vehicleCategoryId: 'car_automatic',
          transmission: 'Automatic',
          fuelType: 'Gasoline',
          currentOdometer: 25000,
          year: 2022,
        );

        final items = VehicleIntelligenceService.generateMaintenanceItems(
          vehicle: avanzaAt,
          categoryId: 'car_automatic',
        );
        final itemKeys = items.map((i) => i.itemKey).toSet();

        // HARUS ADA:
        expect(itemKeys, contains('engine_oil'));
        expect(itemKeys, contains('oil_filter'));
        expect(itemKeys, contains('at_fluid'));
        expect(itemKeys, contains('brake_pad'));
        expect(itemKeys, contains('battery'));
        expect(itemKeys, contains('tires'));
        expect(itemKeys, contains('engine_coolant'));
        expect(itemKeys, contains('cabin_filter'));
        expect(itemKeys, contains('wiper_blades'));

        // TIDAK BOLEH ADA:
        expect(itemKeys, isNot(contains('clutch_plate')));
        expect(itemKeys, isNot(contains('mt_fluid')));
      });

      // -----------------------------------------------------------
      // TEST 4: Avanza Manual (car_manual)
      // -----------------------------------------------------------
      test('TEST 4: Avanza Manual - Ada Clutch Manual & MT Fluid, TIDAK ADA AT Fluid', () {
        final avanzaMt = VehicleModel(
          id: 'audit-avanza-mt',
          brand: 'Toyota',
          model: 'Avanza 1.3 E MT',
          vehicleType: 'car',
          vehicleCategoryId: 'car_manual',
          transmission: 'Manual',
          fuelType: 'Gasoline',
          currentOdometer: 35000,
          year: 2021,
        );

        final items = VehicleIntelligenceService.generateMaintenanceItems(
          vehicle: avanzaMt,
          categoryId: 'car_manual',
        );
        final itemKeys = items.map((i) => i.itemKey).toSet();

        // HARUS ADA:
        expect(itemKeys, contains('engine_oil'));
        expect(itemKeys, contains('oil_filter'));
        expect(itemKeys, contains('mt_fluid'));
        expect(itemKeys, contains('clutch_plate'));
        expect(itemKeys, contains('brake_pad'));
        expect(itemKeys, contains('battery'));
        expect(itemKeys, contains('tires'));
        expect(itemKeys, contains('engine_coolant'));
        expect(itemKeys, contains('cabin_filter'));
        expect(itemKeys, contains('wiper_blades'));

        // TIDAK BOLEH ADA:
        expect(itemKeys, isNot(contains('at_fluid')));
      });

      // -----------------------------------------------------------
      // TEST DIESEL: Innova Diesel (car_diesel)
      // -----------------------------------------------------------
      test('TEST DIESEL: Innova Diesel - Ada Fuel Filter, TIDAK ADA Busi Bensin', () {
        final innovaDiesel = VehicleModel(
          id: 'audit-innova-diesel',
          brand: 'Toyota',
          model: 'Kijang Innova 2.4 V Diesel',
          vehicleType: 'car',
          vehicleCategoryId: 'car_diesel',
          transmission: 'Automatic',
          fuelType: 'Diesel',
          currentOdometer: 40000,
          year: 2020,
        );

        final items = VehicleIntelligenceService.generateMaintenanceItems(
          vehicle: innovaDiesel,
          categoryId: 'car_diesel',
        );
        final itemKeys = items.map((i) => i.itemKey).toSet();

        // HARUS ADA:
        expect(itemKeys, contains('fuel_filter'));
        expect(itemKeys, contains('engine_oil'));
        expect(itemKeys, contains('oil_filter'));

        // TIDAK BOLEH ADA:
        expect(itemKeys, isNot(contains('spark_plug')));
      });

      // -----------------------------------------------------------
      // TEST 5: Legacy vehicle (tanpa vehicle_category_id)
      // -----------------------------------------------------------
      test('TEST 5: Legacy vehicle - Tidak crash dan berhasil generate sesuai kategori fallback', () {
        final legacyMotor = VehicleModel(
          id: 'audit-legacy-vario',
          brand: 'Honda',
          model: 'Vario 150',
          vehicleType: 'motorcycle',
          vehicleCategoryId: null, // Legacy vehicle
          transmission: 'Automatic',
          fuelType: 'Gasoline',
          currentOdometer: 18000,
          year: 2019,
        );

        expect(VehicleIntelligenceService.isLegacyVehicle(legacyMotor), isTrue);

        // Fallback kategori harus resolusi tanpa crash
        final resolvedCategory = VehicleIntelligenceService.resolveCategoryId(legacyMotor);
        expect(resolvedCategory, 'scooter_cvt');

        // Generate maintenance items tidak crash
        final generated = VehicleIntelligenceService.generateMaintenanceItems(
          vehicle: legacyMotor,
          categoryId: resolvedCategory,
        );
        expect(generated, isNotEmpty);
        expect(generated.any((m) => m.itemKey == 'cvt_belt'), isTrue);
      });

      // -----------------------------------------------------------
      // TEST HYBRID: Yaris Cross Hybrid (car_hybrid)
      // -----------------------------------------------------------
      test('TEST HYBRID: Yaris Cross Hybrid - Ada Inverter Coolant & Baterai Hybrid, TIDAK ADA Kopling Manual', () {
        final hybridCar = VehicleModel(
          id: 'audit-yaris-hybrid',
          brand: 'Toyota',
          model: 'Yaris Cross 1.5 S HEV',
          vehicleType: 'car',
          vehicleCategoryId: 'car_hybrid',
          transmission: 'Automatic',
          fuelType: 'Hybrid',
          currentOdometer: 15000,
          year: 2023,
        );

        final items = VehicleIntelligenceService.generateMaintenanceItems(
          vehicle: hybridCar,
          categoryId: 'car_hybrid',
        );
        final itemKeys = items.map((i) => i.itemKey).toSet();

        expect(itemKeys, contains('engine_oil'));
        expect(itemKeys, contains('oil_filter'));
        expect(itemKeys, contains('inverter_coolant'));
        expect(itemKeys, contains('aux_battery'));

        // TIDAK BOLEH ADA:
        expect(itemKeys, isNot(contains('clutch_plate')));
        expect(itemKeys, isNot(contains('mt_fluid')));
      });
    });
  });
}
