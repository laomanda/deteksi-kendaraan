import 'package:flutter_test/flutter_test.dart';
import 'package:ridecare/core/utils/haversine_calculator.dart';

void main() {
  group('HaversineCalculator Unit Tests (PRD Section 9.3 & 18.1)', () {
    test('Zero distance for identical coordinates', () {
      final distance = HaversineCalculator.calculateDistanceKm(
        lat1: -6.1754,
        lon1: 106.8272,
        lat2: -6.1754,
        lon2: 106.8272,
      );
      expect(distance, 0.0);
    });

    test('Accurately computes distance between Monas and Bundaran HI (~2.2 km)', () {
      // Monas Jakarta: -6.175392, 106.827153
      // Bundaran HI Jakarta: -6.195000, 106.823000
      final distanceKm = HaversineCalculator.calculateDistanceKm(
        lat1: -6.175392,
        lon1: 106.827153,
        lat2: -6.195000,
        lon2: 106.823000,
      );

      // Expected distance is ~2.22 km with standard geodesy formula
      expect(distanceKm, closeTo(2.22, 0.1));
    });

    test('Distance in meters converts proportionally', () {
      final meters = HaversineCalculator.calculateDistanceMeters(
        lat1: -6.175392,
        lon1: 106.827153,
        lat2: -6.195000,
        lon2: 106.823000,
      );

      expect(meters, closeTo(2220.0, 100.0));
    });
  });
}
