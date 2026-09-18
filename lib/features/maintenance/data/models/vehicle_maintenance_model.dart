import 'package:flutter/foundation.dart';
import '../../../vehicle/data/models/vehicle_model.dart';
import 'maintenance_rule_model.dart';

/// Immutable model representing a row in the Supabase 'vehicle_maintenance' table
@immutable
class VehicleMaintenanceModel {
  final String id;
  final String vehicleId;
  final String maintenanceId;
  final DateTime? lastServiceDate;
  final int lastServiceOdometer;
  final int healthPercentage; // 0 to 100
  final String status; // 'GOOD' | 'WARNING' | 'OVERDUE'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined relational data
  final MaintenanceRuleModel? maintenanceRule;
  final VehicleModel? vehicle;

  // Cached metadata for offline fast UI display
  final String? itemName;
  final String? itemCategory;
  final int? intervalKm;
  final int? intervalMonth;
  final bool? hasServiceHistoryFlag;

  const VehicleMaintenanceModel({
    required this.id,
    required this.vehicleId,
    required this.maintenanceId,
    this.lastServiceDate,
    this.lastServiceOdometer = 0,
    this.healthPercentage = 100,
    this.status = 'GOOD',
    this.createdAt,
    this.updatedAt,
    this.maintenanceRule,
    this.vehicle,
    this.itemName,
    this.itemCategory,
    this.intervalKm,
    this.intervalMonth,
    bool? hasServiceHistory,
  }) : hasServiceHistoryFlag = hasServiceHistory;

  /// Returns true if this maintenance item has an established service history.
  /// If false, calculations use vehicle current_odometer as the baseline.
  bool get hasServiceHistory =>
      hasServiceHistoryFlag ?? (lastServiceOdometer > 0);

  /// Resolves the base kilometer for maintenance calculation:
  /// if maintenance history exists:
  ///     baseKm = last_service_odometer
  /// else:
  ///     baseKm = vehicle.current_odometer
  int resolveBaseOdometer(int currentOdometer) {
    if (hasServiceHistory) {
      return lastServiceOdometer;
    }
    return currentOdometer;
  }

  bool get isGood => status.toUpperCase() == 'GOOD';
  bool get isWarning =>
      status.toUpperCase() == 'WARNING' ||
      status.toUpperCase() == 'DUE_SOON' ||
      status.toUpperCase() == 'DUE SOON';
  bool get isDueSoon => isWarning;
  bool get isOverdue => status.toUpperCase() == 'OVERDUE';

  String get itemKey =>
      itemCategory ??
      maintenanceRule?.component?.category ??
      maintenanceId;

  String get name =>
      itemName ??
      maintenanceRule?.component?.name ??
      maintenanceRule?.description ??
      '';

  int get effectiveIntervalKm =>
      intervalKm ?? maintenanceRule?.intervalKm ?? 3000;

  VehicleMaintenanceModel copyWith({
    String? id,
    String? vehicleId,
    String? maintenanceId,
    DateTime? lastServiceDate,
    int? lastServiceOdometer,
    int? healthPercentage,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    MaintenanceRuleModel? maintenanceRule,
    VehicleModel? vehicle,
    String? itemName,
    String? itemCategory,
    int? intervalKm,
    int? intervalMonth,
    bool? hasServiceHistory,
  }) {
    return VehicleMaintenanceModel(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      maintenanceId: maintenanceId ?? this.maintenanceId,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      lastServiceOdometer: lastServiceOdometer ?? this.lastServiceOdometer,
      healthPercentage: healthPercentage ?? this.healthPercentage,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      maintenanceRule: maintenanceRule ?? this.maintenanceRule,
      vehicle: vehicle ?? this.vehicle,
      itemName: itemName ?? this.itemName,
      itemCategory: itemCategory ?? this.itemCategory,
      intervalKm: intervalKm ?? this.intervalKm,
      intervalMonth: intervalMonth ?? this.intervalMonth,
      hasServiceHistory: hasServiceHistory ?? hasServiceHistoryFlag,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'maintenance_id': maintenanceId,
      if (lastServiceDate != null)
        'last_service_date': lastServiceDate!.toIso8601String().split('T')[0],
      'last_service_odometer': lastServiceOdometer,
      'health_percentage': healthPercentage,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// JSON for local Hive caching (with metadata & relational joins)
  Map<String, dynamic> toLocalJson() {
    final map = toJson();
    if (itemName != null) map['item_name'] = itemName;
    if (itemCategory != null) map['item_category'] = itemCategory;
    if (intervalKm != null) map['interval_km'] = intervalKm;
    if (intervalMonth != null) map['interval_month'] = intervalMonth;
    if (hasServiceHistoryFlag != null) map['has_service_history'] = hasServiceHistoryFlag;
    if (maintenanceRule != null) map['maintenance_rules'] = maintenanceRule!.toJson();
    return map;
  }

  factory VehicleMaintenanceModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['last_service_date'] != null) {
      parsedDate = DateTime.tryParse(json['last_service_date'].toString());
    }

    final hp = json['health_percentage'];
    final int healthVal = hp is num ? hp.round() : int.tryParse(hp.toString()) ?? 100;

    final odo = json['last_service_odometer'];
    final int odoVal = odo is num ? odo.round() : int.tryParse(odo.toString()) ?? 0;

    final bool? hasHistory = json['has_service_history'] is bool
        ? json['has_service_history'] as bool
        : (json['has_service_history'] != null
            ? json['has_service_history'].toString().toLowerCase() == 'true'
            : null);

    MaintenanceRuleModel? rule;
    if (json['maintenance_rules'] is Map<String, dynamic>) {
      rule = MaintenanceRuleModel.fromJson(json['maintenance_rules'] as Map<String, dynamic>);
    }

    VehicleModel? vehicle;
    if (json['vehicles'] is Map<String, dynamic>) {
      vehicle = VehicleModel.fromJson(json['vehicles'] as Map<String, dynamic>);
    }

    final nameFromRule = rule?.component?.name ?? rule?.description;

    return VehicleMaintenanceModel(
      id: json['id']?.toString() ?? '',
      vehicleId: json['vehicle_id']?.toString() ?? '',
      maintenanceId: json['maintenance_id']?.toString() ?? '',
      lastServiceDate: parsedDate,
      lastServiceOdometer: odoVal,
      healthPercentage: healthVal,
      status: json['status'] as String? ?? 'GOOD',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      maintenanceRule: rule,
      vehicle: vehicle,
      itemName: json['item_name'] as String? ?? nameFromRule,
      itemCategory: json['item_category'] as String? ?? rule?.component?.category,
      intervalKm: (json['interval_km'] as num?)?.toInt() ?? rule?.intervalKm,
      intervalMonth: (json['interval_month'] as num?)?.toInt(),
      hasServiceHistory: hasHistory,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleMaintenanceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          vehicleId == other.vehicleId &&
          maintenanceId == other.maintenanceId &&
          lastServiceOdometer == other.lastServiceOdometer &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^ vehicleId.hashCode ^ maintenanceId.hashCode ^ status.hashCode;
}
