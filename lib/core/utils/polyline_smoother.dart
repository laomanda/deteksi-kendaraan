import 'package:latlong2/latlong.dart';

/// Utility to transform raw, rigid polygonal GPS tracks into smooth, realistic,
/// organic path curves using Chaikin's Corner Smoothing Algorithm.
class PolylineSmoother {
  PolylineSmoother._();

  /// Smooths a list of [LatLng] coordinates.
  ///
  /// - [iterations]: Number of smoothing passes (default 2). 2 passes turns
  ///   sharp 90-degree polygonal corners into natural, fluid road bends.
  /// - Preserves exact start and finish coordinates.
  static List<LatLng> smooth(List<LatLng> points, {int iterations = 2}) {
    if (points.length < 3) return points;

    List<LatLng> current = List<LatLng>.from(points);

    for (int iter = 0; iter < iterations; iter++) {
      if (current.length < 3) break;

      final smoothed = <LatLng>[];
      // Keep exact starting point
      smoothed.add(current.first);

      for (int i = 0; i < current.length - 1; i++) {
        final p0 = current[i];
        final p1 = current[i + 1];

        // Q = 75% p0 + 25% p1
        final qLat = 0.75 * p0.latitude + 0.25 * p1.latitude;
        final qLon = 0.75 * p0.longitude + 0.25 * p1.longitude;

        // R = 25% p0 + 75% p1
        final rLat = 0.25 * p0.latitude + 0.75 * p1.latitude;
        final rLon = 0.25 * p0.longitude + 0.75 * p1.longitude;

        smoothed.add(LatLng(qLat, qLon));
        smoothed.add(LatLng(rLat, rLon));
      }

      // Keep exact finish point
      smoothed.add(current.last);
      current = smoothed;
    }

    return current;
  }
}
