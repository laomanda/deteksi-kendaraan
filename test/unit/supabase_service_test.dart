import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ridecare/core/database/hive_boxes.dart';
import 'package:ridecare/core/database/hive_registrar.dart';
import 'package:ridecare/core/supabase/supabase_config.dart';
import 'package:ridecare/core/supabase/supabase_service.dart';
import 'package:ridecare/core/sync/sync_manager.dart';
import 'package:ridecare/features/garage/data/models/vehicle_model.dart';
import 'package:ridecare/features/garage/data/repositories/vehicle_repository.dart';
import 'package:ridecare/features/maintenance/data/repositories/maintenance_repository.dart';
import 'package:ridecare/features/ride_tracking/data/models/ride_session_model.dart';
import 'package:ridecare/features/ride_tracking/data/repositories/ride_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Setup in-memory / temporary Hive box for unit tests
    Hive.init('./test_hive_supabase');
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(VehicleModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(RideSessionModelAdapter());

    await Hive.openBox<VehicleModel>(HiveBoxes.vehicles);
    await Hive.openBox<RideSessionModel>(HiveBoxes.rides);
    await Hive.openBox<dynamic>(HiveBoxes.settings);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('SupabaseConfig & Constants Tests', () {
    test('Default URL and anonKey fallback are correctly configured', () {
      expect(SupabaseConfig.fallbackUrl, 'https://cmueermihksabkdkqpup.supabase.co');
      expect(SupabaseConfig.fallbackAnonKey, 'sb_publishable_NxXWu7hSOj5tCQoH9rmOhw_n3Rn88wz');
      expect(SupabaseConfig.url, isNotEmpty);
      expect(SupabaseConfig.anonKey, isNotEmpty);
    });
  });

  group('VehicleRepository getVehicles and createVehicle', () {
    test('Can save and retrieve vehicles through repository pattern', () async {
      final repo = VehicleRepository();
      final vehicle = VehicleModel(
        id: 'test-vehicle-beat',
        vehicleType: 'motorcycle',
        brand: 'Honda',
        model: 'Beat',
        year: 2024,
        currentKilometer: 0.0,
        createdAt: DateTime.now(),
      );

      await repo.createVehicle(vehicle);
      final list = await repo.getVehicles();

      expect(list.any((v) => v.id == 'test-vehicle-beat'), isTrue);
      final fetched = list.firstWhere((v) => v.id == 'test-vehicle-beat');
      expect(fetched.brand, 'Honda');
      expect(fetched.model, 'Beat');
      expect(fetched.year, 2024);
    });
  });

  group('MaintenanceRepository catalog & history fallback', () {
    test('Returns graceful fallback when remote connection is unavailable', () async {
      final repo = MaintenanceRepository();
      final catalog = await repo.getMaintenanceCatalog();
      expect(catalog, isA<List<Map<String, dynamic>>>());
    });
  });

  group('RideRepository offline-first save', () {
    test('Saves ride session locally even if remote is offline', () async {
      final repo = RideRepository();
      final session = RideSessionModel(
        id: 'test-ride-session-1',
        vehicleId: 'test-vehicle-beat',
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        endTime: DateTime.now(),
        totalDistanceKm: 12.5,
        durationSeconds: 1800,
        averageSpeedKmh: 25.0,
        points: [],
      );

      await repo.saveRideSession(session);
      expect(HiveRegistrar.ridesBox.containsKey('test-ride-session-1'), isTrue);
    });
  });

  group('SupabaseService & SyncManager Initialization Tests', () {
    test('SupabaseService checkConnection returns false when uninitialized', () async {
      final service = SupabaseService();
      final connected = await service.checkConnection();
      expect(connected, isFalse);
    });

    test('SyncManager handles uninitialized state gracefully', () async {
      final syncManager = SyncManager();
      final uploadResult = await syncManager.uploadPendingChanges();
      expect(uploadResult.success, isFalse);
      expect(uploadResult.message, contains('not initialized'));

      final downloadResult = await syncManager.downloadLatestData();
      expect(downloadResult.success, isFalse);
      expect(downloadResult.message, contains('not initialized'));
    });
  });
}
