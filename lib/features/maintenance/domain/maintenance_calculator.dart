import 'package:flutter/foundation.dart';

/// Calculation output data contract according to specification
@immutable
class MaintenanceCalculationResult {
  final int nextServiceKm;
  final int remainingKm;
  final int healthPercentage;
  final String status; // 'GOOD' | 'WARNING' | 'OVERDUE'

  const MaintenanceCalculationResult({
    required this.nextServiceKm,
    required this.remainingKm,
    required this.healthPercentage,
    required this.status,
  });

  bool get isGood => status == 'GOOD';
  bool get isWarning => status == 'WARNING' || status == 'UPCOMING';
  bool get isUpcoming => isWarning;
  bool get isOverdue => status == 'OVERDUE';

  Map<String, dynamic> toJson() => {
    'next_service_km': nextServiceKm,
    'remaining_km': remainingKm,
    'health_percentage': healthPercentage,
    'status': status,
  };

  @override
  String toString() =>
      'MaintenanceCalculationResult(nextServiceKm: $nextServiceKm, remainingKm: $remainingKm, status: $status, health: $healthPercentage%)';
}

/// Maintenance Status Engine
/// Production-grade calculator adhering strictly to RideCare rules:
/// - Formula next_service_km: current_odometer + interval_km (or base on lastServiceOdometer when available)
/// - remaining_km: next_service_km - current_odometer
/// - remaining_km > 500  -> GOOD
/// - remaining_km <= 500 -> WARNING
/// - remaining_km <= 0   -> OVERDUE
class MaintenanceCalculator {
  MaintenanceCalculator._();

  /// Calculates next service KM, remaining KM, and status
  /// Logic:
  /// if maintenance history exists:
  ///     baseKm = last_service_odometer
  /// else:
  ///     baseKm = vehicle.current_odometer
  /// nextServiceKm = baseKm + maintenanceRule.intervalKm
  static MaintenanceCalculationResult calculate({
    required int currentOdometer,
    required int intervalKm,
    int? lastServiceOdometer,
    bool? hasMaintenanceHistory,
  }) {
    final bool historyExists = hasMaintenanceHistory ??
        (lastServiceOdometer != null && lastServiceOdometer > 0);

    final int baseKm = historyExists
        ? (lastServiceOdometer ?? 0)
        : currentOdometer;

    final int nextServiceKm = baseKm + intervalKm;
    final int remainingKm = nextServiceKm - currentOdometer;

    final String status;
    if (intervalKm <= 0) {
      status = 'GOOD';
    } else if (remainingKm <= 0) {
      status = 'OVERDUE';
    } else if (remainingKm <= 500) {
      status = 'WARNING';
    } else {
      status = 'GOOD';
    }

    // Health percentage [0..100]
    final double ratio = intervalKm > 0
        ? (remainingKm / intervalKm).clamp(0.0, 1.0)
        : 1.0;
    final int healthPercentage = (ratio * 100).round();

    return MaintenanceCalculationResult(
      nextServiceKm: nextServiceKm,
      remainingKm: remainingKm,
      healthPercentage: healthPercentage,
      status: status,
    );
  }
}
