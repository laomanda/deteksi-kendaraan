import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ridecare/core/database/hive_boxes.dart';
import 'package:ridecare/core/database/hive_registrar.dart';
import 'package:ridecare/core/utils/date_formatter.dart';
import 'package:ridecare/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:ridecare/features/garage/presentation/controllers/active_vehicle_controller.dart';
import 'package:ridecare/features/maintenance/data/models/maintenance_item_model.dart';
import 'package:ridecare/features/maintenance/data/models/service_log_model.dart';
import 'package:ridecare/features/maintenance/data/models/service_record_model.dart';
import 'package:ridecare/features/maintenance/data/models/vehicle_maintenance_model.dart';
import 'package:ridecare/features/maintenance/data/repositories/maintenance_repository.dart';
import 'package:ridecare/features/maintenance/providers/maintenance_intelligence_providers.dart';
import 'package:ridecare/features/maintenance/providers/maintenance_prediction_providers.dart';
import 'package:ridecare/features/ride_tracking/data/models/gps_point_model.dart';
import 'package:ridecare/features/ride_tracking/data/models/ride_session_model.dart';
import 'package:ridecare/features/ride_tracking/data/repositories/ride_history_repository.dart';
import 'package:ridecare/features/ride_tracking/data/repositories/ride_repository.dart';
import 'package:ridecare/features/shared/providers/repository_providers.dart'
    hide maintenanceRepositoryProvider;
import 'package:ridecare/features/vehicle/data/models/vehicle_model.dart';
import 'package:ridecare/features/vehicle/data/repositories/vehicle_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late VehicleRepository vehicleRepository;
  late MaintenanceRepository maintenanceRepository;
  late RideRepository rideRepository;
  late RideHistoryRepository rideHistoryRepository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ridecare_dashboard_test_');
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
    rideRepository = RideRepository();
    rideHistoryRepository = RideHistoryRepository();
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

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(vehicleRepository),
        maintenanceRepositoryProvider.overrideWithValue(maintenanceRepository),
        rideRepositoryProvider.overrideWithValue(rideRepository),
        rideHistoryRepositoryProvider.overrideWithValue(rideHistoryRepository),
      ],
    );
  }

  group('RIDECARE DASHBOARD UNIT TEST SUITE (12/12)', () {
    // -------------------------------------------------------------
    // TEST 1: Vehicle tersedia -> Dashboard menampilkan vehicle
    // -------------------------------------------------------------
    test('TEST 1: Vehicle tersedia -> Dashboard menampilkan vehicle', () async {
      final now = DateTime(2026, 6, 1);
      final vehicle = VehicleModel(
        id: 'veh-dash-01',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 12565,
        createdAt: now,
        updatedAt: now,
      );

      await vehicleRepository.saveVehicle(vehicle);
      await vehicleRepository.setActiveVehicleId(vehicle.id);

      final container = createContainer();
      final active = container.read(activeVehicleProvider);

      expect(active, isNotNull);
      expect(active!.displayName, equals('Honda Beat'));
      expect(active.currentKilometer, equals(12565));

      final summary = container.read(dashboardSummaryProvider).value;
      expect(summary, isNotNull);
      expect(summary!.vehicle.displayName, equals('Honda Beat'));
    });

    // -------------------------------------------------------------
    // TEST 2: Vehicle tidak tersedia -> Empty state
    // -------------------------------------------------------------
    test('TEST 2: Vehicle tidak tersedia -> Empty state', () {
      final container = createContainer();
      final active = container.read(activeVehicleProvider);
      expect(active, isNull);

      final summary = container.read(dashboardSummaryProvider).value;
      expect(summary, isNull,
          reason: 'When no vehicle exists, summary is null to trigger empty state UI');
    });

    // -------------------------------------------------------------
    // TEST 3: Current odometer: 12.565 KM -> Dashboard: 12.565 KM
    // -------------------------------------------------------------
    test('TEST 3: Current odometer: 12.565 KM -> Dashboard: 12.565 KM', () async {
      final now = DateTime(2026, 6, 1);
      final vehicle = VehicleModel(
        id: 'veh-dash-03',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 12565,
        createdAt: now,
        updatedAt: now,
      );

      await vehicleRepository.saveVehicle(vehicle);
      await vehicleRepository.setActiveVehicleId(vehicle.id);

      final container = createContainer();
      final summary = container.read(dashboardSummaryProvider).value;

      expect(summary, isNotNull);
      expect(summary!.vehicle.currentOdometer, equals(12565));
      expect(DateFormatter.formatKm(summary.vehicle.currentKilometer), equals('12.565 km'));
    });

    // -------------------------------------------------------------
    // TEST 4: Maintenance OVERDUE -> Dashboard memprioritaskan OVERDUE
    // -------------------------------------------------------------
    test('TEST 4: Maintenance OVERDUE -> Dashboard memprioritaskan OVERDUE', () async {
      final now = DateTime(2026, 6, 1);
      final vehicle = VehicleModel(
        id: 'veh-dash-04',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 13100, // Exceeds 10.000 + 3.000
        createdAt: now,
        updatedAt: now,
      );

      await vehicleRepository.saveVehicle(vehicle);
      await vehicleRepository.setActiveVehicleId(vehicle.id);

      final overdueItem = VehicleMaintenanceModel(
        id: 'vm-overdue-01',
        vehicleId: vehicle.id,
        maintenanceId: 'm-oil',
        itemName: 'Oli Mesin',
        itemCategory: 'Mesin',
        healthPercentage: 0,
        lastServiceOdometer: 10000,
        lastServiceDate: DateTime(2026, 5, 1),
        intervalKm: 3000,
        intervalMonth: 3,
        updatedAt: now,
      );

      await maintenanceRepository.updateVehicleMaintenance(overdueItem);

      final container = createContainer();
      final summary = container.read(dashboardSummaryProvider).value;

      expect(summary, isNotNull);
      expect(summary!.overdueCount, greaterThan(0));
      expect(summary.status, equals('OVERDUE'),
          reason: 'Smart Priority rule: Status MUST be OVERDUE if any overdue item exists');
      expect(summary.isOverdue, isTrue);
      expect(summary.isGood, isFalse);
    });

    // -------------------------------------------------------------
    // TEST 5: Maintenance DUE SOON -> Next Maintenance menampilkan item tersebut
    // -------------------------------------------------------------
    test('TEST 5: Maintenance DUE SOON -> Next Maintenance menampilkan item tersebut', () async {
      final now = DateTime(2026, 6, 1);
      final vehicle = VehicleModel(
        id: 'veh-dash-05',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 12565, // Remaining 435 KM
        createdAt: now,
        updatedAt: now,
      );

      await vehicleRepository.saveVehicle(vehicle);
      await vehicleRepository.setActiveVehicleId(vehicle.id);

      final dueSoonItem = VehicleMaintenanceModel(
        id: 'vm-duesoon-01',
        vehicleId: vehicle.id,
        maintenanceId: 'm-oil',
        itemName: 'Oli Mesin',
        itemCategory: 'Mesin',
        healthPercentage: 15,
        lastServiceOdometer: 10000,
        lastServiceDate: DateTime.now().subtract(const Duration(days: 14)),
        intervalKm: 3000,
        intervalMonth: 3,
        updatedAt: now,
      );

      await maintenanceRepository.updateVehicleMaintenance(dueSoonItem);

      final container = createContainer();
      final summary = container.read(dashboardSummaryProvider).value;

      expect(summary, isNotNull);
      expect(summary!.dueSoonCount, equals(1));
      expect(summary.status, equals('DUE SOON'));
      expect(summary.isDueSoon, isTrue);
      expect(summary.mostUrgentPrediction, isNotNull);
      expect(summary.mostUrgentPrediction!.componentName, equals('Oli Mesin'));
      expect(summary.mostUrgentPrediction!.remainingKm, equals(435));
    });

    // -------------------------------------------------------------
    // TEST 6: Cost forecast tersedia -> Dashboard menampilkan range harga
    // -------------------------------------------------------------
    test('TEST 6: Cost forecast tersedia -> Dashboard menampilkan range harga', () async {
      final now = DateTime(2026, 6, 1);
      final vehicle = VehicleModel(
        id: 'veh-dash-06',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 12565,
        createdAt: now,
        updatedAt: now,
      );

      await vehicleRepository.saveVehicle(vehicle);
      await vehicleRepository.setActiveVehicleId(vehicle.id);

      final item = VehicleMaintenanceModel(
        id: 'vm-cost-01',
        vehicleId: vehicle.id,
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

      await maintenanceRepository.updateVehicleMaintenance(item);

      final container = createContainer();
      final summary = container.read(dashboardSummaryProvider).value;

      expect(summary, isNotNull);
      expect(summary!.formattedUpcomingCost, contains('Rp'));
      expect(summary.formattedUpcomingCost, contains('-'));
    });

    // -------------------------------------------------------------
    // TEST 7: Tidak ada cost data -> Graceful empty state
    // -------------------------------------------------------------
    test('TEST 7: Tidak ada cost data -> Graceful empty state', () async {
      final now = DateTime(2026, 6, 1);
      final vehicle = VehicleModel(
        id: 'veh-dash-07',
        brand: 'Yamaha',
        model: 'Mio',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 1000,
        createdAt: now,
        updatedAt: now,
      );

      await vehicleRepository.saveVehicle(vehicle);
      await vehicleRepository.setActiveVehicleId(vehicle.id);

      final container = createContainer();
      final summary = container.read(dashboardSummaryProvider).value;

      expect(summary, isNotNull);
      expect(summary!.formattedUpcomingCost, equals('Estimasi biaya belum tersedia'));
    });

    // -------------------------------------------------------------
    // TEST 8: Recent rides tersedia -> maksimal 3 ride terbaru
    // -------------------------------------------------------------
    test('TEST 8: Recent rides tersedia -> maksimal 3 ride terbaru', () async {
      final now = DateTime.now();
      final vehicle = VehicleModel(
        id: 'veh-dash-08',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 12565,
        createdAt: now,
        updatedAt: now,
      );

      await vehicleRepository.saveVehicle(vehicle);
      await vehicleRepository.setActiveVehicleId(vehicle.id);

      // Save 5 rides
      for (int i = 1; i <= 5; i++) {
        final ride = RideSessionModel(
          id: 'ride-seq-$i',
          vehicleId: vehicle.id,
          startTime: now.subtract(Duration(days: 6 - i)),
          endTime: now.subtract(Duration(days: 6 - i)).add(const Duration(minutes: 30)),
          totalDistanceKm: 10.0 * i,
          durationSeconds: 1800,
          averageSpeedKmh: 20.0,
          points: [],
        );
        await rideRepository.saveRideSession(ride);
      }

      final container = createContainer();
      final recentRides = container.read(recentRidesProvider);

      expect(recentRides.length, equals(3),
          reason: 'Recent rides card must show a maximum of 3 latest rides');
    });

    // -------------------------------------------------------------
    // TEST 9: Tidak ada ride -> Empty state
    // -------------------------------------------------------------
    test('TEST 9: Tidak ada ride -> Empty state', () async {
      final now = DateTime.now();
      final vehicle = VehicleModel(
        id: 'veh-dash-09',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 10000,
        createdAt: now,
        updatedAt: now,
      );

      await vehicleRepository.saveVehicle(vehicle);
      await vehicleRepository.setActiveVehicleId(vehicle.id);

      final container = createContainer();
      final recentRides = container.read(recentRidesProvider);
      final monthlyStats = container.read(monthlyRideStatsProvider);

      expect(recentRides, isEmpty);
      expect(monthlyStats.hasActivity, isFalse);
      expect(monthlyStats.tripCount, equals(0));
      expect(monthlyStats.totalDistanceKm, equals(0.0));
    });

    // -------------------------------------------------------------
    // TEST 10: Ride selesai -> Dashboard reactive terhadap odometer terbaru
    // -------------------------------------------------------------
    test('TEST 10: Ride selesai -> Dashboard reactive terhadap odometer terbaru', () async {
      final now = DateTime.now();
      final vehicle = VehicleModel(
        id: 'veh-dash-10',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 12500,
        createdAt: now,
        updatedAt: now,
      );

      await vehicleRepository.saveVehicle(vehicle);
      await vehicleRepository.setActiveVehicleId(vehicle.id);

      final item = VehicleMaintenanceModel(
        id: 'vm-reactive-01',
        vehicleId: vehicle.id,
        maintenanceId: 'm-oil',
        itemName: 'Oli Mesin',
        itemCategory: 'Mesin',
        healthPercentage: 17,
        lastServiceOdometer: 10000,
        lastServiceDate: DateTime.now().subtract(const Duration(days: 14)),
        intervalKm: 3000,
        intervalMonth: 3,
        updatedAt: now,
      );

      await maintenanceRepository.updateVehicleMaintenance(item);

      final container = createContainer();

      // Before ride: 12.500 KM -> remaining: 500 KM
      var summary = container.read(dashboardSummaryProvider).value;
      expect(summary!.vehicle.currentOdometer, equals(12500));
      expect(summary.mostUrgentPrediction!.remainingKm, equals(500));

      // Simulate ride finished with +65 KM
      final ride = RideSessionModel(
        id: 'ride-update-10',
        vehicleId: vehicle.id,
        startTime: now.subtract(const Duration(minutes: 45)),
        endTime: now,
        totalDistanceKm: 65.0,
        durationSeconds: 2700,
        averageSpeedKmh: 35.0,
        points: [],
      );

      await rideRepository.processRideCompletion(
        session: ride,
        vehicleRepository: vehicleRepository,
      );

      // Refresh active vehicle provider in container
      container.read(activeVehicleProvider.notifier).refresh();

      summary = container.read(dashboardSummaryProvider).value;
      expect(summary!.vehicle.currentOdometer, equals(12565));
      expect(summary.mostUrgentPrediction!.remainingKm, equals(435));
      expect(summary.status, equals('DUE SOON'));
    });

    // -------------------------------------------------------------
    // TEST 11: Service dicatat -> Health dan next maintenance berubah
    // -------------------------------------------------------------
    test('TEST 11: Service dicatat -> Health dan next maintenance berubah', () async {
      final now = DateTime.now();
      final vehicle = VehicleModel(
        id: 'veh-dash-11',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 12565,
        createdAt: now,
        updatedAt: now,
      );

      await vehicleRepository.saveVehicle(vehicle);
      await vehicleRepository.setActiveVehicleId(vehicle.id);

      final item = VehicleMaintenanceModel(
        id: 'vm-serviced-01',
        vehicleId: vehicle.id,
        maintenanceId: 'm-oil',
        itemName: 'Oli Mesin',
        itemCategory: 'Mesin',
        healthPercentage: 15,
        lastServiceOdometer: 10000,
        lastServiceDate: DateTime.now().subtract(const Duration(days: 14)),
        intervalKm: 3000,
        intervalMonth: 3,
        updatedAt: now,
      );

      await maintenanceRepository.updateVehicleMaintenance(item);

      final container = createContainer();
      var summary = container.read(dashboardSummaryProvider).value;
      expect(summary!.status, equals('DUE SOON'));

      // Record service
      final record = ServiceRecordModel(
        id: 'rec-dash-11',
        vehicleId: vehicle.id,
        maintenanceId: item.maintenanceId,
        maintenanceName: item.itemName,
        serviceDate: now,
        odometer: 12565,
        cost: 80000,
        createdAt: now,
      );

      await maintenanceRepository.addServiceRecord(record);

      // Invalidate and refresh container providers
      container.invalidate(vehicleMaintenanceProvider(vehicle.id));
      container.invalidate(maintenancePredictionProvider(vehicle.id));
      container.invalidate(upcomingMaintenanceProvider(vehicle.id));
      container.invalidate(maintenanceHealthProvider(vehicle.id));
      container.invalidate(dashboardSummaryProvider);

      summary = container.read(dashboardSummaryProvider).value;
      expect(summary!.status, equals('GOOD'));
      expect(summary.mostUrgentPrediction!.remainingKm, equals(3000));
      expect(summary.mostUrgentPrediction!.nextServiceOdometer, equals(15565));
      expect(summary.dueSoonCount, equals(0));
    });

    // -------------------------------------------------------------
    // TEST 12: Offline -> Dashboard tetap dapat digunakan dari Hive
    // -------------------------------------------------------------
    test('TEST 12: Offline -> Dashboard tetap dapat digunakan dari Hive', () async {
      final now = DateTime.now();
      final vehicle = VehicleModel(
        id: 'veh-dash-offline',
        brand: 'Honda',
        model: 'Vario 160',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 15000,
        createdAt: now,
        updatedAt: now,
      );

      await vehicleRepository.saveVehicle(vehicle);
      await vehicleRepository.setActiveVehicleId(vehicle.id);

      final items = await maintenanceRepository.getVehicleMaintenance(
        vehicle.id,
        vehicleType: 'motorcycle',
        currentOdometer: vehicle.currentOdometer,
      );

      expect(items, isNotEmpty);

      // Add 1 ride session
      final ride = RideSessionModel(
        id: 'ride-offline-1',
        vehicleId: vehicle.id,
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now,
        totalDistanceKm: 25.5,
        durationSeconds: 3600,
        averageSpeedKmh: 25.5,
        points: [],
      );
      await rideRepository.saveRideSession(ride);

      // Completely offline container
      final container = createContainer();

      final summary = container.read(dashboardSummaryProvider).value;
      final recentRides = container.read(recentRidesProvider);
      final monthlyStats = container.read(monthlyRideStatsProvider);

      expect(summary, isNotNull);
      expect(summary!.vehicle.displayName, equals('Honda Vario 160'));
      expect(summary.vehicle.currentKilometer, equals(15000));
      expect(recentRides.length, equals(1));
      expect(recentRides.first.totalDistanceKm, equals(25.5));
      expect(monthlyStats.hasActivity, isTrue);
      expect(monthlyStats.tripCount, equals(1));
    });
  });
}
