import 'package:flutter/foundation.dart';
import '../presentation/widgets/vehicle_part_icon_badge.dart';

/// UI Data Contract for Dashboard & Maintenance Cards
/// Satisfies Specification Section 4 & 9:
/// - component_name
/// - description
/// - interval_km
/// - current_odometer
/// - next_service_km
/// - remaining_km
/// - health_percentage
/// - status ('GOOD' | 'WARNING' | 'OVERDUE')
@immutable
class DashboardMaintenanceItem {
  final String componentName;
  final String description;
  final int intervalKm;
  final int currentOdometer;
  final int nextServiceKm;
  final int remainingKm;
  final int healthPercentage;
  final String status; // 'GOOD' | 'WARNING' | 'OVERDUE'
  final String priority; // 'high' | 'medium' | 'low'
  final String assetPath;
  final String? maintenanceId;

  const DashboardMaintenanceItem({
    required this.componentName,
    required this.description,
    required this.intervalKm,
    required this.currentOdometer,
    required this.nextServiceKm,
    required this.remainingKm,
    required this.healthPercentage,
    required this.status,
    this.priority = 'medium',
    this.assetPath = '',
    this.maintenanceId,
  });

  bool get isGood => status.toUpperCase() == 'GOOD';
  bool get isWarning =>
      status.toUpperCase() == 'WARNING' ||
      status.toUpperCase() == 'DUE_SOON' ||
      status.toUpperCase() == 'DUE SOON';
  bool get isOverdue => status.toUpperCase() == 'OVERDUE';

  Map<String, dynamic> toJson() => {
    'component_name': componentName,
    'description': description,
    'interval_km': intervalKm,
    'current_odometer': currentOdometer,
    'next_service_km': nextServiceKm,
    'remaining_km': remainingKm,
    'health_percentage': healthPercentage,
    'status': status,
    'priority': priority,
    'asset_path': assetPath,
    if (maintenanceId != null) 'maintenance_id': maintenanceId,
  };

  factory DashboardMaintenanceItem.fromJson(Map<String, dynamic> json) {
    final name = json['component_name']?.toString() ?? 'Komponen';
    final key = json['component_key']?.toString() ?? name;
    final asset = json['asset_path']?.toString().isNotEmpty == true
        ? json['asset_path'].toString()
        : VehiclePartVisualInfo.resolveSvgAsset(name, category: key);

    return DashboardMaintenanceItem(
      componentName: name,
      description: json['description']?.toString() ?? '',
      intervalKm: (json['interval_km'] as num?)?.toInt() ?? 0,
      currentOdometer: (json['current_odometer'] as num?)?.toInt() ?? 0,
      nextServiceKm: (json['next_service_km'] as num?)?.toInt() ?? 0,
      remainingKm: (json['remaining_km'] as num?)?.toInt() ?? 0,
      healthPercentage: (json['health_percentage'] as num?)?.toInt() ?? 100,
      status: json['status']?.toString() ?? 'GOOD',
      priority: json['priority']?.toString() ?? 'medium',
      assetPath: asset,
      maintenanceId: json['maintenance_id']?.toString(),
    );
  }

  DashboardMaintenanceItem copyWith({
    String? componentName,
    String? description,
    int? intervalKm,
    int? currentOdometer,
    int? nextServiceKm,
    int? remainingKm,
    int? healthPercentage,
    String? status,
    String? priority,
    String? assetPath,
    String? maintenanceId,
  }) {
    return DashboardMaintenanceItem(
      componentName: componentName ?? this.componentName,
      description: description ?? this.description,
      intervalKm: intervalKm ?? this.intervalKm,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      nextServiceKm: nextServiceKm ?? this.nextServiceKm,
      remainingKm: remainingKm ?? this.remainingKm,
      healthPercentage: healthPercentage ?? this.healthPercentage,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assetPath: assetPath ?? this.assetPath,
      maintenanceId: maintenanceId ?? this.maintenanceId,
    );
  }

  @override
  String toString() =>
      'DashboardMaintenanceItem($componentName, next: ${nextServiceKm}km, rem: ${remainingKm}km, status: $status)';
}
