import 'package:flutter_test/flutter_test.dart';
import 'package:ridecare/features/maintenance/data/models/vehicle_maintenance_model.dart';
import 'package:ridecare/features/maintenance/domain/vehicle_maintenance_service.dart';
import 'package:ridecare/features/vehicle/data/models/vehicle_model.dart';

void main() {
  group('VehicleMaintenanceService - Strict Pipeline & DTO Tests', () {
    test('Scenario: Honda Vario 160 ABS 2024 (scooter_cvt) - Only CVT components, ZERO Manual components', () {
      final vario = VehicleModel(
        id: 'vario-160-uuid',
        vehicleType: 'motorcycle',
        brand: 'Honda',
        model: 'Vario 160 ABS',
        year: 2024,
        licensePlate: 'B 1600 VAR',
        currentOdometer: 5000,
        vehicleCategoryId: 'scooter_cvt',
      );

      final profileId = VehicleMaintenanceService.resolveMaintenanceProfileId(vario);
      expect(profileId, equals('scooter_cvt'));

      // Generate items through pipeline
      final items = VehicleMaintenanceService.sanitizeAndValidate(
        vehicle: vario,
        rawItems: [],
      );

      final componentNames = items.map((e) => e.itemName?.toLowerCase() ?? '').toList();

      // Check Allowed items
      expect(componentNames.any((n) => n.contains('oli mesin') || n.contains('engine oil')), isTrue);
      expect(componentNames.any((n) => n.contains('gardan') || n.contains('gear oil')), isTrue);
      expect(componentNames.any((n) => n.contains('v-belt') || n.contains('cvt belt')), isTrue);
      expect(componentNames.any((n) => n.contains('roller')), isTrue);
      expect(componentNames.any((n) => n.contains('rem')), isTrue);
      expect(componentNames.any((n) => n.contains('ban')), isTrue);
      expect(componentNames.any((n) => n.contains('aki') || n.contains('battery')), isTrue);

      // Check Forbidden items - MUST NEVER EXIST
      expect(componentNames.any((n) => n.contains('rantai') || n.contains('chain')), isFalse);
      expect(componentNames.any((n) => n.contains('kopling manual') || n.contains('clutch plate')), isFalse);
    });

    test('Scenario: Motorcycle Manual - Only Manual components, ZERO CVT components', () {
      final manualMotor = VehicleModel(
        id: 'cb150-uuid',
        vehicleType: 'motorcycle',
        brand: 'Honda',
        model: 'CB150R',
        year: 2023,
        licensePlate: 'B 1500 CBR',
        currentOdometer: 12000,
        vehicleCategoryId: 'motorcycle_manual',
      );

      final profileId = VehicleMaintenanceService.resolveMaintenanceProfileId(manualMotor);
      expect(profileId, equals('motorcycle_manual'));

      final items = VehicleMaintenanceService.sanitizeAndValidate(
        vehicle: manualMotor,
        rawItems: [],
      );

      final componentNames = items.map((e) => e.itemName?.toLowerCase() ?? '').toList();

      // Allowed
      expect(componentNames.any((n) => n.contains('oli mesin') || n.contains('engine oil')), isTrue);
      expect(componentNames.any((n) => n.contains('rantai') || n.contains('chain')), isTrue);
      expect(componentNames.any((n) => n.contains('kopling') || n.contains('clutch')), isTrue);
      expect(componentNames.any((n) => n.contains('rem')), isTrue);
      expect(componentNames.any((n) => n.contains('ban')), isTrue);
      expect(componentNames.any((n) => n.contains('aki') || n.contains('battery')), isTrue);

      // Forbidden
      expect(componentNames.any((n) => n.contains('v-belt') || n.contains('cvt')), isFalse);
      expect(componentNames.any((n) => n.contains('roller')), isFalse);
      expect(componentNames.any((n) => n.contains('gardan') || n.contains('gear oil')), isFalse);
    });

    test('Scenario: Clean DTO Extraction returns expected fields', () {
      final vario = VehicleModel(
        id: 'vario-160-dto-test',
        vehicleType: 'motorcycle',
        brand: 'Honda',
        model: 'Vario 160 ABS',
        year: 2024,
        licensePlate: 'B 1600 VAR',
        currentOdometer: 5000,
        vehicleCategoryId: 'scooter_cvt',
      );

      final raw = [
        VehicleMaintenanceModel(
          id: 'vm-1',
          vehicleId: vario.id,
          maintenanceId: 'engine_oil',
          itemName: 'Oli Mesin',
          itemCategory: 'engine_oil',
          intervalKm: 3000,
          intervalMonth: 3,
          healthPercentage: 85,
          status: 'GOOD',
          lastServiceOdometer: 4500,
        ),
      ];

      final dtos = VehicleMaintenanceService.getVehicleMaintenanceComponents(vario, raw);
      expect(dtos.length, equals(1));
      
      final dto = dtos.first;
      expect(dto.componentName, equals('Oli Mesin'));
      expect(dto.intervalKm, equals(3000));
      expect(dto.priority, isIn(['high', 'medium', 'low']));
      expect(dto.assetPath, contains('assets/maintenance/'));

      final json = dto.toJson();
      expect(json['component_name'], equals('Oli Mesin'));
      expect(json['interval_km'], equals(3000));
      expect(json['priority'], isIn(['high', 'medium', 'low']));
      expect(json['asset_path'], contains('assets/maintenance/'));
    });

    test('Scenario: Contaminated raw list gets purged when processed', () {
      final vario = VehicleModel(
        id: 'vario-160-contaminated',
        vehicleType: 'motorcycle',
        brand: 'Honda',
        model: 'Vario 160 ABS',
        year: 2024,
        licensePlate: 'B 1600 VAR',
        currentOdometer: 5000,
        vehicleCategoryId: 'scooter_cvt',
      );

      final contaminatedRaw = [
        VehicleMaintenanceModel(
          id: 'vm-1',
          vehicleId: vario.id,
          maintenanceId: 'engine_oil',
          itemName: 'Oli Mesin',
          itemCategory: 'engine_oil',
          intervalKm: 3000,
          healthPercentage: 80,
          status: 'GOOD',
        ),
        VehicleMaintenanceModel(
          id: 'vm-2',
          vehicleId: vario.id,
          maintenanceId: 'chain_sprocket',
          itemName: 'Rantai Motor & Gear',
          itemCategory: 'chain_sprocket',
          intervalKm: 15000,
          healthPercentage: 80,
          status: 'GOOD',
        ),
        VehicleMaintenanceModel(
          id: 'vm-3',
          vehicleId: vario.id,
          maintenanceId: 'manual_clutch',
          itemName: 'Kampas Kopling Manual',
          itemCategory: 'clutch_plate',
          intervalKm: 24000,
          healthPercentage: 80,
          status: 'GOOD',
        ),
      ];

      final sanitized = VehicleMaintenanceService.sanitizeAndValidate(
        vehicle: vario,
        rawItems: contaminatedRaw,
      );

      expect(sanitized.length, equals(1));
      expect(sanitized.first.itemName, equals('Oli Mesin'));
    });
  });
}
