import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../data/models/maintenance_price_model.dart';
import '../data/models/vehicle_maintenance_model.dart';
import '../../vehicle/data/models/vehicle_model.dart';

/// DTO representing maintenance prediction for a single component
class MaintenancePrediction {
  final VehicleMaintenanceModel item;
  final String componentName;
  final String category;
  final double currentHealth; // 0.0 to 100.0
  final int remainingKm;
  final int usedKm;
  final int nextServiceOdometer;
  final int remainingDays;
  final DateTime estimatedNextServiceDate;
  final String status; // 'OVERDUE' | 'DUE SOON' | 'GOOD'
  final String urgencyGroup; // 'URGENT' | 'UPCOMING' | 'LATER'
  final String whicheverComesFirstText;
  final MaintenancePriceModel? priceEstimate;
  final double partMin;
  final double partMax;
  final double laborMin;
  final double laborMax;
  final double totalMin;
  final double totalMax;

  const MaintenancePrediction({
    required this.item,
    required this.componentName,
    required this.category,
    required this.currentHealth,
    required this.remainingKm,
    required this.usedKm,
    required this.nextServiceOdometer,
    required this.remainingDays,
    required this.estimatedNextServiceDate,
    required this.status,
    required this.urgencyGroup,
    required this.whicheverComesFirstText,
    this.priceEstimate,
    required this.partMin,
    required this.partMax,
    required this.laborMin,
    required this.laborMax,
    required this.totalMin,
    required this.totalMax,
  });

  bool get isOverdue => status == 'OVERDUE';
  bool get isDueSoon => status == 'DUE SOON';
  bool get isGood => status == 'GOOD';

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  String get formattedTotalRange =>
      '${_currencyFormat.format(totalMin)} - ${_currencyFormat.format(totalMax)}';

  String get formattedPartRange =>
      '${_currencyFormat.format(partMin)} - ${_currencyFormat.format(partMax)}';

  String get formattedLaborRange =>
      '${_currencyFormat.format(laborMin)} - ${_currencyFormat.format(laborMax)}';

  /// Compact formatted range (e.g. "Rp60K - Rp150K" or "Rp1M - Rp2.5M")
  String get formattedCompactRange {
    return '${_formatCompactNumber(totalMin)} - ${_formatCompactNumber(totalMax)}';
  }

  static String _formatCompactNumber(double amount) {
    if (amount >= 1000000) {
      final val = amount / 1000000.0;
      return 'Rp${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}M';
    } else if (amount >= 1000) {
      final val = amount / 1000.0;
      return 'Rp${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 0)}K';
    }
    return _currencyFormat.format(amount);
  }

  /// Checks if prediction falls within a given calendar horizon in days
  bool isDueWithinDays(int days) {
    if (isOverdue) return true;
    return remainingDays <= days;
  }
}

/// Pure deterministic offline maintenance prediction engine
class MaintenancePredictionService {
  MaintenancePredictionService._();

  /// Adds months safely by handling varying month lengths
  static DateTime addMonthsSafely(DateTime date, int months) {
    var newYear = date.year + (date.month + months - 1) ~/ 12;
    var newMonth = (date.month + months - 1) % 12 + 1;
    var newDay = date.day;

    var daysInMonth = DateTime(newYear, newMonth + 1, 0).day;
    if (newDay > daysInMonth) {
      newDay = daysInMonth;
    }
    return DateTime(
      newYear,
      newMonth,
      newDay,
      date.hour,
      date.minute,
      date.second,
    );
  }

  /// Formats the "whichever comes first" text e.g. "500 KM or 20 days"
  static String formatWhicheverComesFirst({
    required int remainingKm,
    required int remainingDays,
  }) {
    final displayDays = math.max(0, remainingDays);
    return '$remainingKm KM or $displayDays days';
  }

  /// Calculates maintenance prediction for a single maintenance item
  static MaintenancePrediction predictItem({
    required VehicleMaintenanceModel item,
    required int currentOdometer,
    MaintenancePriceModel? priceEstimate,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();

    // 1. KM-BASED CALCULATION
    final intervalKm = (item.intervalKm != null && item.intervalKm! > 0)
        ? item.intervalKm!
        : 3000;
    final usedKm = math.max(0, currentOdometer - item.lastServiceOdometer);
    final remainingKm = math.max(0, intervalKm - usedKm);
    final nextServiceOdometer = item.lastServiceOdometer + intervalKm;

    String kmStatus;
    if (currentOdometer >= nextServiceOdometer || remainingKm <= 0) {
      kmStatus = 'OVERDUE';
    } else if (remainingKm <= 500 || remainingKm <= (0.25 * intervalKm)) {
      kmStatus = 'DUE SOON';
    } else {
      kmStatus = 'GOOD';
    }

    // 2. TIME-BASED CALCULATION
    final intervalMonth = (item.intervalMonth != null && item.intervalMonth! > 0)
        ? item.intervalMonth!
        : 3;
    final lastDate = item.lastServiceDate ?? now;
    final nextServiceDate = addMonthsSafely(lastDate, intervalMonth);
    final remainingDays = nextServiceDate.difference(now).inDays;

    String timeStatus;
    if (remainingDays <= 0 || now.isAfter(nextServiceDate)) {
      timeStatus = 'OVERDUE';
    } else if (remainingDays <= 30 ||
        remainingDays <= (0.25 * intervalMonth * 30)) {
      timeStatus = 'DUE SOON';
    } else {
      timeStatus = 'GOOD';
    }

    // 3. WHICHEVER COMES FIRST & STATUS SYNTHESIS
    String overallStatus;
    if (kmStatus == 'OVERDUE' || timeStatus == 'OVERDUE') {
      overallStatus = 'OVERDUE';
    } else if (kmStatus == 'DUE SOON' || timeStatus == 'DUE SOON') {
      overallStatus = 'DUE SOON';
    } else {
      overallStatus = 'GOOD';
    }

    final displayDays = math.max(0, remainingDays);
    final String whicheverText = '$remainingKm KM or $displayDays days';

    // 4. HEALTH PERCENTAGE
    final kmFraction =
        intervalKm > 0 ? (remainingKm / intervalKm).clamp(0.0, 1.0) : 1.0;
    final totalIntervalDays = intervalMonth * 30;
    final timeFraction = totalIntervalDays > 0
        ? (remainingDays / totalIntervalDays).clamp(0.0, 1.0)
        : 1.0;
    final currentHealth =
        (math.min(kmFraction, timeFraction) * 100.0).clamp(0.0, 100.0);

    // 5. URGENCY GROUPING
    String urgencyGroup;
    if (overallStatus == 'OVERDUE' ||
        (overallStatus == 'DUE SOON' &&
            (remainingKm <= 1000 || remainingDays <= 14))) {
      urgencyGroup = 'URGENT';
    } else if (overallStatus == 'DUE SOON' ||
        (remainingKm <= 3000 || remainingDays <= 60)) {
      urgencyGroup = 'UPCOMING';
    } else {
      urgencyGroup = 'LATER';
    }

    // 6. COST ESTIMATION RANGE
    final partMin = priceEstimate?.minPrice ?? 0.0;
    final partMax = priceEstimate?.maxPrice ?? 0.0;
    final laborMin = priceEstimate?.laborMin ?? 0.0;
    final laborMax = priceEstimate?.laborMax ?? 0.0;
    final totalMin = partMin + laborMin;
    final totalMax = partMax + laborMax;

    return MaintenancePrediction(
      item: item,
      componentName: item.itemName ?? item.maintenanceId,
      category: item.itemCategory ?? 'general',
      currentHealth: currentHealth,
      remainingKm: remainingKm,
      usedKm: usedKm,
      nextServiceOdometer: nextServiceOdometer,
      remainingDays: remainingDays,
      estimatedNextServiceDate: nextServiceDate,
      status: overallStatus,
      urgencyGroup: urgencyGroup,
      whicheverComesFirstText: whicheverText,
      priceEstimate: priceEstimate,
      partMin: partMin,
      partMax: partMax,
      laborMin: laborMin,
      laborMax: laborMax,
      totalMin: totalMin,
      totalMax: totalMax,
    );
  }

  /// Predicts all maintenance items for a vehicle and sorts them by urgency
  static List<MaintenancePrediction> predictVehicleMaintenance({
    required VehicleModel vehicle,
    required List<VehicleMaintenanceModel> items,
    List<MaintenancePriceModel>? prices,
    DateTime? currentDate,
  }) {
    if (items.isEmpty) return [];

    final now = currentDate ?? DateTime.now();

    final predictions = items.map((item) {
      final price = prices?.where((p) {
            return p.maintenanceId == item.maintenanceId ||
                p.maintenanceId == item.id ||
                (item.itemName != null &&
                    p.id.toLowerCase().contains(item.itemName!.toLowerCase()));
          }).firstOrNull ??
          MaintenancePriceModel.getPriceForMaintenance(
            item.itemName ?? item.maintenanceId,
            vehicleType: vehicle.vehicleType,
          );

      return predictItem(
        item: item,
        currentOdometer: vehicle.currentOdometer,
        priceEstimate: price,
        currentDate: now,
      );
    }).toList();

    // Priority Sort (Section 5):
    // 1. OVERDUE
    // 2. DUE SOON with least remaining
    // 3. GOOD with least remaining
    predictions.sort((a, b) {
      final priorityWeight = {'OVERDUE': 0, 'DUE SOON': 1, 'GOOD': 2};
      final weightA = priorityWeight[a.status] ?? 3;
      final weightB = priorityWeight[b.status] ?? 3;

      if (weightA != weightB) {
        return weightA.compareTo(weightB);
      }

      // If same status, compare smallest remaining KM or remaining days
      if (a.remainingKm != b.remainingKm) {
        return a.remainingKm.compareTo(b.remainingKm);
      }
      return a.remainingDays.compareTo(b.remainingDays);
    });

    return predictions;
  }
}
