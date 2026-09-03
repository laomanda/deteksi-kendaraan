import 'package:hive/hive.dart';
import '../../../../core/database/hive_registrar.dart';
import '../models/ride_session_model.dart';

class RideHistoryRepository {
  Box<RideSessionModel> get _box => HiveRegistrar.ridesBox;

  List<RideSessionModel> getRidesForVehicle(
    String vehicleId, {
    int offset = 0,
    int? limit,
    DateTime? afterDate,
  }) {
    final filtered = _box.values.where((ride) {
      if (ride.vehicleId != vehicleId) return false;
      if (afterDate != null && ride.startTime.isBefore(afterDate)) return false;
      return true;
    }).toList();

    // Sort descending by start time (newest first)
    filtered.sort((a, b) => b.startTime.compareTo(a.startTime));

    if (offset >= filtered.length) return [];
    if (limit != null) {
      return filtered.skip(offset).take(limit).toList();
    }
    return offset > 0 ? filtered.skip(offset).toList() : filtered;
  }

  /// Fast O(N) single-pass lookup without duplicating or sorting the entire database
  RideSessionModel? getLatestRideForVehicle(String vehicleId) {
    RideSessionModel? latest;
    for (final ride in _box.values) {
      if (ride.vehicleId == vehicleId) {
        if (latest == null || ride.startTime.isAfter(latest.startTime)) {
          latest = ride;
        }
      }
    }
    return latest;
  }

  /// Fast aggregate stats without full widget list allocations
  ({int count, double totalKm}) getVehicleRideStats(String vehicleId) {
    int count = 0;
    double totalKm = 0.0;
    for (final ride in _box.values) {
      if (ride.vehicleId == vehicleId) {
        count++;
        totalKm += ride.totalDistanceKm;
      }
    }
    return (count: count, totalKm: totalKm);
  }

  Future<void> saveRide(RideSessionModel session) async {
    await _box.put(session.id, session);
  }

  Future<void> deleteRide(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteRidesForVehicle(String vehicleId) async {
    final keys = _box.values
        .where((ride) => ride.vehicleId == vehicleId)
        .map((ride) => ride.id)
        .toList();
    await _box.deleteAll(keys);
  }
}
