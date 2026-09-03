import 'dart:math' as math;

/// Haversine Formula for distance calculation between geographical coordinates (PRD Section 9.3)
class HaversineCalculator {
  HaversineCalculator._();

  /// Earth radius in kilometers (R = 6,371 km)
  static const double earthRadiusKm = 6371.0;

  /// Calculates geodesic distance in kilometers between two points
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final phi1 = lat1 * (math.pi / 180.0);
    final phi2 = lat2 * (math.pi / 180.0);
    final deltaPhi = (lat2 - lat1) * (math.pi / 180.0);
    final deltaLambda = (lon2 - lon1) * (math.pi / 180.0);

    final sinDeltaPhi = math.sin(deltaPhi / 2.0);
    final sinDeltaLambda = math.sin(deltaLambda / 2.0);

    final a = (sinDeltaPhi * sinDeltaPhi) +
        math.cos(phi1) * math.cos(phi2) * (sinDeltaLambda * sinDeltaLambda);

    final c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(math.max(0.0, 1.0 - a)));

    return earthRadiusKm * c;
  }

  /// Calculates distance in meters
  static double calculateDistanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return calculateDistanceKm(
          lat1: lat1,
          lon1: lon1,
          lat2: lat2,
          lon2: lon2,
        ) *
        1000.0;
  }
}
