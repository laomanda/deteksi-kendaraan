import 'dart:math' as math;
import '../data/models/maintenance_item_model.dart';
import '../data/models/maintenance_price_model.dart';
import '../data/models/vehicle_maintenance_model.dart';

/// Health calculation status wrapper containing computed metrics
class ComponentHealthResult {
  final MaintenanceItemModel item;
  final double deltaKm;
  final int deltaDays;
  final double rKm;
  final double rWaktu;
  final double healthPercentage; // 0.0 to 100.0
  final double remainingKm;
  final int remainingDays;

  const ComponentHealthResult({
    required this.item,
    required this.deltaKm,
    required this.deltaDays,
    required this.rKm,
    required this.rWaktu,
    required this.healthPercentage,
    required this.remainingKm,
    required this.remainingDays,
  });

  /// Fraction between 0.0 and 1.0 for UI Fill Icons
  double get fraction => (healthPercentage / 100.0).clamp(0.0, 1.0);

  bool get isOptimal => healthPercentage >= 80.0;
  bool get isModerate => healthPercentage >= 50.0 && healthPercentage < 80.0;
  bool get isWarning => healthPercentage >= 20.0 && healthPercentage < 50.0;
  bool get isCritical => healthPercentage < 20.0;
}

/// Service implementing PRD Section 7.3.3 formulas deterministically
class HealthCalculationService {
  HealthCalculationService._();

  /// Computes component health according to PRD formulas (2)-(6)
  static ComponentHealthResult calculateComponentHealth({
    required MaintenanceItemModel item,
    required double currentOdometer,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();

    // Delta KM and Delta Days
    final deltaKm = math.max(0.0, currentOdometer - item.lastServiceKm);
    final deltaDays = math.max(0, now.difference(item.lastServiceDate).inDays);

    // R_KM: if intervalKm <= 0 (e.g. Battery), R_KM is considered 1.0
    double rKm = 1.0;
    double remainingKm = 0.0;
    if (item.intervalKm > 0) {
      rKm = math.max(0.0, 1.0 - (deltaKm / item.intervalKm));
      remainingKm = math.max(0.0, item.intervalKm - deltaKm);
    }

    // R_Waktu: calendar degradation
    double rWaktu = 1.0;
    int remainingDays = 0;
    if (item.intervalDays > 0) {
      rWaktu = math.max(0.0, 1.0 - (deltaDays / item.intervalDays));
      remainingDays = math.max(0, item.intervalDays - deltaDays);
    }

    // Health Percentage = min(R_KM, R_Waktu) * 100%
    final healthPercentage = (math.min(rKm, rWaktu) * 100.0).clamp(0.0, 100.0);

    return ComponentHealthResult(
      item: item,
      deltaKm: deltaKm,
      deltaDays: deltaDays,
      rKm: rKm,
      rWaktu: rWaktu,
      healthPercentage: healthPercentage,
      remainingKm: remainingKm,
      remainingDays: remainingDays,
    );
  }

  /// Calculates aggregated health score for a vehicle across all its maintenance items
  static double calculateVehicleAggregateScore(
    List<ComponentHealthResult> results,
  ) {
    if (results.isEmpty) return 100.0;
    final total = results.fold<double>(
      0.0,
      (sum, item) => sum + item.healthPercentage,
    );
    return (total / results.length).clamp(0.0, 100.0);
  }

  /// Conservative Degradation Heuristic (PRD Section 7.2.2 Condition B)
  /// Initializes component to 25% health (warning zone)
  static ({double lastServiceKm, DateTime lastServiceDate})
      calculateUnknownHistoryInitialCondition({
    required double currentOdometer,
    required double intervalKm,
    required int intervalDays,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();

    final lastKm = intervalKm > 0
        ? math.max(0.0, currentOdometer - (0.75 * intervalKm))
        : currentOdometer;

    final daysToSubtract = (0.75 * intervalDays).round();
    final lastDate = current.subtract(Duration(days: daysToSubtract));

    return (lastServiceKm: lastKm, lastServiceDate: lastDate);
  }

  /// Kalkulasi Maintenance Health berdasarkan current_odometer, last_service_odometer, dan default_interval_km
  static VehicleMaintenanceHealth calculateItemHealth({
    required VehicleMaintenanceModel item,
    required int currentOdometer,
    required int defaultIntervalKm,
    MaintenancePriceModel? priceEstimate,
  }) {
    final usedKm = math.max(0, currentOdometer - item.lastServiceOdometer);
    final remainingKm = math.max(0, defaultIntervalKm - usedKm);
    final healthPercentage = defaultIntervalKm > 0
        ? ((remainingKm / defaultIntervalKm) * 100.0).clamp(0.0, 100.0)
        : 100.0;

    String status;
    if (remainingKm == 0 || healthPercentage <= 0) {
      status = 'OVERDUE';
    } else if (remainingKm <= (0.25 * defaultIntervalKm) || healthPercentage <= 25.0) {
      status = 'DUE SOON';
    } else {
      status = 'GOOD';
    }

    final nextServiceOdo = item.lastServiceOdometer + defaultIntervalKm;

    return VehicleMaintenanceHealth(
      item: item,
      usedKm: usedKm,
      remainingKm: remainingKm,
      healthPercentage: healthPercentage,
      status: status,
      nextServiceOdometer: nextServiceOdo,
      priceEstimate: priceEstimate,
    );
  }

  /// Menghitung skor kesehatan keseluruhan (Overall Health) kendaraan
  static double calculateOverallScore(List<VehicleMaintenanceHealth> items) {
    if (items.isEmpty) return 100.0;
    final sum = items.fold<double>(0.0, (acc, e) => acc + e.healthPercentage);
    return (sum / items.length).clamp(0.0, 100.0);
  }
}

/// DTO representasi hasil kalkulasi kesehatan satu item maintenance
class VehicleMaintenanceHealth {
  final VehicleMaintenanceModel item;
  final int usedKm;
  final int remainingKm;
  final double healthPercentage; // 0.0 to 100.0
  final String status; // 'GOOD' | 'DUE SOON' | 'OVERDUE'
  final int nextServiceOdometer;
  final MaintenancePriceModel? priceEstimate;

  const VehicleMaintenanceHealth({
    required this.item,
    required this.usedKm,
    required this.remainingKm,
    required this.healthPercentage,
    required this.status,
    required this.nextServiceOdometer,
    this.priceEstimate,
  });

  bool get isGood => status == 'GOOD';
  bool get isDueSoon => status == 'DUE SOON';
  bool get isOverdue => status == 'OVERDUE';
}
