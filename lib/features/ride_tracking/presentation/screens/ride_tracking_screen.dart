import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/polyline_smoother.dart';
import '../controllers/ride_tracking_controller.dart';
import '../widgets/ride_completion_summary_dialog.dart';
import '../widgets/start_ride_button.dart';
import '../../../vehicle/data/models/vehicle_model.dart';

import '../../../vehicle/providers/vehicle_provider.dart';


/// Layar 2: Ride Tracking Screen (Active Session) (DSS Section 9.2 & PRD Section 9, 10)

class RideTrackingScreen extends ConsumerStatefulWidget {
  const RideTrackingScreen({super.key});

  @override
  ConsumerState<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends ConsumerState<RideTrackingScreen> {
  final MapController _mapController = MapController();
  bool _autoCentering = true;
  LatLng? _userRealLocation;

  @override
  void initState() {
    super.initState();
    _locateUserInitialPosition();
  }

  Future<void> _locateUserInitialPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
      if (mounted) {
        setState(() {
          _userRealLocation = LatLng(pos.latitude, pos.longitude);
        });
        _mapController.move(_userRealLocation!, 15.5);
      }
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null && mounted) {
          setState(() {
            _userRealLocation = LatLng(last.latitude, last.longitude);
          });
          _mapController.move(_userRealLocation!, 15.5);
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(rideTrackingProvider);
    final activeVehicle = ref.watch(activeVehicleProvider);
    final vehiclesAsync = ref.watch(vehicleListProvider);

    final vehiclesList = vehiclesAsync.maybeWhen(
      data: (list) => list,
      orElse: () => activeVehicle != null ? [activeVehicle] : <VehicleModel>[],
    );

    final selectedVehicle = vehiclesList
            .where((v) =>
                v.id == (trackingState.selectedVehicleId ?? activeVehicle?.id))
            .firstOrNull ??
        activeVehicle;

    final hasPoints = trackingState.points.isNotEmpty;
    final last = trackingState.lastPoint;
    final currentLatLng = (hasPoints && last != null)
        ? LatLng(last.latitude, last.longitude)
        : (_userRealLocation ?? const LatLng(-6.2088, 106.8456));

    final rawPoints =
        trackingState.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final polylinePoints = PolylineSmoother.smooth(rawPoints);

    // Auto center map if enabled
    if (_autoCentering && hasPoints) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(currentLatLng, _mapController.camera.zoom);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: AppBar(
        title: Text('Pelacakan Perjalanan', style: AppTypography.heading2),
        elevation: 0,
        actions: [
          // Simulation helper button for testing GPS movement on emulator or desktop
          if (trackingState.status != RideTrackingStatus.idle)
            IconButton(
              icon: const Icon(Icons.speed, size: 20),
              tooltip: 'Simulasi Pergerakan (Uji Coba)',
              onPressed: () {
                final lastPoint = trackingState.lastPoint;
                final baseLat = lastPoint?.latitude ?? currentLatLng.latitude;
                final baseLon = lastPoint?.longitude ?? currentLatLng.longitude;
                final count = trackingState.points.length;
                // Realistic city street curve trajectory simulation (winding street contour)
                final angle = count * 0.28;
                final step = 0.00035; // ~35 meters
                final lat = baseLat + (math.cos(angle) * step);
                final lon = baseLon + (math.sin(angle) * step);
                ref.read(rideTrackingProvider.notifier).addSimulatedPoint(
                      latitude: lat,
                      longitude: lon,
                      speedKmh: 28.0 + (math.sin(count * 0.5) * 6.0),
                    );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Map Section (Occupies ~60% of vertical viewport)
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: currentLatLng,
                      initialZoom: 15.0,
                      onPositionChanged: (pos, hasGesture) {
                        if (hasGesture && _autoCentering) {
                          setState(() => _autoCentering = false);
                        }
                      },
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
                      // Outer border polyline for sharp contrast (DSS 12.2)
                      if (polylinePoints.length > 1) ...[
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: polylinePoints,
                              strokeWidth: 6.5,
                              color: Colors.white.withValues(alpha: 0.5),
                              strokeCap: StrokeCap.round,
                              strokeJoin: StrokeJoin.round,
                            ),
                          ],
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: polylinePoints,
                              strokeWidth: 4.5,
                              color: AppColors.primaryBlue,
                              strokeCap: StrokeCap.round,
                              strokeJoin: StrokeJoin.round,
                            ),
                          ],
                        ),
                      ],
                      MarkerLayer(
                        markers: [
                          // Start pin
                          if (polylinePoints.isNotEmpty)
                            Marker(
                              point: polylinePoints.first,
                              width: 32,
                              height: 40,
                              alignment: Alignment.topCenter,
                              child: SvgPicture.asset(
                                'assets/markers/marker_start.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                          // Live current location vehicle marker (DSS 12.2)
                          Marker(
                            point: currentLatLng,
                            width: 38,
                            height: 38,
                            child: Transform.rotate(
                              angle: trackingState.heading * (math.pi / 180.0),
                              child: SvgPicture.asset(
                                (selectedVehicle?.isMotorcycle ?? true)
                                    ? 'assets/markers/marker_motorcycle.svg'
                                    : 'assets/markers/marker_vehicle.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Map Floating Controls
                  Positioned(
                    right: AppSpacing.space16,
                    bottom: AppSpacing.space16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'recenter_map',
                          backgroundColor: _autoCentering
                              ? AppColors.primaryBlue
                              : AppColors.surfaceWhite,
                          foregroundColor: _autoCentering
                              ? Colors.white
                              : AppColors.textPrimary,
                          elevation: 2,
                          onPressed: () async {
                            setState(() => _autoCentering = true);
                            await _locateUserInitialPosition();
                            final target = _userRealLocation ?? currentLatLng;
                            _mapController.move(
                              target,
                              _mapController.camera.zoom,
                            );
                          },
                          child: const Icon(Icons.my_location_rounded, size: 20),
                        ),
                      ],
                    ),
                  ),

                  // Vehicle Selector Pill when idle (allows picking vehicle before starting ride)
                  if (trackingState.status == RideTrackingStatus.idle &&
                      selectedVehicle != null)
                    Positioned(
                      top: AppSpacing.space12,
                      left: AppSpacing.space16,
                      right: AppSpacing.space16,
                      child: _buildVehicleSelectorCard(
                        context,
                        vehiclesList,
                        selectedVehicle,
                      ),
                    ),

                  // GPS Signal Status Banner if degraded
                  if (!trackingState.isGpsLocked &&
                      trackingState.status == RideTrackingStatus.recording)
                    Positioned(
                      top: AppSpacing.space12,
                      left: AppSpacing.space16,
                      right: AppSpacing.space16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.healthWarning.withValues(alpha: 0.95),
                          borderRadius: AppSpacing.chipBorderRadius,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.satellite_alt,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Akurasi GPS rendah (${trackingState.gpsAccuracy.toInt()}m). Memfilter noise.',
                                style: AppTypography.captionBadge
                                    .copyWith(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. Telemetry Overlay Panel (Occupies ~40% of bottom area)
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space24,
                  vertical: AppSpacing.space16,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: AppSpacing.modalTopRadius,
                  border: Border(
                      top: BorderSide(color: AppColors.borderSubtle, width: 1)),
                  boxShadow: AppSpacing.floatingShadow,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Primary telemetry readouts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // Speed readout
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('KECEPATAN', style: AppTypography.captionBadge),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  trackingState.currentSpeedKmh.toStringAsFixed(0),
                                  style: AppTypography.displayLarge.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontSize: 36,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text('km/j', style: AppTypography.bodyMedium),
                              ],
                            ),
                          ],
                        ),

                        // Distance readout
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('JARAK', style: AppTypography.captionBadge),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  trackingState.totalDistanceKm
                                      .toStringAsFixed(2),
                                  style: AppTypography.displayMedium,
                                ),
                                const SizedBox(width: 4),
                                Text('km', style: AppTypography.bodyMedium),
                              ],
                            ),
                          ],
                        ),

                        // Duration readout
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('DURASI', style: AppTypography.captionBadge),
                            Text(
                              DateFormatter.formatDuration(
                                  trackingState.durationSeconds),
                              style: AppTypography.displayMedium,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Controls row with Ride Completion Summary Dialog
                    StartRideButton(
                      onFinished: (result) {
                        if (result != null) {
                          RideCompletionSummaryDialog.show(
                            context,
                            result: result,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSelectorCard(
    BuildContext context,
    List<VehicleModel> vehicles,
    VehicleModel currentVehicle,
  ) {
    final hasMultiple = vehicles.length > 1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasMultiple
            ? () => _showVehiclePickerModal(context, vehicles, currentVehicle)
            : null,
        borderRadius: AppSpacing.cardBorderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite.withValues(alpha: 0.95),
            borderRadius: AppSpacing.cardBorderRadius,
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                currentVehicle.isMotorcycle
                    ? Icons.two_wheeler_rounded
                    : Icons.directions_car_rounded,
                color: AppColors.primaryBlue,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('KENDARAAN PERJALANAN', style: AppTypography.captionBadge),
                    const SizedBox(height: 2),
                    Text(
                      '${currentVehicle.displayName} • ${DateFormatter.formatKm(currentVehicle.currentKilometer)} KM',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasMultiple) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: AppSpacing.chipBorderRadius,
                  ),
                  child: Row(
                    children: const [
                      Text(
                        'Ganti',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: AppColors.primaryBlue),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showVehiclePickerModal(
    BuildContext context,
    List<VehicleModel> vehicles,
    VehicleModel currentVehicle,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.modalTopRadius,
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Pilih Kendaraan untuk Perjalanan',
                  style: AppTypography.heading2,
                ),
              ),
              const Divider(),
              ...vehicles.map((v) {
                final isSelected = v.id == currentVehicle.id;
                return ListTile(
                  leading: Icon(
                    v.isMotorcycle
                        ? Icons.two_wheeler_rounded
                        : Icons.directions_car_rounded,
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.textSecondary,
                  ),
                  title: Text(
                    v.displayName,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${DateFormatter.formatKm(v.currentKilometer)} KM',
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primaryBlue)
                      : null,
                  onTap: () {
                    ref
                        .read(rideTrackingProvider.notifier)
                        .setSelectedVehicle(v.id);
                    ref
                        .read(activeVehicleProvider.notifier)
                        .setActiveVehicle(v.id);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

