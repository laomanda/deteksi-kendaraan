import 'package:flutter/foundation.dart';
import '../../features/garage/data/models/vehicle_model.dart';
import '../../features/maintenance/data/models/service_log_model.dart';
import '../../features/ride_tracking/data/models/ride_session_model.dart';
import '../database/hive_registrar.dart';
import '../supabase/supabase_config.dart';
import '../supabase/supabase_service.dart';

class SyncManager {
  final SupabaseService _supabaseService;

  SyncManager([SupabaseService? supabaseService])
      : _supabaseService = supabaseService ?? SupabaseService();

  /// Uploads local changes from Hive to Supabase.
  Future<({bool success, String message, int count})> uploadPendingChanges() async {
    if (!SupabaseConfig.isInitialized) {
      return (
        success: false,
        message: 'Supabase is not initialized.',
        count: 0,
      );
    }
    try {
      int syncedCount = 0;

      // 1. Sync Vehicles
      final vehiclesBox = HiveRegistrar.vehiclesBox;
      for (final vehicle in vehiclesBox.values) {
        try {
          await _supabaseService.client.from('vehicles').upsert({
            'id': vehicle.id,
            'brand': vehicle.brand,
            'model': vehicle.model,
            'year': vehicle.year,
            'vehicle_type': vehicle.vehicleType,
            'current_kilometer': vehicle.currentKilometer,
            'photo_path': vehicle.photoPath,
            'created_at': vehicle.createdAt.toIso8601String(),
          }, onConflict: 'id');
          syncedCount++;
        } catch (e) {
          debugPrint('Error uploading vehicle ${vehicle.id}: $e');
        }
      }

      // 2. Sync Service Records (Maintenance)
      final historyBox = HiveRegistrar.serviceHistoryBox;
      for (final log in historyBox.values) {
        try {
          await _supabaseService.client.from('service_records').upsert({
            'id': log.id,
            'vehicle_id': log.vehicleId,
            'component_type': log.componentType,
            'service_km': log.serviceKm,
            'service_date': log.serviceDate.toIso8601String(),
            'cost': log.cost,
            'notes': log.notes,
          }, onConflict: 'id');
          syncedCount++;
        } catch (e) {
          debugPrint('Error uploading service log ${log.id}: $e');
        }
      }

      // 3. Sync Ride Sessions
      final ridesBox = HiveRegistrar.ridesBox;
      for (final RideSessionModel ride in ridesBox.values) {
        try {
          await _supabaseService.client.from('ride_sessions').upsert({
            'id': ride.id,
            'vehicle_id': ride.vehicleId,
            'start_time': ride.startTime.toIso8601String(),
            'end_time': ride.endTime.toIso8601String(),
            'total_distance_km': ride.totalDistanceKm,
            'total_duration_seconds': ride.durationSeconds,
            'avg_speed_kmh': ride.averageSpeedKmh,
            'max_speed_kmh': ride.maxSpeedKmh,
          }, onConflict: 'id');
          syncedCount++;
        } catch (e) {
          debugPrint('Error uploading ride ${ride.id}: $e');
        }
      }

      return (
        success: true,
        message: 'Successfully uploaded $syncedCount records to Supabase.',
        count: syncedCount
      );
    } catch (e) {
      debugPrint('SyncManager.uploadPendingChanges failed: $e');
      return (
        success: false,
        message: 'Upload failed: $e',
        count: 0
      );
    }
  }

  /// Downloads latest remote data from Supabase and merges into Hive local database.
  Future<({bool success, String message, int count})> downloadLatestData() async {
    if (!SupabaseConfig.isInitialized) {
      return (
        success: false,
        message: 'Supabase is not initialized.',
        count: 0,
      );
    }
    try {
      int importedCount = 0;

      // 1. Download Vehicles
      try {
        final remoteVehicles = await _supabaseService.getData('vehicles');
        final vehiclesBox = HiveRegistrar.vehiclesBox;

        for (final item in remoteVehicles) {
          final id = item['id']?.toString();
          if (id != null) {
            final vehicle = VehicleModel(
              id: id,
              vehicleType: item['vehicle_type']?.toString() ?? 'motorcycle',
              brand: item['brand']?.toString() ?? '',
              model: item['model']?.toString() ?? '',
              year: int.tryParse(item['year']?.toString() ?? '2024') ?? 2024,
              currentKilometer: double.tryParse(item['current_kilometer']?.toString() ?? '0') ?? 0.0,
              photoPath: item['photo_path']?.toString(),
              createdAt: DateTime.tryParse(item['created_at']?.toString() ?? '') ?? DateTime.now(),
            );
            await vehiclesBox.put(vehicle.id, vehicle);
            importedCount++;
          }
        }
      } catch (e) {
        debugPrint('Error downloading vehicles: $e');
      }

      // 2. Download Service Records
      try {
        final remoteLogs = await _supabaseService.getData('service_records');
        final historyBox = HiveRegistrar.serviceHistoryBox;

        for (final item in remoteLogs) {
          final id = item['id']?.toString();
          if (id != null) {
            final log = ServiceLogModel(
              id: id,
              vehicleId: item['vehicle_id']?.toString() ?? '',
              componentType: item['component_type']?.toString() ?? '',
              serviceKm: double.tryParse(item['service_km']?.toString() ?? '0') ?? 0.0,
              serviceDate: DateTime.tryParse(item['service_date']?.toString() ?? '') ?? DateTime.now(),
              cost: double.tryParse(item['cost']?.toString() ?? '0') ?? 0.0,
              notes: item['notes']?.toString() ?? '',
            );
            await historyBox.put(log.id, log);
            importedCount++;
          }
        }
      } catch (e) {
        debugPrint('Error downloading service records: $e');
      }

      return (
        success: true,
        message: 'Successfully downloaded and merged $importedCount records.',
        count: importedCount
      );
    } catch (e) {
      debugPrint('SyncManager.downloadLatestData failed: $e');
      return (
        success: false,
        message: 'Download failed: $e',
        count: 0
      );
    }
  }
}
