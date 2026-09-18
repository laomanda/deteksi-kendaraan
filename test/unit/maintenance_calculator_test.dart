import 'package:flutter_test/flutter_test.dart';
import 'package:ridecare/features/maintenance/domain/maintenance_calculator.dart';
import 'package:ridecare/features/maintenance/domain/dashboard_maintenance_item.dart';

void main() {
  group('MaintenanceCalculator Unit Tests', () {
    test('Rule: remaining_km > 500 -> GOOD', () {
      final res = MaintenanceCalculator.calculate(
        currentOdometer: 10000,
        intervalKm: 3000,
        lastServiceOdometer: 8000,
      );
      expect(res.nextServiceKm, equals(11000));
      expect(res.remainingKm, equals(1000));
      expect(res.status, equals('GOOD'));
      expect(res.isGood, isTrue);
    });

    test('Rule: remaining_km <= 500 -> WARNING', () {
      final res = MaintenanceCalculator.calculate(
        currentOdometer: 10600,
        intervalKm: 3000,
        lastServiceOdometer: 8000,
      );
      expect(res.nextServiceKm, equals(11000));
      expect(res.remainingKm, equals(400));
      expect(res.status, equals('WARNING'));
      expect(res.isWarning, isTrue);
    });

    test('Rule: remaining_km <= 0 -> OVERDUE', () {
      final res = MaintenanceCalculator.calculate(
        currentOdometer: 11200,
        intervalKm: 3000,
        lastServiceOdometer: 8000,
      );
      expect(res.nextServiceKm, equals(11000));
      expect(res.remainingKm, equals(-200));
      expect(res.status, equals('OVERDUE'));
      expect(res.isOverdue, isTrue);
    });

    test('Formula: next_service_km = current_odometer + interval_km when last service is unknown', () {
      final res = MaintenanceCalculator.calculate(
        currentOdometer: 5000,
        intervalKm: 3000,
      );
      expect(res.nextServiceKm, equals(8000));
      expect(res.remainingKm, equals(3000));
      expect(res.status, equals('GOOD'));
    });

    test('DashboardMaintenanceItem serialization & deserialization', () {
      const item = DashboardMaintenanceItem(
        componentName: 'Oli Mesin',
        description: 'Ganti oli mesin berkala',
        intervalKm: 3000,
        currentOdometer: 10000,
        nextServiceKm: 11000,
        remainingKm: 1000,
        healthPercentage: 80,
        status: 'GOOD',
      );

      final json = item.toJson();
      expect(json['component_name'], equals('Oli Mesin'));
      expect(json['status'], equals('GOOD'));

      final parsed = DashboardMaintenanceItem.fromJson(json);
      expect(parsed.componentName, equals('Oli Mesin'));
      expect(parsed.nextServiceKm, equals(11000));
      expect(parsed.remainingKm, equals(1000));
      expect(parsed.isGood, isTrue);
    });
  });
}
