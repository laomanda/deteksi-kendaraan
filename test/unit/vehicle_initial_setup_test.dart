import 'package:flutter_test/flutter_test.dart';
import 'package:ridecare/features/maintenance/domain/maintenance_calculator.dart';
import 'package:ridecare/features/vehicle/data/models/vehicle_model.dart';
import 'package:ridecare/features/vehicle/domain/vehicle_intelligence_service.dart';

void main() {
  group('Vehicle Initial Condition Setup Tests', () {
    final testVehicle = VehicleModel(
      id: 'test-vario-160',
      brand: 'Honda',
      model: 'Vario 160 ABS',
      vehicleType: 'motorcycle',
      year: 2023,
      currentOdometer: 119371,
      vehicleCategoryId: 'scooter_cvt',
    );

    test('1. Prediksi Otomatis: vehicle is healthy, baseline = currentOdometer, health 100%, never overdue', () {
      final items = VehicleIntelligenceService.generateMaintenanceItems(
        vehicle: testVehicle,
        initialCondition: VehicleInitialCondition.autoPrediction,
      );

      expect(items.isNotEmpty, isTrue);

      for (final item in items) {
        expect(item.healthPercentage, equals(100));
        expect(item.status, equals('GOOD'));
        expect(item.hasServiceHistory, isFalse);

        // Verification through MaintenanceCalculator
        final calc = MaintenanceCalculator.calculate(
          currentOdometer: testVehicle.currentOdometer,
          intervalKm: item.effectiveIntervalKm,
          lastServiceOdometer: item.lastServiceOdometer,
          hasMaintenanceHistory: item.hasServiceHistory,
        );

        // Next service MUST be currentOdometer + intervalKm (for distance-based items)
        if (item.effectiveIntervalKm > 0) {
          expect(calc.nextServiceKm, equals(testVehicle.currentOdometer + item.effectiveIntervalKm));
          expect(calc.remainingKm, equals(item.effectiveIntervalKm));
        }
        expect(calc.healthPercentage, equals(100));
        expect(calc.status, equals('GOOD'));
        expect(calc.isOverdue, isFalse);
      }

      // Specific check for Oli Mesin (interval 3000 KM on Vario 160 ABS 119371 KM)
      final oilItem = items.firstWhere((it) => it.name.toLowerCase().contains('oli mesin'));
      final oilCalc = MaintenanceCalculator.calculate(
        currentOdometer: testVehicle.currentOdometer,
        intervalKm: oilItem.effectiveIntervalKm,
        lastServiceOdometer: oilItem.lastServiceOdometer,
        hasMaintenanceHistory: oilItem.hasServiceHistory,
      );
      expect(oilCalc.nextServiceKm, equals(122371));
      expect(oilCalc.remainingKm, equals(3000));
      expect(oilCalc.status, equals('GOOD'));
    });

    test('2. Input Riwayat Servis: uses last_service_odometer for normal accurate calculation', () {
      final items = VehicleIntelligenceService.generateMaintenanceItems(
        vehicle: testVehicle,
        initialCondition: VehicleInitialCondition.serviceHistory,
        lastServiceOdometer: 115000,
        lastServiceDate: DateTime(2026, 1, 15),
      );

      expect(items.isNotEmpty, isTrue);

      // Check oil item (interval 3000 km) -> next service was 118000 km, now at 119371 km -> OVERDUE
      final oilItem = items.firstWhere((it) => it.name.toLowerCase().contains('oli mesin'));
      expect(oilItem.lastServiceOdometer, equals(115000));
      expect(oilItem.hasServiceHistory, isTrue);

      final oilCalc = MaintenanceCalculator.calculate(
        currentOdometer: testVehicle.currentOdometer,
        intervalKm: oilItem.effectiveIntervalKm,
        lastServiceOdometer: oilItem.lastServiceOdometer,
        hasMaintenanceHistory: oilItem.hasServiceHistory,
      );
      expect(oilCalc.nextServiceKm, equals(118000));
      expect(oilCalc.remainingKm, equals(-1371));
      expect(oilCalc.status, equals('OVERDUE'));

      // Check long-interval item (e.g. CVT belt interval 24000 km or spark plug 8000 km)
      final longItem = items.firstWhere((it) => it.effectiveIntervalKm >= 8000);
      final longCalc = MaintenanceCalculator.calculate(
        currentOdometer: testVehicle.currentOdometer,
        intervalKm: longItem.effectiveIntervalKm,
        lastServiceOdometer: longItem.lastServiceOdometer,
        hasMaintenanceHistory: longItem.hasServiceHistory,
      );
      expect(longCalc.nextServiceKm, equals(115000 + longItem.effectiveIntervalKm));
      expect(longCalc.remainingKm, greaterThan(0));
    });

    test('3. Semua Komponen Kondisi Baik: all items 100% health, baseline = current_odometer', () {
      final car = VehicleModel(
        id: 'test-car-avanza',
        brand: 'Toyota',
        model: 'Avanza 1.5 G CVT',
        vehicleType: 'car',
        year: 2022,
        currentOdometer: 45000,
        vehicleCategoryId: 'car_automatic',
      );

      final items = VehicleIntelligenceService.generateMaintenanceItems(
        vehicle: car,
        initialCondition: VehicleInitialCondition.allGood,
      );

      expect(items.isNotEmpty, isTrue);

      for (final item in items) {
        expect(item.healthPercentage, equals(100));
        expect(item.status, equals('GOOD'));
        expect(item.lastServiceOdometer, equals(45000));
        expect(item.hasServiceHistory, isTrue);

        final calc = MaintenanceCalculator.calculate(
          currentOdometer: car.currentOdometer,
          intervalKm: item.effectiveIntervalKm,
          lastServiceOdometer: item.lastServiceOdometer,
          hasMaintenanceHistory: item.hasServiceHistory,
        );

        if (item.effectiveIntervalKm > 0) {
          expect(calc.nextServiceKm, equals(45000 + item.effectiveIntervalKm));
          expect(calc.remainingKm, equals(item.effectiveIntervalKm));
        }
        expect(calc.healthPercentage, equals(100));
        expect(calc.status, equals('GOOD'));
        expect(calc.isOverdue, isFalse);
      }
    });

    test('VehicleModel.initialConditionOption parsing and default fallback', () {
      final v1 = VehicleModel(
        id: '1',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2021,
        initialCondition: 'service_history',
      );
      expect(v1.initialConditionOption, equals(VehicleInitialCondition.serviceHistory));

      final v2 = VehicleModel(
        id: '2',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2021,
        initialCondition: 'all_good',
      );
      expect(v2.initialConditionOption, equals(VehicleInitialCondition.allGood));

      final v3 = VehicleModel(
        id: '3',
        brand: 'Honda',
        model: 'Beat',
        vehicleType: 'motorcycle',
        year: 2021,
        initialCondition: null,
      );
      expect(v3.initialConditionOption, equals(VehicleInitialCondition.autoPrediction));
    });
  });
}
