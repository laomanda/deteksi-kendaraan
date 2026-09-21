import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ridecare/core/database/hive_boxes.dart';
import 'package:ridecare/core/database/hive_registrar.dart';
import 'package:ridecare/features/maintenance/data/models/maintenance_item_model.dart';
import 'package:ridecare/features/maintenance/data/models/service_log_model.dart';
import 'package:ridecare/features/maintenance/data/models/vehicle_maintenance_model.dart';
import 'package:ridecare/features/maintenance/domain/health_calculation_service.dart';
import 'package:ridecare/features/maintenance/domain/maintenance_prediction_service.dart';
import 'package:ridecare/features/vehicle/domain/vehicle_intelligence_service.dart';
import 'package:ridecare/features/ride_tracking/data/models/gps_point_model.dart';
import 'package:ridecare/features/ride_tracking/data/models/ride_session_model.dart';
import 'package:ridecare/features/vehicle/data/models/vehicle_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

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

  group('RIDE TRACKING & MAINTENANCE HEALTH SYNCHRONIZATION AUDIT TESTS', () {
    // -----------------------------------------------------------------------
    // TEST 1: Baseline Odometer Anchoring for AutoPrediction (No History)
    // -----------------------------------------------------------------------
    test('TEST 1: AutoPrediction anchors baseline odometer so health degrades with distance', () {
      final vehicle = VehicleModel(
        id: 'beat-sync-1',
        brand: 'Honda',
        model: 'Beat Deluxe',
        vehicleType: 'motorcycle',
        year: 2024,
        initialOdometer: 10000,
        currentOdometer: 10000,
        initialCondition: 'auto_prediction',
      );

      // Generate items using VehicleIntelligenceService
      final items = VehicleIntelligenceService.generateMaintenanceItems(
        vehicle: vehicle,
        initialCondition: VehicleInitialCondition.autoPrediction,
      );

      final oilItem = items.firstWhere((it) => it.maintenanceId.contains('oil') || it.itemName?.contains('Oli') == true);
      expect(oilItem.lastServiceOdometer, equals(0), reason: 'AutoPrediction has no recorded service history');
      expect(oilItem.hasServiceHistory, isFalse);

      // Pre-ride check at 10.000 KM
      final preHealth = HealthCalculationService.calculateItemHealth(
        item: oilItem,
        currentOdometer: 10000,
        defaultIntervalKm: oilItem.intervalKm ?? 3000,
        vehicleInitialOdometer: vehicle.initialOdometer,
      );
      expect(preHealth.usedKm, equals(0));
      expect(preHealth.remainingKm, equals(3000));
      expect(preHealth.healthPercentage, equals(100.0));
      expect(preHealth.status, equals('GOOD'));

      // Ride 75 KM -> Odometer becomes 10.075 KM
      final postHealth = HealthCalculationService.calculateItemHealth(
        item: oilItem,
        currentOdometer: 10075,
        defaultIntervalKm: oilItem.intervalKm ?? 3000,
        vehicleInitialOdometer: vehicle.initialOdometer,
      );
      expect(postHealth.usedKm, equals(75), reason: 'Used KM must increase by the exact ride distance');
      expect(postHealth.remainingKm, equals(2925), reason: 'Remaining KM must decrease by the exact ride distance');
      expect(postHealth.healthPercentage, equals(97.5));
      expect(postHealth.status, equals('GOOD'));

      // Predictions should also reflect the decrease
      final prediction = MaintenancePredictionService.predictItem(
        item: oilItem,
        currentOdometer: 10075,
        vehicleInitialOdometer: vehicle.initialOdometer,
      );
      expect(prediction.usedKm, equals(75));
      expect(prediction.remainingKm, equals(2925));
    });

    // -----------------------------------------------------------------------
    // TEST 2: Affected Service Status Sort Priority in Ride Completion Dialog
    // -----------------------------------------------------------------------
    test('TEST 2: Dialog priority sort prioritizes truly affected km-based items over time-only battery', () {
      final itemAki = VehicleMaintenanceModel(
        id: 'vm-aki',
        vehicleId: 'v1',
        maintenanceId: 'battery',
        itemName: 'Aki',
        itemCategory: 'battery',
        intervalKm: 0, // Time-only item
        intervalMonth: 24,
        hasServiceHistory: false,
        lastServiceOdometer: 0,
      );

      final itemOli = VehicleMaintenanceModel(
        id: 'vm-oli',
        vehicleId: 'v1',
        maintenanceId: 'engine_oil',
        itemName: 'Oli Mesin',
        itemCategory: 'oil',
        intervalKm: 3000,
        intervalMonth: 3,
        hasServiceHistory: false,
        lastServiceOdometer: 10000,
      );

      final itemBusi = VehicleMaintenanceModel(
        id: 'vm-busi',
        vehicleId: 'v1',
        maintenanceId: 'spark_plug',
        itemName: 'Busi',
        itemCategory: 'ignition',
        intervalKm: 8000,
        intervalMonth: 12,
        hasServiceHistory: false,
        lastServiceOdometer: 10000,
      );

      final healthAki = HealthCalculationService.calculateItemHealth(
        item: itemAki,
        currentOdometer: 10100,
        defaultIntervalKm: 0,
      );

      final healthOli = HealthCalculationService.calculateItemHealth(
        item: itemOli,
        currentOdometer: 10100,
        defaultIntervalKm: 3000,
      );

      final healthBusi = HealthCalculationService.calculateItemHealth(
        item: itemBusi,
        currentOdometer: 10100,
        defaultIntervalKm: 8000,
      );

      // Verify health properties
      expect(healthAki.remainingKm, equals(0), reason: 'Time-only item has 0 remaining km');
      expect(healthAki.healthPercentage, equals(100.0));
      expect(healthOli.remainingKm, equals(2900));
      expect(healthBusi.remainingKm, equals(7900));

      final allHealthItems = [healthAki, healthOli, healthBusi];

      // Simulate the updated dialog sorting algorithm
      final kmItems = allHealthItems.where((it) => (it.item.intervalKm ?? 0) > 0).toList();
      final targetItems = kmItems.isNotEmpty ? kmItems : allHealthItems;

      targetItems.sort((a, b) {
        final priorityWeight = {'OVERDUE': 0, 'DUE SOON': 1, 'GOOD': 2};
        final wA = priorityWeight[a.status] ?? 3;
        final wB = priorityWeight[b.status] ?? 3;
        if (wA != wB) return wA.compareTo(wB);

        if (a.healthPercentage != b.healthPercentage) {
          return a.healthPercentage.compareTo(b.healthPercentage);
        }
        return a.remainingKm.compareTo(b.remainingKm);
      });

      final mostUrgent = targetItems.firstOrNull;
      expect(mostUrgent, isNotNull);
      expect(mostUrgent!.item.itemName, equals('Oli Mesin'),
          reason: 'Oli Mesin must be chosen as most affected/urgent, NOT Aki');
      expect(mostUrgent.remainingKm, equals(2900));
      expect(mostUrgent.status, equals('GOOD'));
    });

    // -----------------------------------------------------------------------
    // TEST 3: Due Soon / Overdue Component Takes Precedence in Dialog
    // -----------------------------------------------------------------------
    test('TEST 3: DUE SOON or OVERDUE component is prioritized in completion dialog', () {
      final itemRem = VehicleMaintenanceModel(
        id: 'vm-rem',
        vehicleId: 'v1',
        maintenanceId: 'brake_pads',
        itemName: 'Kampas Rem',
        intervalKm: 3000,
        hasServiceHistory: true,
        lastServiceOdometer: 7200,
      );

      final itemOli = VehicleMaintenanceModel(
        id: 'vm-oli',
        vehicleId: 'v1',
        maintenanceId: 'engine_oil',
        itemName: 'Oli Mesin',
        intervalKm: 3000,
        hasServiceHistory: true,
        lastServiceOdometer: 9500,
      );

      // At current odometer 10.000 KM:
      // Kampas Rem: used = 2.800 KM, remaining = 200 KM (<= 25% interval) -> DUE SOON
      // Oli Mesin: used = 500 KM, remaining = 2.500 KM -> GOOD
      final healthRem = HealthCalculationService.calculateItemHealth(
        item: itemRem,
        currentOdometer: 10000,
        defaultIntervalKm: 3000,
      );

      final healthOli = HealthCalculationService.calculateItemHealth(
        item: itemOli,
        currentOdometer: 10000,
        defaultIntervalKm: 3000,
      );

      expect(healthRem.status, equals('DUE SOON'));
      expect(healthOli.status, equals('GOOD'));

      final items = [healthOli, healthRem];
      final kmItems = items.where((it) => (it.item.intervalKm ?? 0) > 0).toList();
      final targetItems = kmItems.isNotEmpty ? kmItems : items;

      targetItems.sort((a, b) {
        final priorityWeight = {'OVERDUE': 0, 'DUE SOON': 1, 'GOOD': 2};
        final wA = priorityWeight[a.status] ?? 3;
        final wB = priorityWeight[b.status] ?? 3;
        if (wA != wB) return wA.compareTo(wB);

        if (a.healthPercentage != b.healthPercentage) {
          return a.healthPercentage.compareTo(b.healthPercentage);
        }
        return a.remainingKm.compareTo(b.remainingKm);
      });

      final mostUrgent = targetItems.firstOrNull;
      expect(mostUrgent, isNotNull);
      expect(mostUrgent!.item.itemName, equals('Kampas Rem'));
      expect(mostUrgent.status, equals('DUE SOON'));
      expect(mostUrgent.userFacingStatusLabel, equals('Mendekati jadwal perawatan'));
    });
  });
}
