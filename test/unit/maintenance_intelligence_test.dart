import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ridecare/core/database/hive_boxes.dart';
import 'package:ridecare/core/database/hive_registrar.dart';
import 'package:ridecare/features/maintenance/data/models/maintenance_catalog_model.dart';
import 'package:ridecare/features/maintenance/data/models/maintenance_item_model.dart';
import 'package:ridecare/features/maintenance/data/models/maintenance_price_model.dart';
import 'package:ridecare/features/maintenance/data/models/service_log_model.dart';
import 'package:ridecare/features/maintenance/data/models/service_record_model.dart';
import 'package:ridecare/features/maintenance/data/models/vehicle_maintenance_model.dart';
import 'package:ridecare/features/maintenance/data/repositories/maintenance_repository.dart';
import 'package:ridecare/features/maintenance/domain/health_calculation_service.dart';
import 'package:ridecare/features/vehicle/data/models/vehicle_model.dart';
import 'package:ridecare/features/vehicle/data/repositories/vehicle_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MaintenanceRepository maintenanceRepository;
  late VehicleRepository vehicleRepository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ridecare_maint_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(VehicleModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MaintenanceItemModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(ServiceLogModelAdapter());

    await Hive.openBox<VehicleModel>(HiveBoxes.vehicles);
    await Hive.openBox<MaintenanceItemModel>(HiveBoxes.maintenance);
    await Hive.openBox<ServiceLogModel>(HiveBoxes.serviceHistory);
    await Hive.openBox<dynamic>(HiveBoxes.settings);

    maintenanceRepository = MaintenanceRepository();
    vehicleRepository = VehicleRepository();
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
    await HiveRegistrar.serviceHistoryBox.clear();
  });

  group('Maintenance Intelligence Module Tests', () {
    // -------------------------------------------------------------
    // TEST 1: Create Honda Beat & Generate Maintenance Items
    // -------------------------------------------------------------
    test('TEST 1: Inisialisasi Kendaraan Honda Beat -> Maintenance Items Otomatis Tersedia', () async {
      final beat = VehicleModel(
        id: 'honda-beat-uuid-001',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        engineCc: 110,
        currentOdometer: 10000,
      );

      await vehicleRepository.createVehicle(beat);

      // Ambil item maintenance untuk kendaraan ini
      final items = await maintenanceRepository.getVehicleMaintenance(
        beat.id,
        vehicleType: beat.vehicleType,
        currentOdometer: beat.currentOdometer,
      );

      // Verifikasi 14 item motor tersedia lengkap
      expect(items.length, 14);

      // Verifikasi komponen penting ada
      final names = items.map((e) => e.itemName).toList();
      expect(names, contains('Engine Oil'));
      expect(names, contains('Final Drive / Gear Oil'));
      expect(names, contains('Brake Pad Front'));
      expect(names, contains('CVT Service'));
      expect(names, contains('Spark Plug'));
      expect(names, contains('Coolant'));

      // Verifikasi default interval oli mesin 3000 km
      final oilItem = items.firstWhere((e) => e.itemName == 'Engine Oil');
      expect(oilItem.intervalKm, 3000);
      expect(oilItem.healthPercentage, 100);
      expect(oilItem.status, 'GOOD');
    });

    // -------------------------------------------------------------
    // TEST 2: Maintenance Health Calculation (Odo 12.500, Last 10.000, Int 3.000)
    // -------------------------------------------------------------
    test('TEST 2: Perhitungan Health & Remaining KM (Odometer 12.500 KM, Last 10.000 KM, Interval 3.000 KM)', () async {
      final oilItem = VehicleMaintenanceModel(
        id: 'vm-oil-beat',
        vehicleId: 'honda-beat-uuid-001',
        maintenanceId: 'mc-01-engine-oil',
        itemName: 'Engine Oil',
        intervalKm: 3000,
        lastServiceOdometer: 10000,
        lastServiceDate: DateTime(2026, 5, 1),
        healthPercentage: 100,
        status: 'GOOD',
      );

      final priceEstimate = maintenanceRepository.getEstimatedPrice(
        'Engine Oil',
        vehicleType: 'motorcycle',
      );

      final healthResult = HealthCalculationService.calculateItemHealth(
        item: oilItem,
        currentOdometer: 12500,
        defaultIntervalKm: 3000,
        priceEstimate: priceEstimate,
      );

      // Used: 12.500 - 10.000 = 2.500 KM
      expect(healthResult.usedKm, 2500);

      // Remaining: 3.000 - 2.500 = 500 KM
      expect(healthResult.remainingKm, 500);

      // Health %: (500 / 3000) * 100 = 16.666...% (sekitar 17%)
      expect(healthResult.healthPercentage, closeTo(16.67, 0.1));
      expect(healthResult.healthPercentage.round(), 17);

      // Status harus DUE SOON karena remaining 500 KM <= 25% dari 3000 (750 KM)
      expect(healthResult.status, 'DUE SOON');
      expect(healthResult.isDueSoon, isTrue);

      // Estimasi harga terhubung: Total Rp60.000 - Rp150.000
      expect(healthResult.priceEstimate, isNotNull);
      expect(healthResult.priceEstimate!.minTotal, 60000);
      expect(healthResult.priceEstimate!.maxTotal, 150000);
      expect(healthResult.priceEstimate!.formattedTotalRange, contains('60.000'));
      expect(healthResult.priceEstimate!.formattedTotalRange, contains('150.000'));
    });

    // -------------------------------------------------------------
    // TEST 3: Add Service Record (Oil Change @ 12.500 KM, Rp80.000) -> Health Returns to 100%
    // -------------------------------------------------------------
    test('TEST 3: Catat Servis Oli di 12.500 KM (Rp80.000) -> Health Kembali 100% (GOOD)', () async {
      final vehicleId = 'honda-beat-uuid-001';

      // Pastikan item sudah ada di repository
      await maintenanceRepository.getVehicleMaintenance(vehicleId, vehicleType: 'motorcycle');

      // Tambahkan service record
      final record = ServiceRecordModel(
        id: 'srv-record-beat-01',
        vehicleId: vehicleId,
        maintenanceId: 'mc-01-engine-oil',
        maintenanceName: 'Engine Oil',
        serviceDate: DateTime(2026, 6, 1),
        odometer: 12500,
        cost: 80000,
        workshop: 'AHASS Motor',
        notes: 'Ganti oli mesin MPX2',
      );

      await maintenanceRepository.addServiceRecord(record);

      // Cek record tersimpan di riwayat
      final history = await maintenanceRepository.getServiceRecords(vehicleId);
      expect(history.any((r) => r.id == 'srv-record-beat-01'), isTrue);
      final savedRecord = history.firstWhere((r) => r.id == 'srv-record-beat-01');
      expect(savedRecord.odometer, 12500);
      expect(savedRecord.cost, 80000);

      // Cek vehicle_maintenance terupdate
      final updatedItems = await maintenanceRepository.getVehicleMaintenance(vehicleId);
      final updatedOil = updatedItems.firstWhere((it) => it.maintenanceId == 'mc-01-engine-oil');

      expect(updatedOil.lastServiceOdometer, 12500);
      expect(updatedOil.healthPercentage, 100);
      expect(updatedOil.status, 'GOOD');

      // Hitung ulang health pada odometer 12.500 KM
      final newHealth = HealthCalculationService.calculateItemHealth(
        item: updatedOil,
        currentOdometer: 12500,
        defaultIntervalKm: 3000,
      );

      expect(newHealth.usedKm, 0);
      expect(newHealth.remainingKm, 3000);
      expect(newHealth.healthPercentage, 100.0);
      expect(newHealth.status, 'GOOD');
    });

    // -------------------------------------------------------------
    // TEST 4: Offline Mode (Bekerja tanpa internet dari cache lokal)
    // -------------------------------------------------------------
    test('TEST 4: Mode Offline - Health calculation & Cost library tetap berjalan tanpa internet', () async {
      // Panggilan getCatalog offline
      final catalog = await maintenanceRepository.getCatalog(vehicleType: 'motorcycle');
      expect(catalog, isNotEmpty);
      expect(catalog.length, 14);

      // Panggilan getPrices offline
      final prices = await maintenanceRepository.getPrices(vehicleType: 'motorcycle');
      expect(prices, isNotEmpty);

      final oilPrice = maintenanceRepository.getEstimatedPrice('Engine Oil', vehicleType: 'motorcycle');
      expect(oilPrice, isNotNull);
      expect(oilPrice!.minPrice, 50000);
      expect(oilPrice.maxPrice, 120000);
      expect(oilPrice.laborMin, 10000);
      expect(oilPrice.laborMax, 30000);
      expect(oilPrice.minTotal, 60000);
      expect(oilPrice.maxTotal, 150000);

      // Disclaimer harga tersedia
      expect(MaintenancePriceModel.priceDisclaimer, contains('database internal RideCare'));
      expect(MaintenancePriceModel.priceDisclaimer, contains('Juni 2026'));
    });

    // -------------------------------------------------------------
    // TEST 5: Online Sync Serialization (Payload Siap Sinkronisasi Supabase)
    // -------------------------------------------------------------
    test('TEST 5: Format Payload Sinkronisasi Siap untuk Supabase', () async {
      final record = ServiceRecordModel(
        id: 'sync-test-uuid',
        vehicleId: 'veh-test-uuid',
        maintenanceId: 'mc-01-engine-oil',
        serviceDate: DateTime(2026, 6, 1),
        odometer: 12500,
        cost: 80000,
        workshop: 'AHASS',
        notes: 'Flushing & ganti oli',
      );

      final payload = record.toJson();
      expect(payload['id'], 'sync-test-uuid');
      expect(payload['vehicle_id'], 'veh-test-uuid');
      expect(payload['maintenance_id'], 'mc-01-engine-oil');
      expect(payload['service_date'], '2026-06-01');
      expect(payload['odometer'], 12500);
      expect(payload['cost'], 80000.0);
      expect(payload['workshop'], 'AHASS');

      // Deserialisasi balik
      final fromJson = ServiceRecordModel.fromJson(payload);
      expect(fromJson.odometer, 12500);
      expect(fromJson.cost, 80000);
    });

    // -------------------------------------------------------------
    // TEST 6: Verifikasi Schema 4 Tabel Supabase (Catalog, Prices, Vehicle Maint, Service Records)
    // -------------------------------------------------------------
    test('TEST 6: Validasi Schema Supabase (maintenance_catalog, maintenance_prices, vehicle_maintenance, service_records)', () {
      // 1. maintenance_catalog
      final cat = MaintenanceCatalogModel(
        id: 'cat-test-1',
        name: 'Engine Oil',
        category: 'fluids',
        vehicleType: 'motorcycle',
        defaultIntervalKm: 3000,
        defaultIntervalMonth: 3,
        description: 'Uji ganti oli',
      );
      final catJson = cat.toJson();
      expect(catJson.containsKey('id'), isTrue);
      expect(catJson.containsKey('name'), isTrue);
      expect(catJson.containsKey('category'), isTrue);
      expect(catJson.containsKey('vehicle_type'), isTrue);
      expect(catJson.containsKey('default_interval_km'), isTrue);
      expect(catJson.containsKey('default_interval_month'), isTrue);
      expect(catJson.containsKey('description'), isTrue);

      // 2. maintenance_prices
      final price = MaintenancePriceModel(
        id: 'prc-test-1',
        maintenanceId: 'cat-test-1',
        vehicleType: 'motorcycle',
        minPrice: 50000,
        maxPrice: 120000,
        laborMin: 10000,
        laborMax: 30000,
        source: 'RideCare Internal Estimate',
        updatedDate: '2026-06-01',
      );
      final prcJson = price.toJson();
      expect(prcJson.containsKey('id'), isTrue);
      expect(prcJson.containsKey('maintenance_id'), isTrue);
      expect(prcJson.containsKey('vehicle_type'), isTrue);
      expect(prcJson.containsKey('min_price'), isTrue);
      expect(prcJson.containsKey('max_price'), isTrue);
      expect(prcJson.containsKey('labor_min'), isTrue);
      expect(prcJson.containsKey('labor_max'), isTrue);
      expect(prcJson.containsKey('source'), isTrue);
      expect(prcJson.containsKey('updated_date'), isTrue);

      // 3. vehicle_maintenance
      final vm = VehicleMaintenanceModel(
        id: 'vm-test-1',
        vehicleId: 'veh-test-1',
        maintenanceId: 'cat-test-1',
        lastServiceDate: DateTime(2026, 6, 1),
        lastServiceOdometer: 10000,
        healthPercentage: 100,
        status: 'GOOD',
      );
      final vmJson = vm.toJson();
      expect(vmJson.containsKey('id'), isTrue);
      expect(vmJson.containsKey('vehicle_id'), isTrue);
      expect(vmJson.containsKey('maintenance_id'), isTrue);
      expect(vmJson.containsKey('last_service_date'), isTrue);
      expect(vmJson.containsKey('last_service_odometer'), isTrue);
      expect(vmJson.containsKey('health_percentage'), isTrue);
      expect(vmJson.containsKey('status'), isTrue);

      // 4. service_records
      final srv = ServiceRecordModel(
        id: 'srv-test-1',
        vehicleId: 'veh-test-1',
        maintenanceId: 'cat-test-1',
        serviceDate: DateTime(2026, 6, 1),
        odometer: 12500,
        cost: 80000,
        workshop: 'AHASS',
        notes: 'Notes test',
      );
      final srvJson = srv.toJson();
      expect(srvJson.containsKey('id'), isTrue);
      expect(srvJson.containsKey('vehicle_id'), isTrue);
      expect(srvJson.containsKey('maintenance_id'), isTrue);
      expect(srvJson.containsKey('service_date'), isTrue);
      expect(srvJson.containsKey('odometer'), isTrue);
      expect(srvJson.containsKey('cost'), isTrue);
      expect(srvJson.containsKey('workshop'), isTrue);
      expect(srvJson.containsKey('notes'), isTrue);
    });
  });
}
