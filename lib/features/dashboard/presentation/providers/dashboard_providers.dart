import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../maintenance/domain/maintenance_prediction_service.dart';
import '../../../maintenance/providers/maintenance_intelligence_providers.dart';
import '../../../maintenance/providers/maintenance_prediction_providers.dart';
import '../../../ride_tracking/data/models/ride_session_model.dart';
import '../../../ride_tracking/presentation/controllers/ride_tracking_controller.dart';
import '../../../vehicle/data/models/vehicle_model.dart';

/// DTO for Dashboard Vehicle Summary
class DashboardVehicleSummary {
  final VehicleModel vehicle;
  final double healthScore;
  final String status; // 'GOOD' | 'DUE SOON' | 'OVERDUE'
  final int overdueCount;
  final int dueSoonCount;
  final int totalUpcomingCount;
  final String formattedUpcomingCost;
  final MaintenancePrediction? mostUrgentPrediction;

  const DashboardVehicleSummary({
    required this.vehicle,
    required this.healthScore,
    required this.status,
    required this.overdueCount,
    required this.dueSoonCount,
    required this.totalUpcomingCount,
    required this.formattedUpcomingCost,
    this.mostUrgentPrediction,
  });

  bool get isOverdue => status == 'OVERDUE';
  bool get isDueSoon => status == 'DUE SOON';
  bool get isGood => status == 'GOOD';

  /// Human-friendly Indonesian status title (No technical jargon)
  String get humanStatusTitle {
    if (isOverdue) return 'Perlu Servis';
    if (isDueSoon) return 'Perlu Perhatian';
    return 'Kendaraan Aman';
  }

  /// Human-friendly Indonesian status explanation
  String get humanStatusSubtitle {
    if (isOverdue) {
      if (mostUrgentPrediction != null) {
        return '${mostUrgentPrediction!.componentName} sudah melewati jadwal servis.';
      }
      return 'Ada komponen yang sudah melewati jadwal servis.';
    }
    if (isDueSoon) {
      if (mostUrgentPrediction != null) {
        return '${mostUrgentPrediction!.componentName} diperkirakan perlu diganti dalam ${mostUrgentPrediction!.remainingKm} KM.';
      }
      return 'Ada komponen yang mendekati batas pemakaian.';
    }
    return 'Belum ada servis yang perlu dilakukan.';
  }

  /// Human-friendly short badge
  String get humanStatusBadge {
    if (isOverdue) return 'PERLU SERVIS';
    if (isDueSoon) return 'PERHATIAN';
    return 'AMAN';
  }
}

/// Synthesizes vehicle summary for dashboard with Smart Priority rule:
/// If ANY maintenance item is OVERDUE, vehicle status is NEVER 'GOOD'.
final dashboardSummaryProvider = Provider<AsyncValue<DashboardVehicleSummary?>>((ref) {
  final activeVehicle = ref.watch(activeVehicleProvider);
  if (activeVehicle == null) {
    return const AsyncValue.data(null);
  }

  final healthAsync = ref.watch(maintenanceHealthProvider(activeVehicle.id));
  final upcomingAsync = ref.watch(upcomingMaintenanceProvider(activeVehicle.id));
  final costAsync = ref.watch(maintenanceCostForecastProvider(activeVehicle.id));

  // Provide graceful defaults during initial async load to support instant offline-first display
  final healthScore = healthAsync.value?.overallScore ?? 100.0;
  final predictions = upcomingAsync.value ?? [];
  final costData = costAsync.value;

  int overdueCount = 0;
  int dueSoonCount = 0;

  for (final p in predictions) {
    if (p.isOverdue) {
      overdueCount++;
    } else if (p.isDueSoon) {
      dueSoonCount++;
    }
  }

  // Smart Priority Status logic
  String status;
  if (overdueCount > 0) {
    status = 'OVERDUE';
  } else if (dueSoonCount > 0 || healthScore < 50) {
    status = 'DUE SOON';
  } else {
    status = 'GOOD';
  }

  final String formattedCost = (costData != null && costData.count > 0)
      ? costData.formattedCompactRange
      : 'Estimasi biaya belum tersedia';

  final mostUrgent = predictions.isNotEmpty ? predictions.first : null;

  return AsyncValue.data(
    DashboardVehicleSummary(
      vehicle: activeVehicle,
      healthScore: healthScore,
      status: status,
      overdueCount: overdueCount,
      dueSoonCount: dueSoonCount,
      totalUpcomingCount: overdueCount + dueSoonCount,
      formattedUpcomingCost: formattedCost,
      mostUrgentPrediction: mostUrgent,
    ),
  );
});

/// DTO for Monthly Ride Activity Statistics
class MonthlyRideStats {
  final double totalDistanceKm;
  final int tripCount;
  final int totalDurationSeconds;

  const MonthlyRideStats({
    required this.totalDistanceKm,
    required this.tripCount,
    required this.totalDurationSeconds,
  });

  String get formattedDistance => DateFormatter.formatKm(totalDistanceKm);

  String get formattedRideTime {
    if (totalDurationSeconds <= 0) return '0 min';
    final hours = totalDurationSeconds ~/ 3600;
    final minutes = (totalDurationSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '$minutes min';
  }

  bool get hasActivity => tripCount > 0 || totalDistanceKm > 0;
}

/// Provider computing current month ride statistics deterministically from Hive rides
final monthlyRideStatsProvider = Provider<MonthlyRideStats>((ref) {
  final rides = ref.watch(rideHistoryListProvider);
  final now = DateTime.now();

  double totalDistance = 0.0;
  int tripCount = 0;
  int totalDuration = 0;

  for (final ride in rides) {
    if (ride.startTime.year == now.year && ride.startTime.month == now.month) {
      totalDistance += ride.totalDistanceKm;
      tripCount++;
      totalDuration += ride.durationSeconds;
    }
  }

  return MonthlyRideStats(
    totalDistanceKm: totalDistance,
    tripCount: tripCount,
    totalDurationSeconds: totalDuration,
  );
});

/// Provider returning up to 3 most recent rides for active vehicle
final recentRidesProvider = Provider<List<RideSessionModel>>((ref) {
  final rides = ref.watch(rideHistoryListProvider);
  return rides.take(3).toList();
});
