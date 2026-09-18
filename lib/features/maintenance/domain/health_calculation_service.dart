import 'dart:math' as math;
import '../../../../core/utils/date_formatter.dart';
import '../data/models/maintenance_item_model.dart';
import '../data/models/maintenance_price_model.dart';
import '../data/models/vehicle_maintenance_model.dart';

/// Health calculation status wrapper containing computed metrics
class ComponentHealthResult {
  final MaintenanceItemModel item;
  final double baseKm;
  final double deltaKm;
  final int deltaDays;
  final double rKm;
  final double rWaktu;
  final double healthPercentage; // 0.0 to 100.0
  final double remainingKm;
  final int remainingDays;
  final bool hasServiceHistory;

  const ComponentHealthResult({
    required this.item,
    this.baseKm = 0.0,
    required this.deltaKm,
    required this.deltaDays,
    required this.rKm,
    required this.rWaktu,
    required this.healthPercentage,
    required this.remainingKm,
    required this.remainingDays,
    this.hasServiceHistory = false,
  });

  /// Fraction between 0.0 and 1.0 for UI Fill Icons
  double get fraction => (healthPercentage / 100.0).clamp(0.0, 1.0);

  bool get isOptimal => healthPercentage >= 80.0;
  bool get isModerate => healthPercentage >= 50.0 && healthPercentage < 80.0;
  bool get isWarning => healthPercentage >= 20.0 && healthPercentage < 50.0;
  bool get isCritical => healthPercentage < 20.0;

  /// User-facing status label adhering to UX consistency rules
  String get userFacingStatusLabel {
    if (isCritical) return 'Perlu dilakukan segera';
    if (isWarning) return 'Mendekati jadwal perawatan';
    return 'Kondisi prima';
  }

  /// User-facing remaining text adhering to UX consistency rules
  String get userFacingRemainingText {
    final remKmStr = DateFormatter.formatKm(remainingKm);
    if (isCritical) return 'Perlu dilakukan segera (Lewat jadwal)';
    if (isWarning) return 'Disarankan dalam $remKmStr lagi';
    return item.intervalKm > 0
        ? 'Disarankan dalam $remKmStr lagi'
        : 'Disarankan dalam ≈ $remainingDays hari lagi';
  }

  /// User-facing history footnote distinguishing baseline vs recorded history
  String get userFacingHistoryText {
    final double rawKm = hasServiceHistory
        ? item.lastServiceKm
        : (baseKm > 0 ? baseKm : (item.lastServiceKm > 0 ? item.lastServiceKm : 0.0));
    final kmStr = DateFormatter.formatKm(rawKm);
    final dateStr = DateFormatter.formatDate(item.lastServiceDate);
    if (hasServiceHistory) {
      return 'Servis terakhir: $kmStr ($dateStr)';
    }
    return 'Mulai pemantauan: $kmStr ($dateStr)';
  }

  /// Explicit semantic distinction title
  String get userFacingHistoryStateTitle {
    if (hasServiceHistory) {
      return 'Servis terakhir tercatat';
    }
    return 'Pemantauan dimulai dari odometer kendaraan';
  }
}

/// Service implementing PRD Section 7.3.3 formulas deterministically
class HealthCalculationService {
  HealthCalculationService._();

  /// Computes component health according to PRD formulas (2)-(6)
  /// Logic:
  /// if maintenance history exists:
  ///     baseKm = last_service_odometer
  /// else:
  ///     baseKm = vehicle.current_odometer
  /// nextServiceKm = baseKm + maintenanceRule.intervalKm
  static ComponentHealthResult calculateComponentHealth({
    required MaintenanceItemModel item,
    required double currentOdometer,
    DateTime? currentDate,
    bool? hasMaintenanceHistory,
  }) {
    final now = currentDate ?? DateTime.now();

    final bool historyExists = hasMaintenanceHistory ?? (item.lastServiceKm > 0);
    final double baseKm = historyExists ? item.lastServiceKm : currentOdometer;

    // Delta KM and Delta Days
    final deltaKm = math.max(0.0, currentOdometer - baseKm);
    final deltaDays = math.max(0, now.difference(item.lastServiceDate).inDays);

    // R_KM: if intervalKm <= 0 (e.g. Battery), R_KM is considered 1.0
    double rKm = 1.0;
    double remainingKm = 0.0;
    if (item.intervalKm > 0) {
      final nextServiceKm = baseKm + item.intervalKm;
      remainingKm = math.max(0.0, nextServiceKm - currentOdometer);
      rKm = (remainingKm / item.intervalKm).clamp(0.0, 1.0);
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
      baseKm: baseKm,
      deltaKm: deltaKm,
      deltaDays: deltaDays,
      rKm: rKm,
      rWaktu: rWaktu,
      healthPercentage: healthPercentage,
      remainingKm: remainingKm,
      remainingDays: remainingDays,
      hasServiceHistory: historyExists,
    );
  }

  /// Calculates aggregated health score for a vehicle across all its maintenance items
  static double calculateVehicleAggregateScore(
    List<ComponentHealthResult> results,
  ) {
    if (results.isEmpty) return 100.0;
    final total = results.fold<double>(
      0.0,
      (sum, item) => sum + item.healthPercentage.clamp(0.0, 100.0),
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
  /// Logic:
  /// if maintenance history exists:
  ///     baseKm = last_service_odometer
  /// else:
  ///     baseKm = vehicle.current_odometer
  /// nextServiceKm = baseKm + defaultIntervalKm
  static VehicleMaintenanceHealth calculateItemHealth({
    required VehicleMaintenanceModel item,
    required int currentOdometer,
    required int defaultIntervalKm,
    MaintenancePriceModel? priceEstimate,
    DateTime? currentDate,
    bool? hasMaintenanceHistory,
  }) {
    final now = currentDate ?? DateTime.now();
    final isTimeOnly = defaultIntervalKm <= 0;

    final bool historyExists = hasMaintenanceHistory ?? item.hasServiceHistory;
    final int baseKm = historyExists
        ? item.lastServiceOdometer
        : currentOdometer;

    final usedKm = isTimeOnly ? 0 : math.max(0, currentOdometer - baseKm);
    final nextServiceOdo = isTimeOnly ? currentOdometer : baseKm + defaultIntervalKm;
    final remainingKm = isTimeOnly ? 0 : math.max(0, nextServiceOdo - currentOdometer);

    double healthPercentage;
    if (isTimeOnly) {
      if (item.intervalMonth != null && item.intervalMonth! > 0) {
        final lastDate = (historyExists && item.lastServiceDate != null)
            ? item.lastServiceDate!
            : now;
        final daysInInterval = item.intervalMonth! * 30;
        final elapsedDays = math.max(0, now.difference(lastDate).inDays);
        final remainingDays = math.max(0, daysInInterval - elapsedDays);
        healthPercentage = ((remainingDays / daysInInterval) * 100.0).clamp(0.0, 100.0);
      } else {
        healthPercentage = 100.0;
      }
    } else {
      healthPercentage = ((remainingKm / defaultIntervalKm) * 100.0).clamp(0.0, 100.0);
    }

    String status;
    if (healthPercentage <= 0.0 || (!isTimeOnly && remainingKm <= 0)) {
      status = 'OVERDUE';
    } else if (healthPercentage <= 25.0 || (!isTimeOnly && remainingKm <= (0.25 * defaultIntervalKm))) {
      status = 'DUE SOON';
    } else {
      status = 'GOOD';
    }

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
    final sum = items.fold<double>(0.0, (acc, e) => acc + e.healthPercentage.clamp(0.0, 100.0));
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

  /// User-facing status label adhering to UX consistency rules
  String get userFacingStatusLabel {
    if (isOverdue) return 'Perlu dilakukan segera';
    if (isDueSoon) return 'Mendekati jadwal perawatan';
    return 'Kondisi prima';
  }

  /// User-facing remaining text adhering to UX consistency rules
  String get userFacingRemainingText {
    final remKmStr = DateFormatter.formatKm(remainingKm.toDouble());
    if (isOverdue) return 'Perlu dilakukan segera (Lewat jadwal)';
    if (isDueSoon) return 'Disarankan dalam $remKmStr lagi';
    return 'Disarankan dalam $remKmStr lagi';
  }

  /// User-facing history footnote distinguishing baseline vs recorded history
  String get userFacingHistoryText {
    final double rawKm = item.hasServiceHistory
        ? item.lastServiceOdometer.toDouble()
        : (item.lastServiceOdometer > 0
            ? item.lastServiceOdometer.toDouble()
            : (nextServiceOdometer - (item.intervalKm ?? 0)).toDouble().clamp(0.0, double.infinity));
    final kmStr = DateFormatter.formatKm(rawKm);
    final dateStr = item.lastServiceDate != null
        ? DateFormatter.formatDate(item.lastServiceDate!)
        : '-';
    if (item.hasServiceHistory) {
      return 'Servis terakhir: $kmStr ($dateStr)';
    }
    return 'Mulai pemantauan: $kmStr ($dateStr)';
  }

  /// Explicit semantic distinction title
  String get userFacingHistoryStateTitle {
    if (item.hasServiceHistory) {
      return 'Servis terakhir tercatat';
    }
    return 'Pemantauan dimulai dari odometer kendaraan';
  }
}
