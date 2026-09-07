import 'package:flutter/foundation.dart';
import '../../../../core/database/hive_registrar.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../vehicle/data/repositories/vehicle_repository.dart';
import '../models/gps_point_model.dart';

import '../models/ride_session_model.dart';

class RideRepository {
  final SupabaseService _supabaseService;
  static const String _processedRidesKey = 'processed_odometer_ride_ids';

  RideRepository([SupabaseService? supabaseService])
      : _supabaseService = supabaseService ?? SupabaseService();

  /// Checks if a ride session has already accumulated distance into the vehicle odometer (Idempotency)
  bool isRideProcessedForOdometer(String rideId) {
    try {
      final raw = HiveRegistrar.settingsBox.get(_processedRidesKey);
      if (raw is List) {
        return raw.map((e) => e.toString()).contains(rideId);
      }
    } catch (e) {
      debugPrint('RideRepository.isRideProcessedForOdometer error: $e');
    }
    return false;
  }

  /// Marks a ride session as processed for odometer accumulation in local storage
  Future<void> markRideProcessed(String rideId) async {
    try {
      final raw = HiveRegistrar.settingsBox.get(_processedRidesKey);
      final List<String> currentList =
          raw is List ? raw.map((e) => e.toString()).toList() : [];
      if (!currentList.contains(rideId)) {
        currentList.add(rideId);
        await HiveRegistrar.settingsBox.put(_processedRidesKey, currentList);
      }
    } catch (e) {
      debugPrint('RideRepository.markRideProcessed error: $e');
    }
  }

  /// Processes ride completion:
  /// 1. Saves RideSession to local Hive database (Offline-first)
  /// 2. Accumulates distance into Vehicle Odometer idempotently (No double counting)
  /// 3. Syncs session and odometer to Supabase if online
  Future<({int previousOdometer, int newOdometer, RideSessionModel session, bool wasAlreadyProcessed})>
      processRideCompletion({
    required RideSessionModel session,
    required VehicleRepository vehicleRepository,
  }) async {
    // 1. Always ensure ride session is stored locally
    await HiveRegistrar.ridesBox.put(session.id, session);

    final vehicle = vehicleRepository.getVehicleById(session.vehicleId);
    final previousOdo = vehicle?.currentOdometer ?? 0;

    // 2. Check Idempotency: Prevent double counting distance
    final alreadyProcessed = isRideProcessedForOdometer(session.id);
    if (alreadyProcessed || vehicle == null) {
      debugPrint(
        'Ride ${session.id} odometer update skipped. alreadyProcessed: $alreadyProcessed, vehicleExists: ${vehicle != null}',
      );
      // Attempt remote sync anyway for safety
      await _syncRemoteSession(session);
      return (
        previousOdometer: previousOdo,
        newOdometer: previousOdo,
        session: session,
        wasAlreadyProcessed: true,
      );
    }

    // 3. Calculate new odometer
    final int distanceToAdd = session.totalDistanceKm.round();
    final int newOdo = previousOdo + distanceToAdd;

    // 4. Update Vehicle Odometer in local Hive & Supabase
    await vehicleRepository.updateOdometer(vehicle.id, newOdo.toDouble());

    // 5. Mark as processed for odometer
    await markRideProcessed(session.id);

    // 6. Attempt remote sync for ride session & points
    await _syncRemoteSession(session);

    return (
      previousOdometer: previousOdo,
      newOdometer: newOdo,
      session: session,
      wasAlreadyProcessed: false,
    );
  }

  /// Remote sync helper for ride session and points
  Future<void> _syncRemoteSession(RideSessionModel session) async {
    try {
      if (!SupabaseConfig.isInitialized) return;
      await _supabaseService.insertData('ride_sessions', {
        'id': session.id,
        'vehicle_id': session.vehicleId,
        'start_time': session.startTime.toIso8601String(),
        'end_time': session.endTime.toIso8601String(),
        'distance': session.totalDistanceKm,
        'duration': session.durationSeconds,
        'avg_speed': session.averageSpeedKmh,
        'max_speed': session.maxSpeedKmh,
      });

      if (session.points.isNotEmpty) {
        await saveRidePoints(session.id, session.points);
      }
    } catch (e) {
      debugPrint('RideRepository._syncRemoteSession skipped/failed: $e');
    }
  }

  /// Saves a ride session locally to Hive and syncs to Supabase if connected.
  Future<void> saveRideSession(RideSessionModel session) async {
    // 1. Save to local Hive database (Offline-first)
    await HiveRegistrar.ridesBox.put(session.id, session);

    // 2. Attempt remote sync to Supabase
    await _syncRemoteSession(session);
  }

  /// Saves ride points associated with a ride session.
  Future<void> saveRidePoints(String sessionId, List<GpsPointModel> points) async {
    try {
      if (!SupabaseConfig.isInitialized) return;
      final payload = points.map((p) => {
        'ride_session_id': sessionId,
        'latitude': p.latitude,
        'longitude': p.longitude,
        'speed': p.speed,
        'recorded_at': p.timestamp.toIso8601String(),
      }).toList();

      await _supabaseService.insertData('ride_points', payload);
    } catch (e) {
      debugPrint('RideRepository.saveRidePoints remote sync skipped/failed: $e');
    }
  }
}

