import 'package:hive/hive.dart';
import '../../../../core/database/hive_registrar.dart';
import '../models/ride_session_model.dart';

class RideHistoryRepository {
  Box<RideSessionModel> get _box => HiveRegistrar.ridesBox;

  List<RideSessionModel> getRidesForVehicle(String vehicleId) {
    final rides = _box.values
        .where((ride) => ride.vehicleId == vehicleId)
        .toList();
    // Sort descending by start time
    rides.sort((a, b) => b.startTime.compareTo(a.startTime));
    return rides;
  }

  RideSessionModel? getLatestRideForVehicle(String vehicleId) {
    final rides = getRidesForVehicle(vehicleId);
    return rides.isNotEmpty ? rides.first : null;
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
