import 'package:flutter_test/flutter_test.dart';
import 'package:ridecare/features/maintenance/data/models/maintenance_item_model.dart';
import 'package:ridecare/features/maintenance/data/models/vehicle_maintenance_model.dart';
import 'package:ridecare/features/maintenance/domain/health_calculation_service.dart';
import 'package:ridecare/features/maintenance/domain/maintenance_prediction_service.dart';
import 'package:ridecare/features/vehicle/data/models/vehicle_model.dart';
import 'package:ridecare/features/vehicle/domain/vehicle_intelligence_service.dart';

void main() {
  group('Maintenance UX Presentation Polish Tests', () {
    final newVehicle = VehicleModel(
      id: 'honda-vario-160-abs',
      brand: 'Honda',
      model: 'Vario 160 ABS',
      vehicleType: 'motorcycle',
      year: 2023,
      currentOdometer: 119371,
      vehicleCategoryId: 'scooter_cvt',
    );

    test('Scenario 1: New vehicle with Prediksi Otomatis (No service history)', () {
      final items = VehicleIntelligenceService.generateMaintenanceItems(
        vehicle: newVehicle,
        initialCondition: VehicleInitialCondition.autoPrediction,
      );

      final oilItem = items.firstWhere((it) => it.name.toLowerCase().contains('oli mesin'));
      expect(oilItem.hasServiceHistory, isFalse);
      expect(oilItem.lastServiceOdometer, equals(0));

      // 1. Check ComponentHealthResult UX presentation
      final healthItem = MaintenanceItemModel(
        id: 'oil-1',
        vehicleId: newVehicle.id,
        componentType: oilItem.name,
        lastServiceDate: oilItem.lastServiceDate ?? DateTime(2026, 9, 18),
        lastServiceKm: oilItem.lastServiceOdometer.toDouble(),
        intervalKm: oilItem.effectiveIntervalKm.toDouble(),
        intervalDays: 90,
      );

      final healthResult = HealthCalculationService.calculateComponentHealth(
        item: healthItem,
        currentOdometer: 119371,
        hasMaintenanceHistory: false,
      );

      expect(healthResult.hasServiceHistory, isFalse);
      expect(healthResult.userFacingStatusLabel, equals('Kondisi prima'));
      expect(healthResult.userFacingRemainingText, contains('Disarankan dalam'));
      expect(healthResult.userFacingRemainingText, contains('3.000'));
      expect(healthResult.userFacingHistoryText, startsWith('Mulai pemantauan:'));
      expect(healthResult.userFacingHistoryText, contains('119.371'));
      expect(healthResult.userFacingHistoryStateTitle, equals('Pemantauan dimulai dari odometer kendaraan'));

      // 2. Check MaintenancePrediction UX presentation
      final vm = VehicleMaintenanceModel(
        id: 'oil-vm-1',
        vehicleId: newVehicle.id,
        maintenanceId: 'oil_engine',
        itemName: oilItem.name,
        lastServiceDate: oilItem.lastServiceDate ?? DateTime(2026, 9, 18),
        lastServiceOdometer: 119371,
        healthPercentage: 100,
        status: 'GOOD',
        intervalKm: 3000,
        hasServiceHistory: false,
      );

      final prediction = MaintenancePrediction(
        item: vm,
        componentName: 'Oli Mesin',
        category: 'Mesin',
        currentHealth: 100,
        remainingKm: 3000,
        usedKm: 0,
        nextServiceOdometer: 122371,
        remainingDays: 90,
        estimatedNextServiceDate: DateTime(2026, 12, 18),
        status: 'GOOD',
        urgencyGroup: 'UPCOMING',
        whicheverComesFirstText: 'Berdasarkan kilometer atau waktu',
        partMin: 50000,
        partMax: 80000,
        laborMin: 15000,
        laborMax: 25000,
        totalMin: 65000,
        totalMax: 105000,
      );

      expect(prediction.userFacingStatusLabel, equals('Kondisi prima'));
      expect(prediction.userFacingRemainingText, equals('Disarankan dalam 3.000 km lagi'));
      expect(prediction.userFacingHistoryText, startsWith('Mulai pemantauan:'));
      expect(prediction.userFacingHistoryText, contains('119.371'));
      expect(prediction.userFacingHistoryStateTitle, equals('Pemantauan dimulai dari odometer kendaraan'));
    });

    test('Scenario 2: Vehicle with real service history', () {
      final vm = VehicleMaintenanceModel(
        id: 'oil-vm-history',
        vehicleId: newVehicle.id,
        maintenanceId: 'oil_engine',
        itemName: 'Oli Mesin',
        lastServiceDate: DateTime(2026, 9, 20),
        lastServiceOdometer: 120000,
        healthPercentage: 90,
        status: 'GOOD',
        intervalKm: 3000,
        hasServiceHistory: true,
      );

      final prediction = MaintenancePrediction(
        item: vm,
        componentName: 'Oli Mesin',
        category: 'Mesin',
        currentHealth: 90,
        remainingKm: 2700,
        usedKm: 300,
        nextServiceOdometer: 123000,
        remainingDays: 80,
        estimatedNextServiceDate: DateTime(2026, 12, 10),
        status: 'GOOD',
        urgencyGroup: 'UPCOMING',
        whicheverComesFirstText: 'Berdasarkan kilometer atau waktu',
        partMin: 50000,
        partMax: 80000,
        laborMin: 15000,
        laborMax: 25000,
        totalMin: 65000,
        totalMax: 105000,
      );

      expect(prediction.userFacingStatusLabel, equals('Kondisi prima'));
      expect(prediction.userFacingRemainingText, equals('Disarankan dalam 2.700 km lagi'));
      expect(prediction.userFacingHistoryText, startsWith('Servis terakhir:'));
      expect(prediction.userFacingHistoryText, contains('120.000'));
      expect(prediction.userFacingHistoryStateTitle, equals('Servis terakhir tercatat'));

      final healthItem = MaintenanceItemModel(
        id: 'oil-hist-entity',
        vehicleId: newVehicle.id,
        componentType: 'Oli Mesin',
        lastServiceDate: DateTime(2026, 9, 20),
        lastServiceKm: 120000,
        intervalKm: 3000,
        intervalDays: 90,
      );
      final healthResult = HealthCalculationService.calculateComponentHealth(
        item: healthItem,
        currentOdometer: 120300,
        hasMaintenanceHistory: true,
      );
      expect(healthResult.hasServiceHistory, isTrue);
      expect(healthResult.userFacingHistoryText, startsWith('Servis terakhir:'));
      expect(healthResult.userFacingHistoryText, contains('120.000'));
      expect(healthResult.userFacingHistoryStateTitle, equals('Servis terakhir tercatat'));
    });

    test('Scenario 3: Overdue vehicle component', () {
      final vmOverdue = VehicleMaintenanceModel(
        id: 'oil-vm-overdue',
        vehicleId: newVehicle.id,
        maintenanceId: 'oil_engine',
        itemName: 'Oli Mesin',
        lastServiceDate: DateTime(2026, 1, 1),
        lastServiceOdometer: 110000,
        healthPercentage: 0,
        status: 'OVERDUE',
        intervalKm: 3000,
        hasServiceHistory: true,
      );

      final predictionOverdue = MaintenancePrediction(
        item: vmOverdue,
        componentName: 'Oli Mesin',
        category: 'Mesin',
        currentHealth: 0,
        remainingKm: -6371,
        usedKm: 9371,
        nextServiceOdometer: 113000,
        remainingDays: -30,
        estimatedNextServiceDate: DateTime(2026, 4, 1),
        status: 'OVERDUE',
        urgencyGroup: 'URGENT',
        whicheverComesFirstText: 'Berdasarkan kilometer atau waktu',
        partMin: 50000,
        partMax: 80000,
        laborMin: 15000,
        laborMax: 25000,
        totalMin: 65000,
        totalMax: 105000,
      );

      expect(predictionOverdue.userFacingStatusLabel, equals('Perlu dilakukan segera'));
      expect(predictionOverdue.userFacingRemainingText, equals('Perlu dilakukan segera (Lewat jadwal)'));

      final healthItem = MaintenanceItemModel(
        id: 'oil-overdue-entity',
        vehicleId: newVehicle.id,
        componentType: 'Oli Mesin',
        lastServiceDate: DateTime(2026, 1, 1),
        lastServiceKm: 110000,
        intervalKm: 3000,
        intervalDays: 90,
      );
      final healthResult = HealthCalculationService.calculateComponentHealth(
        item: healthItem,
        currentOdometer: 119371,
        hasMaintenanceHistory: true,
      );
      expect(healthResult.isCritical, isTrue);
      expect(healthResult.userFacingStatusLabel, equals('Perlu dilakukan segera'));
      expect(healthResult.userFacingRemainingText, equals('Perlu dilakukan segera (Lewat jadwal)'));
    });
  });
}
