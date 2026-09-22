import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridecare/core/constants/vehicle_asset_resolver.dart';
import 'package:ridecare/features/maintenance/presentation/widgets/vehicle_part_icon_badge.dart';
import 'package:ridecare/features/vehicle/data/models/vehicle_model.dart';

void main() {
  group('VehicleAssetResolver Unit Tests', () {
    test('Correctly maps scooter_cvt to scooter_cvt.svg', () {
      final vehicle = VehicleModel(
        id: 'v1',
        brand: 'Honda',
        model: 'Vario 160',
        vehicleType: 'motorcycle',
        year: 2024,
        vehicleCategoryId: 'scooter_cvt',
      );
      expect(
        VehicleAssetResolver.getSilhouetteAsset(vehicle),
        equals('assets/icons/vehicle/scooter_cvt.svg'),
      );
    });

    test('Correctly maps motorcycle_manual to motorcycle_manual.svg', () {
      final vehicle = VehicleModel(
        id: 'v2',
        brand: 'Honda',
        model: 'CB150R',
        vehicleType: 'motorcycle',
        year: 2023,
        vehicleCategoryId: 'motorcycle_manual',
      );
      expect(
        VehicleAssetResolver.getSilhouetteAsset(vehicle),
        equals('assets/icons/vehicle/motorcycle_manual.svg'),
      );
    });

    test('Correctly maps sport_motorcycle to sport_motorcycle.svg', () {
      final vehicle = VehicleModel(
        id: 'v3',
        brand: 'Yamaha',
        model: 'YZF-R15',
        vehicleType: 'motorcycle',
        year: 2024,
        vehicleCategoryId: 'sport_motorcycle',
      );
      expect(
        VehicleAssetResolver.getSilhouetteAsset(vehicle),
        equals('assets/icons/vehicle/sport_motorcycle.svg'),
      );
    });

    test('Correctly maps car_manual, car_automatic, car_hybrid to car.svg', () {
      final carManual = VehicleModel(
        id: 'c1',
        brand: 'Toyota',
        model: 'Avanza',
        vehicleType: 'car',
        year: 2022,
        vehicleCategoryId: 'car_manual',
      );
      final carAuto = VehicleModel(
        id: 'c2',
        brand: 'Honda',
        model: 'Brio',
        vehicleType: 'car',
        year: 2023,
        vehicleCategoryId: 'car_automatic',
      );
      final carHybrid = VehicleModel(
        id: 'c3',
        brand: 'Toyota',
        model: 'Yaris Cross HEV',
        vehicleType: 'car',
        year: 2024,
        vehicleCategoryId: 'car_hybrid',
      );

      expect(VehicleAssetResolver.getSilhouetteAsset(carManual), equals('assets/icons/vehicle/car.svg'));
      expect(VehicleAssetResolver.getSilhouetteAsset(carAuto), equals('assets/icons/vehicle/car.svg'));
      expect(VehicleAssetResolver.getSilhouetteAsset(carHybrid), equals('assets/icons/vehicle/car.svg'));
    });

    test('Robust fallback for legacy or new unrecognized vehicles', () {
      final legacyMotor = VehicleModel(
        id: 'l1',
        brand: 'Generic',
        model: 'Motorcycle Legacy',
        vehicleType: 'motorcycle',
        year: 2018,
      );
      final legacyCar = VehicleModel(
        id: 'l2',
        brand: 'Generic',
        model: 'Car Legacy',
        vehicleType: 'car',
        year: 2018,
      );

      expect(VehicleAssetResolver.getSilhouetteAsset(legacyMotor), equals('assets/icons/vehicle/scooter_cvt.svg'));
      expect(VehicleAssetResolver.getSilhouetteAsset(legacyCar), equals('assets/icons/vehicle/car.svg'));
    });

    test('Direct string resolver never returns empty string', () {
      expect(VehicleAssetResolver.resolve(categoryId: null), isNotEmpty);
      expect(VehicleAssetResolver.resolve(categoryId: 'unknown_future_space_vehicle'), isNotEmpty);
    });
  });

  group('Maintenance Icon Centralized Resolver Tests', () {
    test('Resolves all 10 core components to standardized assets/icons/maintenance/ paths', () {
      expect(VehiclePartVisualInfo.resolveSvgAsset('Oli Mesin Matic'), equals('assets/icons/maintenance/oil.svg'));
      expect(VehiclePartVisualInfo.resolveSvgAsset('Oli Gardan / CVTF'), equals('assets/icons/maintenance/gear_oil.svg'));
      expect(VehiclePartVisualInfo.resolveSvgAsset('Sabuk CVT & Roller'), equals('assets/icons/maintenance/cvt.svg'));
      expect(VehiclePartVisualInfo.resolveSvgAsset('Kampas Rem Depan'), equals('assets/icons/maintenance/brake.svg'));
      expect(VehiclePartVisualInfo.resolveSvgAsset('Busi Iridium'), equals('assets/icons/maintenance/spark_plug.svg'));
      expect(VehiclePartVisualInfo.resolveSvgAsset('Filter Udara'), equals('assets/icons/maintenance/filter.svg'));
      expect(VehiclePartVisualInfo.resolveSvgAsset('Aki / Baterai MF'), equals('assets/icons/maintenance/battery.svg'));
      expect(VehiclePartVisualInfo.resolveSvgAsset('Air Radiator Coolant'), equals('assets/icons/maintenance/coolant.svg'));
      expect(VehiclePartVisualInfo.resolveSvgAsset('Rantai Roda & Gir'), equals('assets/icons/maintenance/chain.svg'));
      expect(VehiclePartVisualInfo.resolveSvgAsset('Ban Tubeless'), equals('assets/icons/maintenance/tire.svg'));
    });

    test('Fallback resolves to a valid asset and never empty', () {
      final fallback = VehiclePartVisualInfo.resolveSvgAsset('Komponen Misterius');
      expect(fallback, equals('assets/icons/maintenance/oil.svg'));
    });

    testWidgets('All registered SVG assets are parseable and renderable with SvgPicture.string', (tester) async {
      final assets = [
        'assets/icons/vehicle/car.svg',
        'assets/icons/vehicle/scooter_cvt.svg',
        'assets/icons/vehicle/motorcycle_manual.svg',
        'assets/icons/vehicle/sport_motorcycle.svg',
        'assets/icons/maintenance/battery.svg',
        'assets/icons/maintenance/brake.svg',
        'assets/icons/maintenance/chain.svg',
        'assets/icons/maintenance/coolant.svg',
        'assets/icons/maintenance/cvt.svg',
        'assets/icons/maintenance/filter.svg',
        'assets/icons/maintenance/gear_oil.svg',
        'assets/icons/maintenance/oil.svg',
        'assets/icons/maintenance/spark_plug.svg',
        'assets/icons/maintenance/tire.svg',
        'assets/icons/tracking/marker_trip_start.svg',
        'assets/icons/tracking/marker_trip_finish.svg',
        'assets/icons/tracking/marker_user_location.svg',
        'assets/illustrations/badge_distance.svg',
        'assets/illustrations/badge_health.svg',
        'assets/illustrations/empty_garage.svg',
        'assets/illustrations/empty_tracking.svg',
        'assets/illustrations/onboarding_service.svg',
        'assets/illustrations/onboarding_telemetry.svg',
        'assets/illustrations/onboarding_tracking.svg',
      ];

      for (final path in assets) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path should exist on disk');
        final content = file.readAsStringSync();
        expect(content, isNotEmpty);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SvgPicture.string(
                content,
                width: 100,
                height: 100,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }
    });
  });
}
