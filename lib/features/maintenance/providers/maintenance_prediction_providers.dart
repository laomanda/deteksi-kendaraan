import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vehicle/data/models/vehicle_model.dart';
import '../../vehicle/providers/vehicle_provider.dart' hide maintenanceRepositoryProvider;
import '../domain/maintenance_cost_forecast_service.dart';
import '../domain/maintenance_prediction_service.dart';
import 'maintenance_intelligence_providers.dart';

/// Provider predicting maintenance for all items of a vehicle
final maintenancePredictionProvider = Provider.family<
    AsyncValue<List<MaintenancePrediction>>, String>((ref, vehicleId) {
  final vmAsync = ref.watch(vehicleMaintenanceProvider(vehicleId));
  final vehiclesAsync = ref.watch(vehicleListProvider);

  return vmAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (vmList) {
      VehicleModel? vehicle;
      vehiclesAsync.whenData((list) {
        vehicle = list.where((v) => v.id == vehicleId).firstOrNull;
      });

      if (vehicle == null) {
        // Fallback or empty if vehicle not found
        final all = ref.read(vehicleRepositoryProvider).getAllVehicles();
        vehicle = all.where((v) => v.id == vehicleId).firstOrNull;
      }

      if (vehicle == null) {
        return const AsyncValue.data([]);
      }

      final predictions = MaintenancePredictionService.predictVehicleMaintenance(
        vehicle: vehicle!,
        items: vmList,
        prices: null, // Will use default/cached prices via getPriceForMaintenance
      );

      return AsyncValue.data(predictions);
    },
  );
});

/// Provider filtering and returning upcoming maintenance items sorted by urgency
final upcomingMaintenanceProvider = Provider.family<
    AsyncValue<List<MaintenancePrediction>>, String>((ref, vehicleId) {
  final predictionsAsync = ref.watch(maintenancePredictionProvider(vehicleId));

  return predictionsAsync.whenData((list) {
    // Only items that are OVERDUE, DUE SOON, or due within upcoming threshold
    return list.where((p) {
      return p.isOverdue ||
          p.isDueSoon ||
          p.isDueWithinDays(90) ||
          p.remainingKm <= 3000;
    }).toList();
  });
});

/// Provider calculating aggregate upcoming cost for upcoming items
final maintenanceCostForecastProvider = Provider.family<
    AsyncValue<
        ({
          double minTotal,
          double maxTotal,
          int count,
          String formattedRange,
          String formattedCompactRange,
        })>,
    String>((ref, vehicleId) {
  final upcomingAsync = ref.watch(upcomingMaintenanceProvider(vehicleId));

  return upcomingAsync.whenData((items) {
    return MaintenanceCostForecastService.calculateTotalCost(items);
  });
});

/// Provider returning budget forecast breakdown for 30, 90, 180 days horizons
final maintenanceBudgetForecastProvider = Provider.family<
    AsyncValue<Map<int, BudgetForecastHorizon>>, String>((ref, vehicleId) {
  final predictionsAsync = ref.watch(maintenancePredictionProvider(vehicleId));

  return predictionsAsync.whenData((predictions) {
    return MaintenanceCostForecastService.calculateBudgetForecast(predictions);
  });
});
