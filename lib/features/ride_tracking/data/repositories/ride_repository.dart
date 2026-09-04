import 'package:flutter/foundation.dart';
import '../../../../core/database/hive_registrar.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/gps_point_model.dart';
import '../models/ride_session_model.dart';

class RideRepository {
  final SupabaseService _supabaseService;

  RideRepository([SupabaseService? supabaseService])
      : _supabaseService = supabaseService ?? SupabaseService();

  /// Saves a ride session locally to Hive and syncs to Supabase if connected.
  Future<void> saveRideSession(RideSessionModel session) async {
    // 1. Save to local Hive database (Offline-first)
    await HiveRegistrar.ridesBox.put(session.id, session);

    // 2. Attempt remote sync to Supabase
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

      // Also save points if any
      if (session.points.isNotEmpty) {
        await saveRidePoints(session.id, session.points);
      }
    } catch (e) {
      debugPrint('RideRepository.saveRideSession remote sync skipped/failed: $e');
    }
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
