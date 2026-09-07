import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ridecare/core/database/hive_boxes.dart';
import 'package:ridecare/core/database/hive_registrar.dart';
import 'package:ridecare/core/sync/sync_manager.dart';
import 'package:ridecare/features/maintenance/data/models/maintenance_item_model.dart';
import 'package:ridecare/features/maintenance/data/models/service_log_model.dart';
import 'package:ridecare/features/maintenance/data/models/vehicle_maintenance_model.dart';
import 'package:ridecare/features/maintenance/data/repositories/maintenance_repository.dart';
import 'package:ridecare/features/maintenance/domain/health_calculation_service.dart';
import 'package:ridecare/features/ride_tracking/data/models/gps_point_model.dart';
import 'package:ridecare/features/ride_tracking/data/models/ride_session_model.dart';
import 'package:ridecare/features/ride_tracking/data/repositories/ride_repository.dart';
import 'package:ridecare/features/vehicle/data/models/vehicle_model.dart';
import 'package:ridecare/features/vehicle/data/repositories/vehicle_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late VehicleRepository vehicleRepository;
  late MaintenanceRepository maintenanceRepository;
  late RideRepository rideRepository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ridecare_integration_test_');
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

  group('RIDE TRACKING -> ODOMETER -> MAINTENANCE INTEGRATION TESTS', () {
    // -------------------------------------------------------------
    // TEST 1: Initial 12.500 KM + Ride 65 KM -> Expected 12.565 KM
    // -------------------------------------------------------------
    test('TEST 1: Odometer otomatis bertambah saat ride selesai (12.500 KM + 65 KM -> 12.565 KM)', () async {
      final beat = VehicleModel(
        id: 'beat-test-1',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        initialOdometer: 10000,
        currentOdometer: 12500,
      );
      await vehicleRepository.createVehicle(beat);

      final session = RideSessionModel(
        id: 'ride-session-1',
        vehicleId: beat.id,
        startTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 24)),
        endTime: DateTime.now(),
        totalDistanceKm: 65.0,
        durationSeconds: 5040,
        averageSpeedKmh: 46.4,
        points: [],
      );

      final result = await rideRepository.processRideCompletion(
        session: session,
        vehicleRepository: vehicleRepository,
      );

      expect(result.previousOdometer, equals(12500));
      expect(result.newOdometer, equals(12565));
      expect(result.wasAlreadyProcessed, isFalse);

      final updatedVehicle = vehicleRepository.getVehicleById(beat.id);
      expect(updatedVehicle, isNotNull);
      expect(updatedVehicle!.currentOdometer, equals(12565));
    });

    // -------------------------------------------------------------
    // TEST 2: Maintenance Recalculation (Last 10.000 KM, Interval 3.000 KM, Ride 65 KM -> Remaining 435 KM)
    // -------------------------------------------------------------
    test('TEST 2: Maintenance otomatis dihitung ulang setelah ride (Remaining: 435 KM, Status: DUE SOON)', () async {
      final beat = VehicleModel(
        id: 'beat-test-2',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        initialOdometer: 10000,
        currentOdometer: 12500,
      );
      await vehicleRepository.createVehicle(beat);

      // Ambil item maintenance untuk kendaraan beat melalui repository
      final items = await maintenanceRepository.getVehicleMaintenance(
        beat.id,
        vehicleType: beat.vehicleType,
        currentOdometer: beat.currentOdometer,
      );
      expect(items, isNotEmpty);

      // Sesi servis terakhir tercatat di 10.000 KM untuk Oli Mesin (Interval 3.000 KM)
      final oilItem = VehicleMaintenanceModel(
        id: 'vm-oil-1',
        vehicleId: beat.id,
        maintenanceId: 'engine_oil',
        itemName: 'Oli Mesin',
        intervalKm: 3000,
        intervalMonth: 3,
        lastServiceOdometer: 10000,
        lastServiceDate: DateTime.now().subtract(const Duration(days: 30)),
      );


      // 1. Sebelum ride (Odometer 12.500 KM): Remaining = 500 KM
      final preHealth = HealthCalculationService.calculateItemHealth(
        item: oilItem,
        currentOdometer: beat.currentOdometer,
        defaultIntervalKm: oilItem.intervalKm!,
      );
      expect(preHealth.remainingKm, equals(500));
      expect(preHealth.status, equals('DUE SOON')); // <= 25% dari 3000 (750 KM)

      // 2. User melakukan ride sejauh 65 KM
      final session = RideSessionModel(
        id: 'ride-session-2',
        vehicleId: beat.id,
        startTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 24)),
        endTime: DateTime.now(),
        totalDistanceKm: 65.0,
        durationSeconds: 5040,
        averageSpeedKmh: 46.4,
        points: [],
      );

      final result = await rideRepository.processRideCompletion(
        session: session,
        vehicleRepository: vehicleRepository,
      );
      expect(result.newOdometer, equals(12565));

      // 3. Setelah ride (Odometer 12.565 KM): Remaining = 3.000 - (12.565 - 10.000) = 435 KM
      final postHealth = HealthCalculationService.calculateItemHealth(
        item: oilItem,
        currentOdometer: result.newOdometer,
        defaultIntervalKm: oilItem.intervalKm!,
      );
      expect(postHealth.usedKm, equals(2565));
      expect(postHealth.remainingKm, equals(435));
      expect(postHealth.status, equals('DUE SOON'));
      expect(postHealth.healthPercentage, closeTo(14.5, 0.1));
    });

    // -------------------------------------------------------------
    // TEST 3: Offline Ride (Internet OFF)
    // -------------------------------------------------------------
    test('TEST 3: Mode Offline (Internet OFF) -> Ride tersimpan, jarak terhitung, odometer bertambah, maintenance terhitung ulang', () async {
      // Offline: Supabase tidak terinisialisasi
      final vario = VehicleModel(
        id: 'vario-offline-1',
        brand: 'Honda',
        model: 'Vario 160',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 5000,
      );
      await vehicleRepository.createVehicle(vario);

      // GPS Points offline
      final List<GpsPointModel> points = [
        GpsPointModel(
          latitude: -6.2000,
          longitude: 106.8166,
          altitude: 12.0,
          speed: 8.5,
          timestamp: DateTime.now(),
        ),
        GpsPointModel(
          latitude: -6.2088,
          longitude: 106.8456,
          altitude: 14.0,
          speed: 9.0,
          timestamp: DateTime.now().add(const Duration(minutes: 5)),
        ),
      ];

      final session = RideSessionModel(
        id: 'ride-offline-session',
        vehicleId: vario.id,
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        endTime: DateTime.now(),
        totalDistanceKm: 15.4, // 15.4 KM
        durationSeconds: 1800,
        averageSpeedKmh: 30.8,
        points: points,
      );


      final result = await rideRepository.processRideCompletion(
        session: session,
        vehicleRepository: vehicleRepository,
      );

      // Ride tersimpan di Hive local box
      expect(HiveRegistrar.ridesBox.containsKey(session.id), isTrue);
      expect(HiveRegistrar.ridesBox.get(session.id)!.totalDistanceKm, equals(15.4));

      // Odometer kendaraan ter-update di Hive lokal (5000 + 15 = 5015)
      expect(result.newOdometer, equals(5015));
      final savedVehicle = HiveRegistrar.vehiclesBox.get(vario.id);
      expect(savedVehicle!.currentOdometer, equals(5015));

      // Maintenance item tetap dapat dihitung deterministik offline
      final maintenanceItem = VehicleMaintenanceModel(
        id: 'vm-filter-1',
        vehicleId: vario.id,
        maintenanceId: 'air_filter',
        itemName: 'Filter Udara',
        intervalKm: 8000,
        lastServiceOdometer: 0,
      );

      final health = HealthCalculationService.calculateItemHealth(
        item: maintenanceItem,
        currentOdometer: savedVehicle.currentOdometer,
        defaultIntervalKm: 8000,
      );
      expect(health.usedKm, equals(5015));
      expect(health.remainingKm, equals(2985));
      expect(health.status, equals('GOOD'));
    });

    // -------------------------------------------------------------
    // TEST 4: Two Rides Offline (Initial 10.000 KM + 50 KM + 30 KM -> Expected 10.080 KM)
    // -------------------------------------------------------------
    test('TEST 4: Dua perjalanan offline berturut-turut (10.000 KM + 50 KM + 30 KM -> 10.080 KM, BUKAN 10.160 KM)', () async {
      final nmax = VehicleModel(
        id: 'nmax-offline-two-rides',
        brand: 'Yamaha',
        model: 'NMAX',
        vehicleType: 'motorcycle',
        year: 2023,
        currentOdometer: 10000,
      );
      await vehicleRepository.createVehicle(nmax);

      // Ride A: 50 KM
      final rideA = RideSessionModel(
        id: 'ride-A-50km',
        vehicleId: nmax.id,
        startTime: DateTime.now().subtract(const Duration(hours: 3)),
        endTime: DateTime.now().subtract(const Duration(hours: 2)),
        totalDistanceKm: 50.0,
        durationSeconds: 3600,
        averageSpeedKmh: 50.0,
        points: [],
      );

      final resA = await rideRepository.processRideCompletion(
        session: rideA,
        vehicleRepository: vehicleRepository,
      );
      expect(resA.newOdometer, equals(10050));

      // Ride B: 30 KM
      final rideB = RideSessionModel(
        id: 'ride-B-30km',
        vehicleId: nmax.id,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
        totalDistanceKm: 30.0,
        durationSeconds: 2400,
        averageSpeedKmh: 45.0,
        points: [],
      );

      final resB = await rideRepository.processRideCompletion(
        session: rideB,
        vehicleRepository: vehicleRepository,
      );
      expect(resB.newOdometer, equals(10080));

      // Verifikasi akhir di Hive: 10.080 KM (bukan 10.160 KM)
      final finalVehicle = vehicleRepository.getVehicleById(nmax.id);
      expect(finalVehicle!.currentOdometer, equals(10080));
    });

    // -------------------------------------------------------------
    // TEST 5: Duplicate Processing / Idempotency
    // -------------------------------------------------------------
    test('TEST 5: Idempotency - Sesi ride yang sama diproses dua kali, odometer hanya bertambah satu kali', () async {
      final aerox = VehicleModel(
        id: 'aerox-idempotency',
        brand: 'Yamaha',
        model: 'Aerox',
        vehicleType: 'motorcycle',
        year: 2023,
        currentOdometer: 12500,
      );
      await vehicleRepository.createVehicle(aerox);

      final session = RideSessionModel(
        id: 'ride-duplicate-test',
        vehicleId: aerox.id,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
        totalDistanceKm: 65.0,
        durationSeconds: 3600,
        averageSpeedKmh: 65.0,
        points: [],
      );

      // Eksekusi pertama: 12.500 -> 12.565 KM
      final firstExecution = await rideRepository.processRideCompletion(
        session: session,
        vehicleRepository: vehicleRepository,
      );
      expect(firstExecution.wasAlreadyProcessed, isFalse);
      expect(firstExecution.newOdometer, equals(12565));

      // Eksekusi kedua (misal: user re-open atau sync ulang): ODOMETER TIDAK BOLEH BERUBAH
      final secondExecution = await rideRepository.processRideCompletion(
        session: session,
        vehicleRepository: vehicleRepository,
      );
      expect(secondExecution.wasAlreadyProcessed, isTrue);
      expect(secondExecution.newOdometer, equals(12565));

      // Nilai di Hive tetap 12.565 KM (BUKAN 12.630 KM)
      final checkedVehicle = vehicleRepository.getVehicleById(aerox.id);
      expect(checkedVehicle!.currentOdometer, equals(12565));
    });

    // -------------------------------------------------------------
    // TEST 6: Supabase Sync Payload Consistency
    // -------------------------------------------------------------
    test('TEST 6: Konsistensi data untuk sinkronisasi ke Supabase (Vehicles, Ride Sessions, Maintenance Records)', () async {
      final beat = VehicleModel(
        id: 'beat-sync-test',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 12565,
      );
      await HiveRegistrar.vehiclesBox.put(beat.id, beat);

      final session = RideSessionModel(
        id: 'ride-sync-test',
        vehicleId: beat.id,
        startTime: DateTime.parse('2026-09-07T10:00:00.000Z'),
        endTime: DateTime.parse('2026-09-07T11:24:00.000Z'),
        totalDistanceKm: 65.4,
        durationSeconds: 5040,
        averageSpeedKmh: 46.7,
        points: [],
      );
      await HiveRegistrar.ridesBox.put(session.id, session);

      // Verifikasi konsistensi struktur payload sync
      final vehicleJson = beat.toJson();
      expect(vehicleJson['id'], equals('beat-sync-test'));
      expect(vehicleJson['current_odometer'], equals(12565));
      expect(vehicleJson['brand'], equals('Honda'));
      expect(vehicleJson['vehicle_type'], equals('motorcycle'));

      final rideJson = session.toJson();
      expect(rideJson['id'], equals('ride-sync-test'));
      expect(rideJson['vehicleId'], equals('beat-sync-test'));
      expect(rideJson['totalDistanceKm'], equals(65.4));
      expect(rideJson['durationSeconds'], equals(5040));

      final syncManager = SyncManager();
      // Saat offline / uninitialized, SyncManager mengembalikan false tanpa crash
      final result = await syncManager.uploadPendingChanges();
      expect(result.success, isFalse);
    });

    // -------------------------------------------------------------
    // TEST 7: Restart App after Offline Ride (Hive Persistence)
    // -------------------------------------------------------------
    test('TEST 7: Restart Aplikasi setelah ride offline -> Odometer terbaru & idempotency tetap persisten dari Hive', () async {
      final pcx = VehicleModel(
        id: 'pcx-restart-test',
        brand: 'Honda',
        model: 'PCX 160',
        vehicleType: 'motorcycle',
        year: 2024,
        currentOdometer: 8000,
      );
      await vehicleRepository.createVehicle(pcx);

      final session = RideSessionModel(
        id: 'ride-restart-session',
        vehicleId: pcx.id,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
        totalDistanceKm: 42.0,
        durationSeconds: 3600,
        averageSpeedKmh: 42.0,
        points: [],
      );

      await rideRepository.processRideCompletion(
        session: session,
        vehicleRepository: vehicleRepository,
      );

      // Simulasi tutup dan restart aplikasi (tutup box Hive)
      await Hive.close();

      // Buka kembali box Hive dari direktori yang sama
      Hive.init(tempDir.path);
      await Hive.openBox<VehicleModel>(HiveBoxes.vehicles);
      await Hive.openBox<MaintenanceItemModel>(HiveBoxes.maintenance);
      await Hive.openBox<ServiceLogModel>(HiveBoxes.serviceHistory);
      await Hive.openBox<RideSessionModel>(HiveBoxes.rides);
      await Hive.openBox<dynamic>(HiveBoxes.settings);

      final reloadedVehicleRepo = VehicleRepository();
      final reloadedRideRepo = RideRepository();

      // 1. Odometer terbaru tetap tersedia
      final persistedVehicle = reloadedVehicleRepo.getVehicleById(pcx.id);
      expect(persistedVehicle, isNotNull);
      expect(persistedVehicle!.currentOdometer, equals(8042));

      // 2. Sesi ride tetap ada di local box
      expect(HiveRegistrar.ridesBox.containsKey(session.id), isTrue);

      // 3. Mekanisme idempotency tetap mengingat bahwa sesi ini sudah pernah diproses
      expect(reloadedRideRepo.isRideProcessedForOdometer(session.id), isTrue);

      // 4. Jika coba diproses lagi setelah restart aplikasi, odometer tetap tidak bertambah ganda
      final reloadedSession = HiveRegistrar.ridesBox.get(session.id)!;
      final duplicateAttempt = await reloadedRideRepo.processRideCompletion(
        session: reloadedSession,
        vehicleRepository: reloadedVehicleRepo,
      );
      expect(duplicateAttempt.wasAlreadyProcessed, isTrue);
      expect(duplicateAttempt.newOdometer, equals(8042));
    });
  });
}

