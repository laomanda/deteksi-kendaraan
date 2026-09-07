import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ridecare/core/database/hive_boxes.dart';
import 'package:ridecare/core/database/hive_registrar.dart';
import 'package:ridecare/features/maintenance/data/models/maintenance_item_model.dart';
import 'package:ridecare/features/maintenance/data/models/maintenance_price_model.dart';
import 'package:ridecare/features/maintenance/data/models/service_log_model.dart';
import 'package:ridecare/features/maintenance/data/models/service_record_model.dart';
import 'package:ridecare/features/maintenance/data/models/vehicle_maintenance_model.dart';
import 'package:ridecare/features/maintenance/data/repositories/maintenance_repository.dart';
import 'package:ridecare/features/maintenance/domain/maintenance_cost_forecast_service.dart';
import 'package:ridecare/features/maintenance/domain/maintenance_prediction_service.dart';
import 'package:ridecare/features/ride_tracking/data/models/gps_point_model.dart';
import 'package:ridecare/features/ride_tracking/data/models/ride_session_model.dart';
import 'package:ridecare/features/vehicle/data/models/vehicle_model.dart';
import 'package:ridecare/features/vehicle/data/repositories/vehicle_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late VehicleRepository vehicleRepository;
  late MaintenanceRepository maintenanceRepository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ridecare_prediction_test_');
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
    await HiveRegistrar.serviceHistoryBox.clear();
    await HiveRegistrar.ridesBox.clear();
  });

  group('MAINTENANCE PREDICTION & BUDGET FORECAST TEST SUITE (12/12)', () {
    // -------------------------------------------------------------
    // TEST 1: KM-based prediction
    // Current: 12.500 | Last: 10.000 | Interval: 3.000
    // Remaining: 500 KM | Next service: 13.000 KM
    // -------------------------------------------------------------
    test('TEST 1: KM-based prediction (Current 12.500, Last 10.000, Interval 3.000)', () {
      final now = DateTime(2026, 6, 1);
      final item = VehicleMaintenanceModel(
        id: 'vm-test-1',
        vehicleId: 'veh-1',
        maintenanceId: 'm-oil',
        itemName: 'Oli Mesin',
        itemCategory: 'Mesin',
        healthPercentage: 17,
        lastServiceOdometer: 10000,
        lastServiceDate: DateTime(2026, 3, 1),
        intervalKm: 3000,
        intervalMonth: 3,
        updatedAt: now,
      );

      final prediction = MaintenancePredictionService.predictItem(
        item: item,
        currentOdometer: 12500,
        currentDate: now,
      );

      expect(prediction.nextServiceOdometer, equals(13000),
          reason: 'Next service odometer must be lastService (10.000) + interval (3.000) = 13.000');
      expect(prediction.remainingKm, equals(500),
          reason: 'Remaining KM must be 13.000 - 12.500 = 500 KM');
      expect(prediction.usedKm, equals(2500),
          reason: 'Used KM must be 12.500 - 10.000 = 2.500 KM');
    });

    // -------------------------------------------------------------
    // TEST 2: KM-based prediction (DUE SOON)
    // Current: 12.565 | Last: 10.000 | Interval: 3.000
    // Remaining: 435 KM | Status: DUE SOON
    // -------------------------------------------------------------
    test('TEST 2: KM-based prediction (Current 12.565, Last 10.000, Interval 3.000 -> DUE SOON)', () {
      final now = DateTime(2026, 6, 1);
      final item = VehicleMaintenanceModel(
        id: 'vm-test-2',
        vehicleId: 'veh-2',
        maintenanceId: 'm-oil',
        itemName: 'Oli Mesin',
        itemCategory: 'Mesin',
        healthPercentage: 15,
        lastServiceOdometer: 10000,
        lastServiceDate: DateTime(2026, 5, 1),
        intervalKm: 3000,
        intervalMonth: 3,
        updatedAt: now,
      );

      final prediction = MaintenancePredictionService.predictItem(
        item: item,
        currentOdometer: 12565,
        currentDate: now,
      );

      expect(prediction.remainingKm, equals(435),
          reason: 'Remaining KM must be 13.000 - 12.565 = 435 KM');
      expect(prediction.status, equals('DUE SOON'),
          reason: 'Remaining KM (435) <= 25% interval (750) triggers DUE SOON status');
      expect(prediction.isDueSoon, isTrue);
      expect(prediction.isOverdue, isFalse);
    });

    // -------------------------------------------------------------
    // TEST 3: KM-based prediction (OVERDUE)
    // Current: 13.100 | Last: 10.000 | Interval: 3.000
    // Remaining: 0 KM | Status: OVERDUE
    // -------------------------------------------------------------
    test('TEST 3: KM-based prediction (Current 13.100, Last 10.000, Interval 3.000 -> OVERDUE)', () {
      final now = DateTime(2026, 6, 1);
      final item = VehicleMaintenanceModel(
        id: 'vm-test-3',
        vehicleId: 'veh-3',
        maintenanceId: 'm-oil',
        itemName: 'Oli Mesin',
        itemCategory: 'Mesin',
        healthPercentage: 0,
        lastServiceOdometer: 10000,
        lastServiceDate: DateTime(2026, 3, 1),
        intervalKm: 3000,
        intervalMonth: 3,
        updatedAt: now,
      );

      final prediction = MaintenancePredictionService.predictItem(
        item: item,
        currentOdometer: 13100,
        currentDate: now,
      );

      expect(prediction.status, equals('OVERDUE'),
          reason: 'Current odometer (13.100) > Next service (13.000) must be OVERDUE');
      expect(prediction.isOverdue, isTrue);
      expect(prediction.remainingKm, equals(0),
          reason: 'Remaining KM should be clamped to 0 when overdue');
      expect(prediction.urgencyGroup, equals('URGENT'));
    });

    // -------------------------------------------------------------
    // TEST 4: Time-based prediction
    // Last service: 1 Juni 2026 | Interval: 3 bulan
    // Due date: 1 September 2026 | Remaining days dihitung dari tanggal sekarang
    // -------------------------------------------------------------
    test('TEST 4: Time-based prediction (Last 1 Juni 2026, Interval 3 bulan -> 1 Sept 2026)', () {
      final lastServiceDate = DateTime(2026, 6, 1);
      const intervalMonths = 3;

      final dueDate = MaintenancePredictionService.addMonthsSafely(lastServiceDate, intervalMonths);

      expect(dueDate.year, equals(2026));
      expect(dueDate.month, equals(9));
      expect(dueDate.day, equals(1));

      // Evaluated from 10 Juni 2026
      final refDate = DateTime(2026, 6, 10);
      final remainingDays = dueDate.difference(refDate).inDays;
      expect(remainingDays, equals(83));
    });

    // -------------------------------------------------------------
    // TEST 5: Whichever comes first
    // KM: 500 KM | Time: 20 hari
    // Text: "500 KM or 20 days"
    // -------------------------------------------------------------
    test('TEST 5: Whichever comes first format ("500 KM or 20 days")', () {
      final text = MaintenancePredictionService.formatWhicheverComesFirst(
        remainingKm: 500,
        remainingDays: 20,
      );

      expect(text, equals('500 KM or 20 days'));
    });

    // -------------------------------------------------------------
    // TEST 6: Cost calculation
    // Part: 50.000 - 120.000 | Labor: 10.000 - 30.000
    // Total: 60.000 - 150.000
    // -------------------------------------------------------------
    test('TEST 6: Cost calculation (Part 50K-120K + Labor 10K-30K -> Total 60K-150K)', () {
      final result = MaintenanceCostForecastService.calculateItemCost(
        partMin: 50000,
        partMax: 120000,
        laborMin: 10000,
        laborMax: 30000,
      );

      expect(result.totalMin, equals(60000.0));
      expect(result.totalMax, equals(150000.0));

      final item = VehicleMaintenanceModel(
        id: 'vm-test-6',
        vehicleId: 'veh-6',
        maintenanceId: 'm-oil',
        itemName: 'Oli Mesin',
        itemCategory: 'Mesin',
        healthPercentage: 80,
        lastServiceOdometer: 10000,
        lastServiceDate: DateTime(2026, 6, 1),
        intervalKm: 3000,
        intervalMonth: 3,
        updatedAt: DateTime(2026, 6, 1),
      );

      final customPrice = MaintenancePriceModel(
        id: 'price-custom',
        maintenanceId: 'm-oil',
        vehicleType: 'motorcycle',
        minPrice: 50000,
        maxPrice: 120000,
        laborMin: 10000,
        laborMax: 30000,
      );

      final prediction = MaintenancePredictionService.predictItem(
        item: item,
        currentOdometer: 10500,
        priceEstimate: customPrice,
      );

      expect(prediction.partMin, equals(50000.0));
      expect(prediction.partMax, equals(120000.0));
      expect(prediction.laborMin, equals(10000.0));
      expect(prediction.laborMax, equals(30000.0));
      expect(prediction.totalMin, equals(60000.0));
      expect(prediction.totalMax, equals(150000.0));
      expect(prediction.formattedTotalRange, contains('60.000'));
      expect(prediction.formattedTotalRange, contains('150.000'));
    });

    // -------------------------------------------------------------
    // TEST 7: Multiple maintenance cost
    // Komponen A: 60.000 - 150.000
    // Komponen B: 40.000 - 90.000
    // Total: 100.000 - 240.000
    // -------------------------------------------------------------
    test('TEST 7: Multiple maintenance cost (A: 60K-150K + B: 40K-90K -> Total: 100K-240K)', () {
      final now = DateTime(2026, 6, 1);

      final itemA = VehicleMaintenanceModel(
        id: 'vm-a',
        vehicleId: 'veh-7',
        maintenanceId: 'm-a',
        itemName: 'Komponen A',
        itemCategory: 'Mesin',
        healthPercentage: 50,
        lastServiceOdometer: 8000,
        lastServiceDate: now,
        intervalKm: 3000,
        intervalMonth: 3,
        updatedAt: now,
      );

      final itemB = VehicleMaintenanceModel(
        id: 'vm-b',
        vehicleId: 'veh-7',
        maintenanceId: 'm-b',
        itemName: 'Komponen B',
        itemCategory: 'Pengereman',
        healthPercentage: 50,
        lastServiceOdometer: 8000,
        lastServiceDate: now,
        intervalKm: 5000,
        intervalMonth: 6,
        updatedAt: now,
      );

      final priceA = MaintenancePriceModel(
        id: 'p-a',
        maintenanceId: 'm-a',
        vehicleType: 'motorcycle',
        minPrice: 50000,
        maxPrice: 120000,
        laborMin: 10000,
        laborMax: 30000,
      );

      final priceB = MaintenancePriceModel(
        id: 'p-b',
        maintenanceId: 'm-b',
        vehicleType: 'motorcycle',
        minPrice: 35000,
        maxPrice: 70000,
        laborMin: 5000,
        laborMax: 20000,
      );

      final predA = MaintenancePredictionService.predictItem(
        item: itemA,
        currentOdometer: 10000,
        priceEstimate: priceA,
      );

      final predB = MaintenancePredictionService.predictItem(
        item: itemB,
        currentOdometer: 10000,
        priceEstimate: priceB,
      );

      final total = MaintenanceCostForecastService.calculateTotalCost([predA, predB]);

      expect(total.minTotal, equals(100000.0),
          reason: 'Minimum cost must sum: 60.000 + 40.000 = 100.000');
      expect(total.maxTotal, equals(240000.0),
          reason: 'Maximum cost must sum: 150.000 + 90.000 = 240.000');
    });

    // -------------------------------------------------------------
    // TEST 8: 30-day forecast
    // Hanya item yang jatuh tempo dalam 30 hari yang masuk ke 30-day bucket
    // -------------------------------------------------------------
    test('TEST 8: 30-day forecast (Only items due within 30 days are included)', () {
      final now = DateTime(2026, 6, 1);
      final vehicle = VehicleModel(
        id: 'veh-8',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 10000,
        createdAt: now,
        updatedAt: now,
      );

      // Item 1: 15 days remaining -> in 30, 90, 180
      final item1 = VehicleMaintenanceModel(
        id: 'vm-f1',
        vehicleId: 'veh-8',
        maintenanceId: 'm-f1',
        itemName: 'Item 15 Hari',
        itemCategory: 'Mesin',
        healthPercentage: 10,
        lastServiceOdometer: 7500,
        lastServiceDate: DateTime(2026, 5, 17), // 15 days left till June 16 (1 month interval)
        intervalKm: 10000,
        intervalMonth: 1,
        updatedAt: now,
      );

      // Item 2: 25 days remaining -> in 30, 90, 180
      final item2 = VehicleMaintenanceModel(
        id: 'vm-f2',
        vehicleId: 'veh-8',
        maintenanceId: 'm-f2',
        itemName: 'Item 25 Hari',
        itemCategory: 'Mesin',
        healthPercentage: 20,
        lastServiceOdometer: 7000,
        lastServiceDate: DateTime(2026, 5, 27), // 25 days left till June 27 (1 month interval)
        intervalKm: 10000,
        intervalMonth: 1,
        updatedAt: now,
      );

      // Item 3: 60 days remaining -> NOT in 30, but in 90, 180
      final item3 = VehicleMaintenanceModel(
        id: 'vm-f3',
        vehicleId: 'veh-8',
        maintenanceId: 'm-f3',
        itemName: 'Item 60 Hari',
        itemCategory: 'Transmisi',
        healthPercentage: 50,
        lastServiceOdometer: 5000,
        lastServiceDate: DateTime(2026, 5, 1),
        intervalKm: 10000,
        intervalMonth: 3, // due Aug 1 (approx 61 days)
        updatedAt: now,
      );

      // Item 4: 150 days remaining -> NOT in 30, NOT in 90, but in 180
      final item4 = VehicleMaintenanceModel(
        id: 'vm-f4',
        vehicleId: 'veh-8',
        maintenanceId: 'm-f4',
        itemName: 'Item 150 Hari',
        itemCategory: 'Rangka',
        healthPercentage: 70,
        lastServiceOdometer: 2000,
        lastServiceDate: DateTime(2026, 5, 1),
        intervalKm: 15000,
        intervalMonth: 6, // due Nov 1 (approx 153 days)
        updatedAt: now,
      );

      final preds = MaintenancePredictionService.predictVehicleMaintenance(
        vehicle: vehicle,
        items: [item1, item2, item3, item4],
        currentDate: now,
      );

      final forecast = MaintenanceCostForecastService.calculateBudgetForecast(preds);

      expect(forecast[30]!.items.length, equals(2),
          reason: '30-day forecast must strictly contain only item1 and item2');
      expect(forecast[30]!.items.any((p) => p.componentName == 'Item 15 Hari'), isTrue);
      expect(forecast[30]!.items.any((p) => p.componentName == 'Item 25 Hari'), isTrue);
      expect(forecast[30]!.items.any((p) => p.componentName == 'Item 60 Hari'), isFalse);

      expect(forecast[90]!.items.length, equals(3),
          reason: '90-day forecast includes items due within 90 days (15, 25, 60 days)');
      expect(forecast[180]!.items.length, equals(4),
          reason: '180-day forecast includes all 4 items');
    });

    // -------------------------------------------------------------
    // TEST 9: Offline behavior
    // Internet OFF -> Kalkulasi dan prediksi tetap berjalan 100% offline
    // -------------------------------------------------------------
    test('TEST 9: Offline behavior (Calculations run 100% deterministically without network)', () async {
      final now = DateTime(2026, 6, 1);
      final offlineVehicle = VehicleModel(
        id: 'veh-offline-001',
        brand: 'Honda',
        model: 'Vario 160',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 15000,
        createdAt: now,
        updatedAt: now,
      );

      await vehicleRepository.saveVehicle(offlineVehicle);

      final items = await maintenanceRepository.getVehicleMaintenance(
        offlineVehicle.id,
        vehicleType: 'motorcycle',
        currentOdometer: offlineVehicle.currentOdometer,
      );

      expect(items, isNotEmpty,
          reason: 'Maintenance items generated from local catalog when offline');

      final predictions = MaintenancePredictionService.predictVehicleMaintenance(
        vehicle: offlineVehicle,
        items: items,
        currentDate: now,
      );

      expect(predictions, isNotEmpty);
      for (final p in predictions) {
        expect(p.componentName, isNotEmpty);
        expect(p.totalMin, greaterThan(0));
        expect(p.totalMax, greaterThanOrEqualTo(p.totalMin));
        expect(p.whicheverComesFirstText, isNotEmpty);
      }

      final forecast = MaintenanceCostForecastService.calculateBudgetForecast(predictions);
      expect(forecast[30]!.days, equals(30));
      expect(forecast[90]!.days, equals(90));
      expect(forecast[180]!.days, equals(180));
    });

    // -------------------------------------------------------------
    // TEST 10: Ride integration
    // Selesai ride -> Odometer bertambah -> Prediksi servis otomatis terhitung ulang
    // -------------------------------------------------------------
    test('TEST 10: Ride integration (Ride increments odometer -> recalculates predictions)', () async {
      final now = DateTime(2026, 6, 1);
      final vehicle = VehicleModel(
        id: 'veh-ride-test',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 12500,
        createdAt: now,
        updatedAt: now,
      );

      await vehicleRepository.saveVehicle(vehicle);

      final item = VehicleMaintenanceModel(
        id: 'vm-ride-int',
        vehicleId: vehicle.id,
        maintenanceId: 'm-oil',
        itemName: 'Oli Mesin',
        itemCategory: 'Mesin',
        healthPercentage: 17,
        lastServiceOdometer: 10000,
        lastServiceDate: DateTime(2026, 5, 1),
        intervalKm: 3000,
        intervalMonth: 3,
        updatedAt: now,
      );

      // Before ride: 12.500 KM -> remaining: 500 KM
      final predBefore = MaintenancePredictionService.predictItem(
        item: item,
        currentOdometer: vehicle.currentOdometer,
        currentDate: now,
      );
      expect(predBefore.remainingKm, equals(500));

      // Simulate a completed ride of 65 KM
      final updatedVehicle = vehicle.copyWith(currentOdometer: 12565);
      await vehicleRepository.saveVehicle(updatedVehicle);

      // After ride: 12.565 KM -> remaining: 435 KM, DUE SOON
      final predAfter = MaintenancePredictionService.predictItem(
        item: item,
        currentOdometer: updatedVehicle.currentOdometer,
        currentDate: now,
      );

      expect(predAfter.remainingKm, equals(435),
          reason: 'Remaining KM must decrease by 65 KM after ride');
      expect(predAfter.status, equals('DUE SOON'));
      expect(predAfter.isDueSoon, isTrue);
    });

    // -------------------------------------------------------------
    // TEST 11: Service integration
    // Servis dicatat -> health kembali 100% -> jadwal berikutnya terhitung dari odometer baru
    // -------------------------------------------------------------
    test('TEST 11: Service integration (Service logged -> health 100% -> schedule recalculated)', () async {
      final serviceDate = DateTime(2026, 6, 1);
      final vehicle = VehicleModel(
        id: 'veh-service-int',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 12565,
        createdAt: serviceDate,
        updatedAt: serviceDate,
      );

      await vehicleRepository.saveVehicle(vehicle);

      final initialItem = VehicleMaintenanceModel(
        id: 'vm-service-int',
        vehicleId: vehicle.id,
        maintenanceId: 'm-oil',
        itemName: 'Oli Mesin',
        itemCategory: 'Mesin',
        healthPercentage: 15,
        lastServiceOdometer: 10000,
        lastServiceDate: DateTime(2026, 3, 1),
        intervalKm: 3000,
        intervalMonth: 3,
        updatedAt: serviceDate,
      );

      await maintenanceRepository.updateVehicleMaintenance(initialItem);

      // Record a service of Rp80.000 at 12.565 KM
      final serviceRecord = ServiceRecordModel(
        id: 'srv-rec-001',
        vehicleId: vehicle.id,
        maintenanceId: initialItem.maintenanceId,
        maintenanceName: initialItem.itemName,
        serviceDate: serviceDate,
        odometer: 12565,
        cost: 80000,
        notes: 'Ganti oli berkala bengkel resmi',
        createdAt: serviceDate,
      );

      await maintenanceRepository.addServiceRecord(serviceRecord);

      // Fetch the updated item
      final itemsAfterService = await maintenanceRepository.getVehicleMaintenance(vehicle.id);
      final updatedItem = itemsAfterService.firstWhere((it) => it.id == initialItem.id);

      expect(updatedItem.healthPercentage, equals(100),
          reason: 'Health percentage must reset to 100 after service');
      expect(updatedItem.lastServiceOdometer, equals(12565),
          reason: 'Last service odometer must be updated to service odometer');
      expect(updatedItem.lastServiceDate, equals(serviceDate),
          reason: 'Last service date must be updated to service date');

      // Predict next service after the record
      final prediction = MaintenancePredictionService.predictItem(
        item: updatedItem,
        currentOdometer: vehicle.currentOdometer,
        currentDate: serviceDate,
      );

      expect(prediction.nextServiceOdometer, equals(15565),
          reason: 'Next service odometer must be 12.565 + 3.000 = 15.565 KM');
      expect(prediction.remainingKm, equals(3000),
          reason: 'Remaining KM must be 3.000 KM right after service');
      expect(prediction.status, equals('GOOD'));
      expect(prediction.isGood, isTrue);

      final nextDueDate = MaintenancePredictionService.addMonthsSafely(serviceDate, 3);
      expect(prediction.estimatedNextServiceDate, equals(nextDueDate));
    });

    // -------------------------------------------------------------
    // TEST 12: No data / Initial vehicle state
    // Kendaraan baru tanpa riwayat servis -> tetap punya jadwal awal berdasarkan odometer saat ini
    // -------------------------------------------------------------
    test('TEST 12: No data (New vehicle without service history has valid initial schedule)', () {
      final now = DateTime(2026, 6, 1);
      final newVehicle = VehicleModel(
        id: 'veh-new-001',
        brand: 'Yamaha',
        model: 'NMAX',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 1500,
        initialOdometer: 0,
        createdAt: now,
        updatedAt: now,
      );

      final newItem = VehicleMaintenanceModel(
        id: 'vm-new-001',
        vehicleId: newVehicle.id,
        maintenanceId: 'm-spark',
        itemName: 'Busi',
        itemCategory: 'Pengapian',
        healthPercentage: 100,
        lastServiceOdometer: 0,
        lastServiceDate: null,
        intervalKm: 8000,
        intervalMonth: 8,
        updatedAt: now,
      );

      final prediction = MaintenancePredictionService.predictItem(
        item: newItem,
        currentOdometer: newVehicle.currentOdometer,
        currentDate: now,
      );

      expect(prediction.nextServiceOdometer, equals(8000),
          reason: 'Next service is 0 + 8.000 = 8.000 KM');
      expect(prediction.remainingKm, equals(6500),
          reason: 'Remaining KM is 8.000 - 1.500 = 6.500 KM');
      expect(prediction.remainingDays, greaterThan(0));
      expect(prediction.whicheverComesFirstText, isNotEmpty);
      expect(prediction.status, isNot(equals('OVERDUE')));
      expect(prediction.formattedTotalRange, isNotEmpty);
    });
  });
}
