import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../data/models/maintenance_item_model.dart';
import '../../domain/health_calculation_service.dart';
import '../../domain/maintenance_prediction_service.dart';
import '../../providers/maintenance_intelligence_providers.dart';
import '../../providers/maintenance_prediction_providers.dart';
import '../../../shared/providers/repository_providers.dart'
    hide maintenanceRepositoryProvider;

class MaintenanceStatusState {
  final List<ComponentHealthResult> results;
  final double aggregateHealthScore;
  final List<ComponentHealthResult> priorityComponents;
  final int criticalCount;
  final int warningCount;

  const MaintenanceStatusState({
    required this.results,
    required this.aggregateHealthScore,
    required this.priorityComponents,
    required this.criticalCount,
    required this.warningCount,
  });

  bool get hasUrgentIssues => criticalCount > 0 || warningCount > 0;

  String? get warningMessage {
    final totalNeedingAttention = criticalCount + warningCount;
    if (totalNeedingAttention > 0) {
      return '$totalNeedingAttention komponen perlu perhatian segera';
    }
    return null;
  }
}

class MaintenanceStatusNotifier
    extends AutoDisposeAsyncNotifier<MaintenanceStatusState> {
  @override
  FutureOr<MaintenanceStatusState> build() async {
    final activeVehicle = ref.watch(activeVehicleProvider);
    if (activeVehicle == null) {
      return const MaintenanceStatusState(
        results: [],
        aggregateHealthScore: 100.0,
        priorityComponents: [],
        criticalCount: 0,
        warningCount: 0,
      );
    }

    final repo = ref.watch(maintenanceRepositoryProvider);

    // Watch the canonical VehicleMaintenance list & predictions to stay reactive
    final vmAsync = ref.watch(vehicleMaintenanceProvider(activeVehicle.id));
    final predictionsAsync = ref.watch(maintenancePredictionProvider(activeVehicle.id));

    // Get the vehicle maintenance items (cached or generated)
    final vmList = vmAsync.value ??
        repo.getCachedVehicleMaintenance(activeVehicle.id) ??
        await repo.getVehicleMaintenance(
          activeVehicle.id,
          vehicleType: activeVehicle.vehicleType,
          vehicleCategoryId: activeVehicle.vehicleCategoryId,
          currentOdometer: activeVehicle.currentKilometer.toInt(),
        );

    // Obtain predictions using the unified prediction service
    final List<MaintenancePrediction> predictions = predictionsAsync.value ??
        MaintenancePredictionService.predictVehicleMaintenance(
          vehicle: activeVehicle,
          items: vmList,
        );

    final now = DateTime.now();

    // Map predictions to ComponentHealthResult ensuring 100% unified source of truth
    final results = predictions.map((p) {
      final fraction = (p.currentHealth / 100.0).clamp(0.0, 1.0);
      final deltaKm = math.max(0.0, activeVehicle.currentKilometer - p.item.lastServiceOdometer);
      final deltaDays = p.item.lastServiceDate != null
          ? math.max(0, now.difference(p.item.lastServiceDate!).inDays)
          : 0;

      final componentKey = (p.item.itemCategory != null && p.item.itemCategory!.isNotEmpty)
          ? p.item.itemCategory!
          : (p.category.isNotEmpty && p.category != 'general'
              ? p.category
              : p.componentName);

      final itemModel = MaintenanceItemModel(
        id: p.item.id,
        vehicleId: p.item.vehicleId,
        componentType: componentKey,
        intervalKm: (p.item.intervalKm ?? 3000).toDouble(),
        intervalDays: (p.item.intervalMonth ?? 3) * 30,
        lastServiceKm: p.item.lastServiceOdometer.toDouble(),
        lastServiceDate: p.item.lastServiceDate ?? now,
      );

      return ComponentHealthResult(
        item: itemModel,
        deltaKm: deltaKm,
        deltaDays: deltaDays,
        rKm: fraction,
        rWaktu: fraction,
        healthPercentage: p.currentHealth,
        remainingKm: p.remainingKm.toDouble(),
        remainingDays: p.remainingDays,
      );
    }).toList();

    // Calculate aggregate score matching dashboard
    final healthSummaryAsync = ref.watch(maintenanceHealthProvider(activeVehicle.id));
    final aggregate = healthSummaryAsync.value?.overallScore ??
        HealthCalculationService.calculateVehicleAggregateScore(results);

    // Sort priority
    final sortedForPriority = List<ComponentHealthResult>.from(results)
      ..sort((a, b) => a.healthPercentage.compareTo(b.healthPercentage));

    final priority = sortedForPriority
        .where((r) => r.isCritical || r.isWarning || r.healthPercentage < 75.0)
        .take(3)
        .toList();

    int critical = 0;
    int warning = 0;
    for (final r in results) {
      if (r.isCritical) {
        critical++;
      } else if (r.isWarning) {
        warning++;
      }
    }

    return MaintenanceStatusState(
      results: results,
      aggregateHealthScore: aggregate.clamp(0.0, 100.0),
      priorityComponents: priority,
      criticalCount: critical,
      warningCount: warning,
    );
  }

  Future<void> recordService({
    required String componentType,
    required double serviceKm,
    required DateTime serviceDate,
    required double cost,
    required String notes,
    String? vehicleId,
    int? customIntervalKm,
  }) async {
    final targetVehicleId = vehicleId ?? ref.read(activeVehicleProvider)?.id;
    if (targetVehicleId == null) return;

    final repo = ref.read(maintenanceRepositoryProvider);
    final vmNotifier = ref.read(vehicleMaintenanceProvider(targetVehicleId).notifier);
    final activeNotifier = ref.read(activeVehicleProvider.notifier);
    final vehicle = ref.read(vehicleListProvider).where((v) => v.id == targetVehicleId).firstOrNull;
    final vehicleRepo = ref.read(vehicleRepositoryProvider);
    final isActive = ref.read(activeVehicleProvider)?.id == targetVehicleId;

    await repo.recordService(
      vehicleId: targetVehicleId,
      componentType: componentType,
      serviceKm: serviceKm,
      serviceDate: serviceDate,
      cost: cost,
      notes: notes,
      customIntervalKm: customIntervalKm,
    );

    // Refresh VehicleMaintenance StateNotifier
    await vmNotifier.refresh();

    // If serviceKm is greater than current vehicle odometer, update vehicle odometer
    if (vehicle != null && serviceKm > vehicle.currentKilometer) {
      await vehicleRepo.updateOdometer(targetVehicleId, serviceKm);
      if (isActive) {
        await activeNotifier.updateOdometer(serviceKm);
      }
    }

    // Invalidate dependent providers so Dasbor and Tab Kesehatan update synchronously
    ref.invalidate(vehicleListProvider);
    ref.invalidate(maintenancePredictionProvider(targetVehicleId));
    ref.invalidate(upcomingMaintenanceProvider(targetVehicleId));
    ref.invalidate(maintenanceHealthProvider(targetVehicleId));
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidateSelf();
  }
}

final maintenanceStatusProvider = AutoDisposeAsyncNotifierProvider<
    MaintenanceStatusNotifier, MaintenanceStatusState>(() {
  return MaintenanceStatusNotifier();
});
