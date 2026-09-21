import 'package:flutter/foundation.dart';
import '../../vehicle/data/models/vehicle_model.dart';
import '../../vehicle/domain/vehicle_intelligence_service.dart';
import '../data/models/vehicle_maintenance_model.dart';
import '../presentation/widgets/vehicle_part_icon_badge.dart';

/// Clean Data Transfer Object (DTO) for Vehicle Maintenance Component
/// Conforms strictly to requirements:
/// - component_name
/// - interval_km
/// - priority ("high" | "medium" | "low")
/// - asset_path ("assets/icons/maintenance/...")
class VehicleMaintenanceComponentDto {
  final String componentName;
  final int intervalKm;
  final int intervalMonth;
  final String priority; // 'high' | 'medium' | 'low'
  final String assetPath;
  final String componentKey;
  final int lastServiceOdometer;
  final DateTime? lastServiceDate;
  final double healthPercentage;
  final String status; // 'GOOD' | 'DUE SOON' | 'OVERDUE'

  const VehicleMaintenanceComponentDto({
    required this.componentName,
    required this.intervalKm,
    required this.intervalMonth,
    required this.priority,
    required this.assetPath,
    required this.componentKey,
    this.lastServiceOdometer = 0,
    this.lastServiceDate,
    this.healthPercentage = 100.0,
    this.status = 'GOOD',
  });

  Map<String, dynamic> toJson() => {
        'component_name': componentName,
        'interval_km': intervalKm,
        'interval_month': intervalMonth,
        'priority': priority,
        'asset_path': assetPath,
        'component_key': componentKey,
        'last_service_odometer': lastServiceOdometer,
        if (lastServiceDate != null)
          'last_service_date': lastServiceDate!.toIso8601String(),
        'health_percentage': healthPercentage,
        'status': status,
      };

  factory VehicleMaintenanceComponentDto.fromModel(VehicleMaintenanceModel model) {
    final name = model.itemName ?? model.maintenanceId;
    final key = model.itemCategory ?? model.maintenanceId;
    final asset = VehiclePartVisualInfo.resolveSvgAsset(name, category: key);

    String priorityStr = 'medium';
    final lk = key.toLowerCase();
    if (lk.contains('oil') ||
        lk.contains('oli') ||
        lk.contains('brake') ||
        lk.contains('rem') ||
        lk.contains('belt') ||
        lk.contains('chain') ||
        lk.contains('rantai') ||
        lk.contains('battery') ||
        lk.contains('aki')) {
      priorityStr = 'high';
    }

    return VehicleMaintenanceComponentDto(
      componentName: name,
      intervalKm: model.intervalKm ?? 0,
      intervalMonth: model.intervalMonth ?? 0,
      priority: priorityStr,
      assetPath: asset,
      componentKey: key,
      lastServiceOdometer: model.lastServiceOdometer,
      lastServiceDate: model.lastServiceDate,
      healthPercentage: model.healthPercentage.toDouble(),
      status: model.status,
    );
  }
}

/// Clean Service Layer implementing the exact data pipeline:
/// User Vehicle -> vehicle_catalog -> maintenance_profile_id -> maintenance_rules -> components
class VehicleMaintenanceService {
  VehicleMaintenanceService._();

  /// Resolve maintenance profile ID from vehicle metadata
  static String resolveMaintenanceProfileId(VehicleModel vehicle) {
    if (vehicle.vehicleCategoryId != null &&
        vehicle.vehicleCategoryId!.trim().isNotEmpty) {
      return vehicle.vehicleCategoryId!;
    }
    return VehicleIntelligenceService.inferCategory(
      vehicleType: vehicle.vehicleType,
      brand: vehicle.brand,
      model: vehicle.model,
      transmission: vehicle.transmission,
      fuelType: vehicle.fuelType,
    );
  }

  /// Evaluates whether a component is strictly forbidden for a specific category profile
  static bool isForbiddenComponent({
    required String profileId,
    required String componentKey,
    required String componentName,
    required String maintenanceId,
  }) {
    final k = componentKey.toLowerCase();
    final n = componentName.toLowerCase();
    final m = maintenanceId.toLowerCase();

    switch (profileId) {
      case 'scooter_cvt':
        // Scooter CVT MUST NEVER have Chain, Manual Clutch, or Sprockets
        if (k.contains('chain') ||
            k.contains('clutch_plate') ||
            k.contains('sprocket') ||
            n.contains('rantai') ||
            n.contains('kopling manual') ||
            n.contains('gir depan') ||
            m.contains('chain') ||
            m.contains('clutch-plate') ||
            m.contains('sprocket')) {
          return true;
        }
        break;

      case 'motorcycle_manual':
      case 'sport_motorcycle':
        // Manual Motorcycle MUST NEVER have CVT Belt, CVT Rollers, or Gear Oil
        if (k.contains('cvt') ||
            k.contains('gear_oil') ||
            n.contains('cvt') ||
            n.contains('roller') ||
            n.contains('gardan') ||
            m.contains('cvt') ||
            m.contains('gear-oil')) {
          return true;
        }
        break;

      case 'car_automatic':
        // Automatic Car MUST NEVER have Manual Clutch Plate or MT Fluid
        if (k.contains('clutch_plate') ||
            k.contains('mt_fluid') ||
            n.contains('kopling manual') ||
            n.contains('transmisi manual') ||
            n.contains('filter solar')) {
          return true;
        }
        break;

      case 'car_manual':
        // Manual Car MUST NEVER have Automatic Transmission Fluid (ATF)
        if (k.contains('at_fluid') ||
            n.contains('transmisi matic') ||
            n.contains('atf') ||
            n.contains('filter solar')) {
          return true;
        }
        break;

      case 'car_diesel':
        // Diesel Car MUST NEVER have Gasoline Spark Plugs
        if (n.contains('busi') && !n.contains('glow') && !n.contains('pemanas')) {
          return true;
        }
        break;

      default:
        break;
    }

    return false;
  }

  /// Sanitizes and validates a list of maintenance items against the vehicle's maintenance profile
  static List<VehicleMaintenanceModel> sanitizeAndValidate({
    required VehicleModel vehicle,
    required List<VehicleMaintenanceModel> rawItems,
  }) {
    final profileId = resolveMaintenanceProfileId(vehicle);

    if (rawItems.isEmpty) {
      return VehicleIntelligenceService.generateMaintenanceItems(vehicle: vehicle);
    }

    // Purge any forbidden components for this profile
    final validItems = rawItems.where((it) {
      final isForbidden = isForbiddenComponent(
        profileId: profileId,
        componentKey: it.itemCategory ?? '',
        componentName: it.itemName ?? '',
        maintenanceId: it.maintenanceId,
      );
      if (isForbidden) {
        debugPrint(
            'VehicleMaintenanceService: Purged forbidden component "${it.itemName}" for profile "$profileId"');
        return false;
      }
      return true;
    }).toList();

    return validItems;
  }

  /// Returns structured DTOs for a vehicle
  static List<VehicleMaintenanceComponentDto> getVehicleMaintenanceComponents(
    VehicleModel vehicle,
    List<VehicleMaintenanceModel> models,
  ) {
    final sanitized = sanitizeAndValidate(vehicle: vehicle, rawItems: models);
    return sanitized
        .map((m) => VehicleMaintenanceComponentDto.fromModel(m))
        .toList();
  }
}
