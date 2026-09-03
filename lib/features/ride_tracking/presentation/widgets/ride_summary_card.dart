import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/polyline_smoother.dart';
import '../../data/models/ride_session_model.dart';
import 'ride_share_canvas.dart';

/// RideSummaryCard (DSS Section 8.4 & Table 10)
class RideSummaryCard extends StatelessWidget {
  final RideSessionModel session;
  final String vehicleName;
  final bool isMotorcycle;

  const RideSummaryCard({
    super.key,
    required this.session,
    required this.vehicleName,
    this.isMotorcycle = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasPoints = session.points.isNotEmpty;
    final centerLatLng = hasPoints
        ? LatLng(session.points.first.latitude, session.points.first.longitude)
        : const LatLng(-6.2088, 106.8456); // Default Jakarta fallback

    final rawPoints = session.points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
    final polylinePoints = PolylineSmoother.smooth(rawPoints);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.cardBorderRadius,
        border: AppSpacing.cardBorder,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Map Thumbnail Container (Aspect Ratio 16:9)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: hasPoints
                ? IgnorePointer(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: centerLatLng,
                        initialZoom: 14.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          fallbackUrl:
                              'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.ridecare.ridecare',
                          maxZoom: 19,
                        ),
                        if (polylinePoints.length > 1)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: polylinePoints,
                                strokeWidth: 6.0,
                                color: Colors.white,
                                strokeCap: StrokeCap.round,
                                strokeJoin: StrokeJoin.round,
                              ),
                              Polyline(
                                points: polylinePoints,
                                strokeWidth: 4.0,
                                color: AppColors.primaryBlue,
                                strokeCap: StrokeCap.round,
                                strokeJoin: StrokeJoin.round,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            // Start marker
                            Marker(
                              point: polylinePoints.first,
                              width: 20,
                              height: 25,
                              alignment: Alignment.topCenter,
                              child: SvgPicture.asset(
                                'assets/markers/marker_start.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                            // Finish marker
                            if (polylinePoints.length > 1)
                              Marker(
                                point: polylinePoints.last,
                                width: 20,
                                height: 25,
                                alignment: Alignment.topCenter,
                                child: SvgPicture.asset(
                                  'assets/markers/marker_finish.svg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Container(
                    color: AppColors.surfaceSubtle,
                    child: Center(
                      child: Text(
                        'Peta rute tidak tersedia',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Telemetry Data Grid (3 Columns)
                Row(
                  children: [
                    // Col 1: Jarak Tempuh
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jarak Tempuh', style: AppTypography.captionSubtle),
                          const SizedBox(height: 2),
                          Text(
                            '${session.totalDistanceKm.toStringAsFixed(2)} km',
                            style: AppTypography.heading2,
                          ),
                        ],
                      ),
                    ),
                    // Col 2: Durasi
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Durasi', style: AppTypography.captionSubtle),
                          const SizedBox(height: 2),
                          Text(
                            DateFormatter.formatDuration(session.durationSeconds),
                            style: AppTypography.heading2,
                          ),
                        ],
                      ),
                    ),
                    // Col 3: Kecepatan Rata-rata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kecepatan Rata-rata', style: AppTypography.captionSubtle),
                          const SizedBox(height: 2),
                          Text(
                            '${session.averageSpeedKmh.toStringAsFixed(1)} km/j',
                            style: AppTypography.heading2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space16),
                const Divider(),
                const SizedBox(height: AppSpacing.space12),

                // 3. Card Footer: Date & Share Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormatter.formatDateTime(session.startTime),
                      style: AppTypography.captionSubtle,
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceSubtle,
                        foregroundColor: AppColors.primaryBlue,
                        elevation: 0,
                        minimumSize: const Size(100, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.buttonBorderRadius,
                        ),
                      ),
                      onPressed: () => RideShareCanvas.showModal(
                        context,
                        session: session,
                        vehicleName: vehicleName,
                        isMotorcycle: isMotorcycle,
                      ),
                      icon: const Icon(Icons.share_outlined, size: 16),
                      label: Text(
                        'Bagikan',
                        style: AppTypography.captionBadge.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
