import 'package:flutter_test/flutter_test.dart';
import 'package:ridecare/features/maintenance/data/models/maintenance_item_model.dart';
import 'package:ridecare/features/maintenance/domain/health_calculation_service.dart';

void main() {
  group('HealthCalculationService Unit Tests (PRD Section 7.3.3 & 18.1)', () {
    test('100% health when last service equals current odometer and date', () {
      final now = DateTime.now();
      final item = MaintenanceItemModel(
        id: 'test_oil_1',
        vehicleId: 'v1',
        componentType: 'engine_oil',
        intervalKm: 2500.0,
        intervalDays: 90,
        lastServiceKm: 10000.0,
        lastServiceDate: now,
      );

      final result = HealthCalculationService.calculateComponentHealth(
        item: item,
        currentOdometer: 10000.0,
        currentDate: now,
      );

      expect(result.deltaKm, 0.0);
      expect(result.deltaDays, 0);
      expect(result.rKm, 1.0);
      expect(result.rWaktu, 1.0);
      expect(result.healthPercentage, 100.0);
      expect(result.remainingKm, 2500.0);
      expect(result.remainingDays, 90);
      expect(result.isOptimal, isTrue);
    });

    test('Clamps to 0% and non-negative remaining values when odometer exceeds interval', () {
      final now = DateTime.now();
      final item = MaintenanceItemModel(
        id: 'test_oil_2',
        vehicleId: 'v1',
        componentType: 'engine_oil',
        intervalKm: 2500.0,
        intervalDays: 90,
        lastServiceKm: 10000.0,
        lastServiceDate: now.subtract(const Duration(days: 30)),
      );

      // Current odometer jumps by 3000 km (beyond 2500 km interval)
      final result = HealthCalculationService.calculateComponentHealth(
        item: item,
        currentOdometer: 13000.0,
        currentDate: now,
      );

      expect(result.deltaKm, 3000.0);
      expect(result.rKm, 0.0); // Clamped, not negative
      expect(result.healthPercentage, 0.0);
      expect(result.remainingKm, 0.0);
      expect(result.isCritical, isTrue);
    });

    test('Handles time-only degradation for battery (intervalKm = 0)', () {
      final now = DateTime.now();
      final item = MaintenanceItemModel(
        id: 'test_battery_1',
        vehicleId: 'v1',
        componentType: 'battery',
        intervalKm: 0.0,
        intervalDays: 548, // 18 months
        lastServiceKm: 5000.0,
        lastServiceDate: now.subtract(const Duration(days: 274)), // half life
      );

      final result = HealthCalculationService.calculateComponentHealth(
        item: item,
        currentOdometer: 20000.0, // High mileage should not degrade battery
        currentDate: now,
      );

      expect(result.rKm, 1.0); // Ignored
      expect(result.deltaDays, 274);
      expect(result.healthPercentage, closeTo(50.0, 1.0));
      expect(result.isModerate, isTrue);
    });

    test('Conservative degradation heuristic sets unknown history component to 25% health', () {
      final now = DateTime.now();
      const currentOdo = 15000.0;
      const intervalKm = 8000.0;
      const intervalDays = 365;

      final heuristic = HealthCalculationService.calculateUnknownHistoryInitialCondition(
        currentOdometer: currentOdo,
        intervalKm: intervalKm,
        intervalDays: intervalDays,
        now: now,
      );

      final item = MaintenanceItemModel(
        id: 'test_heuristic',
        vehicleId: 'v1',
        componentType: 'spark_plug',
        intervalKm: intervalKm,
        intervalDays: intervalDays,
        lastServiceKm: heuristic.lastServiceKm,
        lastServiceDate: heuristic.lastServiceDate,
      );

      final result = HealthCalculationService.calculateComponentHealth(
        item: item,
        currentOdometer: currentOdo,
        currentDate: now,
      );

      expect(result.healthPercentage, closeTo(25.0, 0.5));
      expect(result.isWarning, isTrue);
    });

    test('Vehicle aggregate score calculates arithmetic mean accurately', () {
      final now = DateTime.now();
      final item1 = MaintenanceItemModel(
        id: '1',
        vehicleId: 'v1',
        componentType: 'engine_oil',
        intervalKm: 2500,
        intervalDays: 90,
        lastServiceKm: 10000,
        lastServiceDate: now,
      );
      final item2 = MaintenanceItemModel(
        id: '2',
        vehicleId: 'v1',
        componentType: 'gear_oil',
        intervalKm: 8000,
        intervalDays: 180,
        lastServiceKm: 6000,
        lastServiceDate: now,
      );

      final r1 = HealthCalculationService.calculateComponentHealth(
        item: item1,
        currentOdometer: 10000,
        currentDate: now,
      ); // 100%
      final r2 = HealthCalculationService.calculateComponentHealth(
        item: item2,
        currentOdometer: 10000,
        currentDate: now,
      ); // delta 4000km / 8000km = 50%

      final score = HealthCalculationService.calculateVehicleAggregateScore([r1, r2]);
      expect(score, closeTo(75.0, 0.1));
    });
  });
}
