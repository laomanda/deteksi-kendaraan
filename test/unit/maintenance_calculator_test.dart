import 'package:flutter_test/flutter_test.dart';
import 'package:ridecare/features/maintenance/domain/maintenance_calculator.dart';
import 'package:ridecare/features/maintenance/domain/dashboard_maintenance_item.dart';
import 'package:ridecare/features/maintenance/data/models/maintenance_rule_model.dart';

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

    test('Audit scenario: Vario 160 ABS 119371 km with no maintenance history uses current_odometer as baseKm', () {
      final res = MaintenanceCalculator.calculate(
        currentOdometer: 119371,
        intervalKm: 3000,
        lastServiceOdometer: 0,
        hasMaintenanceHistory: false,
      );
      expect(res.nextServiceKm, equals(122371));
      expect(res.remainingKm, equals(3000));
      expect(res.healthPercentage, equals(100));
      expect(res.status, equals('GOOD'));
      expect(res.isGood, isTrue);
      expect(res.isOverdue, isFalse);
    });

    test('Audit scenario: Vehicle with existing maintenance history preserves last_service_odometer as baseKm', () {
      final res = MaintenanceCalculator.calculate(
        currentOdometer: 119371,
        intervalKm: 3000,
        lastServiceOdometer: 115000,
        hasMaintenanceHistory: true,
      );
      expect(res.nextServiceKm, equals(118000));
      expect(res.remainingKm, equals(-1371));
      expect(res.status, equals('OVERDUE'));
      expect(res.isOverdue, isTrue);
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

    test('MaintenanceRuleModel equality compares other properties correctly', () {
      const rule1 = MaintenanceRuleModel(
        id: 'rule-1',
        profileId: 'scooter_cvt',
        componentId: 'comp-1',
        description: 'Ganti Oli',
        intervalKm: 3000,
        priority: 'high',
      );

      const rule2 = MaintenanceRuleModel(
        id: 'rule-1',
        profileId: 'scooter_cvt',
        componentId: 'comp-1',
        description: 'Ganti Oli',
        intervalKm: 3000,
        priority: 'high',
      );

      const rule3DiffProfile = MaintenanceRuleModel(
        id: 'rule-1',
        profileId: 'motorcycle_manual',
        componentId: 'comp-1',
        description: 'Ganti Oli',
        intervalKm: 3000,
        priority: 'high',
      );

      const rule4DiffInterval = MaintenanceRuleModel(
        id: 'rule-1',
        profileId: 'scooter_cvt',
        componentId: 'comp-1',
        description: 'Ganti Oli',
        intervalKm: 4000,
        priority: 'high',
      );

      expect(rule1 == rule2, isTrue);
      expect(rule1.hashCode == rule2.hashCode, isTrue);
      expect(rule1 == rule3DiffProfile, isFalse);
      expect(rule1 == rule4DiffInterval, isFalse);
    });
  });
}
