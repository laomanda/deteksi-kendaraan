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
  bool get isWarning => status == 'WARNING';
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
  static MaintenanceCalculationResult calculate({
    required int currentOdometer,
    required int intervalKm,
    int? lastServiceOdometer,
  }) {
    // If last service is recorded and greater than 0, next service is lastServiceOdometer + intervalKm
    // Otherwise fallback to formula: current_odometer + interval_km
    final int nextServiceKm;
    if (lastServiceOdometer != null && lastServiceOdometer > 0) {
      nextServiceKm = lastServiceOdometer + intervalKm;
    } else {
      nextServiceKm = currentOdometer + intervalKm;
    }

    final int remainingKm = nextServiceKm - currentOdometer;

    final String status;
    if (remainingKm <= 0) {
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
