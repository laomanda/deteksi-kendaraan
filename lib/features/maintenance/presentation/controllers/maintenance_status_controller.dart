import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/health_calculation_service.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../shared/providers/repository_providers.dart';

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
    final items = repo.getItemsForVehicle(activeVehicle.id);

    final results = items.map((item) {
      return HealthCalculationService.calculateComponentHealth(
        item: item,
        currentOdometer: activeVehicle.currentKilometer,
      );
    }).toList();

    // Sort by health ascending so worst components appear first
    final sortedForPriority = List<ComponentHealthResult>.from(results)
      ..sort((a, b) => a.healthPercentage.compareTo(b.healthPercentage));

    final priority = sortedForPriority.take(2).toList();
    final aggregate = HealthCalculationService.calculateVehicleAggregateScore(results);

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
      aggregateHealthScore: aggregate,
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
  }) async {
    final activeVehicle = ref.read(activeVehicleProvider);
    if (activeVehicle == null) return;

    final repo = ref.read(maintenanceRepositoryProvider);
    await repo.recordService(
      vehicleId: activeVehicle.id,
      componentType: componentType,
      serviceKm: serviceKm,
      serviceDate: serviceDate,
      cost: cost,
      notes: notes,
    );

    // If serviceKm is greater than current vehicle odometer, update vehicle odometer
    if (serviceKm > activeVehicle.currentKilometer) {
      await ref.read(activeVehicleProvider.notifier).updateOdometer(serviceKm);
    }

    // Trigger rebuild
    ref.invalidateSelf();
  }
}

final maintenanceStatusProvider = AutoDisposeAsyncNotifierProvider<
    MaintenanceStatusNotifier, MaintenanceStatusState>(() {
  return MaintenanceStatusNotifier();
});
