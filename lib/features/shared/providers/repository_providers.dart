import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../garage/data/repositories/vehicle_repository.dart';
import '../../maintenance/data/repositories/maintenance_repository.dart';
import '../../ride_tracking/data/repositories/ride_history_repository.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository();
});

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepository();
});

final rideHistoryRepositoryProvider = Provider<RideHistoryRepository>((ref) {
  return RideHistoryRepository();
});
