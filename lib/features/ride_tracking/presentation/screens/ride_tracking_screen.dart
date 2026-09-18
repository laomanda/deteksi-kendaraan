import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/polyline_smoother.dart';
import '../../../vehicle/data/models/vehicle_model.dart';
import '../../../vehicle/providers/vehicle_provider.dart';
import '../controllers/ride_tracking_controller.dart';
import '../widgets/ride_completion_summary_dialog.dart';
import '../widgets/start_ride_button.dart';

/// RideCare Ride Tracking Screen (Personal Vehicle Companion)
/// Single Source of Truth: DESIGN.md
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

  String _getSilhouetteAsset(VehicleModel vehicle) {
    if (!vehicle.isMotorcycle) {
      return 'assets/vehicles/vehicle_silhouette_car.svg';
    }
    final trans = (vehicle.transmission ?? '').toLowerCase();
    if (trans.contains('manual') || trans.contains('kopling') || trans.contains('sport')) {
      return 'assets/vehicles/vehicle_silhouette_manual.svg';
    }
    return 'assets/vehicles/vehicle_silhouette_scooter.svg';
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(rideTrackingProvider);
    final activeVehicle = ref.watch(activeVehicleProvider);
    final vehiclesAsync = ref.watch(vehicleAsyncListProvider);

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

    final isIdle = trackingState.status == RideTrackingStatus.idle;
    final isRecording = trackingState.status == RideTrackingStatus.recording;
    final isPaused = trackingState.status == RideTrackingStatus.paused;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Text(
          'Pelacakan Perjalanan',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.primaryNavy,
          ),
        ),
        actions: [
          // Simulation helper button for testing GPS movement on emulator or desktop
          if (!isIdle)
            IconButton(
              icon: const Icon(Icons.speed, size: 20, color: AppColors.primaryNavy),
              tooltip: 'Simulasi Pergerakan (Uji Coba)',
              onPressed: () {
                final lastPoint = trackingState.lastPoint;
                final baseLat = lastPoint?.latitude ?? currentLatLng.latitude;
                final baseLon = lastPoint?.longitude ?? currentLatLng.longitude;
                final count = trackingState.points.length;
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
            // 1. Vehicle Journey Identity Header (Section 1)
            if (selectedVehicle != null)
              _buildVehicleJourneyHeader(context, selectedVehicle, vehiclesList, isIdle),

            // 2. Map Section (Section 2)
            Expanded(
              flex: isIdle ? 5 : 6,
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
                      // Polyline route layers
                      if (polylinePoints.length > 1) ...[
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: polylinePoints,
                              strokeWidth: 7.0,
                              color: Colors.white,
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
                              color: AppColors.primaryNavy,
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
                                'assets/tracking/marker_trip_start.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                          // Live current location vehicle marker
                          Marker(
                            point: currentLatLng,
                            width: 38,
                            height: 38,
                            child: Transform.rotate(
                              angle: trackingState.heading * (math.pi / 180.0),
                              child: SvgPicture.asset(
                                'assets/tracking/marker_user_location.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Top Map Contextual Overlay Badge
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: _buildMapStatusBadge(isIdle, isRecording, isPaused, trackingState),
                  ),

                  // Recenter floating button
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'recenter_map',
                      backgroundColor: AppColors.surfaceWhite,
                      foregroundColor: AppColors.primaryNavy,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      onPressed: () async {
                        setState(() => _autoCentering = true);
                        await _locateUserInitialPosition();
                        final target = _userRealLocation ?? currentLatLng;
                        _mapController.move(
                          target,
                          _mapController.camera.zoom,
                        );
                      },
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedLocation01,
                        size: 20,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3 & 4. Journey Summary & Primary Action Panel
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0C102A43),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status & Telemetry Readouts
                  if (isIdle)
                    _buildIdleJourneySummary()
                  else
                    _buildActiveJourneyTelemetry(trackingState),

                  const SizedBox(height: 16),

                  // Primary Action Controls
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
          ],
        ),
      ),
    );
  }

  /// Vehicle Journey Identity Header (Section 1)
  Widget _buildVehicleJourneyHeader(
    BuildContext context,
    VehicleModel vehicle,
    List<VehicleModel> vehicles,
    bool isIdle,
  ) {
    final hasMultiple = vehicles.length > 1;
    final silhouetteAsset = _getSilhouetteAsset(vehicle);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Vehicle Silhouette Thumbnail
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: SvgPicture.asset(
              silhouetteAsset,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),

          // Vehicle Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Perjalanan dengan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.secondarySteel,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  vehicle.displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Total Odometer: ${DateFormatter.formatKm(vehicle.currentKilometer, includeUnit: false)} KM',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Vehicle Switcher Pill (Only when idle)
          if (isIdle && hasMultiple)
            InkWell(
              onTap: () => _showVehiclePickerModal(context, vehicles, vehicle),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ganti',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.primaryNavy,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Contextual Map Overlay Badge
  Widget _buildMapStatusBadge(
    bool isIdle,
    bool isRecording,
    bool isPaused,
    RideTrackingState trackingState,
  ) {
    final String label;
    final Color badgeBg;
    final Color textColor;
    final IconData icon;

    if (isRecording) {
      label = 'Perjalanan Sedang Berlangsung';
      badgeBg = AppColors.primaryNavy;
      textColor = Colors.white;
      icon = Icons.fiber_manual_record_rounded;
    } else if (isPaused) {
      label = 'Perjalanan Dijeda';
      badgeBg = AppColors.warningAmber;
      textColor = Colors.white;
      icon = Icons.pause_rounded;
    } else {
      label = 'Siap Merekam Perjalanan';
      badgeBg = AppColors.surfaceWhite.withValues(alpha: 0.95);
      textColor = AppColors.primaryNavy;
      icon = Icons.check_circle_outline_rounded;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isIdle ? AppColors.borderSubtle : Colors.transparent,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18102A43),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isRecording ? AppColors.accentCyan : textColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty Journey Summary when Idle
  Widget _buildIdleJourneySummary() {
    return Row(
      children: [
        SizedBox(
          width: 58,
          height: 58,
          child: SvgPicture.asset(
            'assets/experience/empty_tracking_stage.svg',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Belum Ada Perjalanan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Mulai perjalanan pertama kamu untuk merekam rute dan jarak.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.secondarySteel,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Active Telemetry Readout during Recording
  Widget _buildActiveJourneyTelemetry(RideTrackingState trackingState) {
    final isMoving = trackingState.currentSpeedKmh > 1.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Perjalanan Saat Ini',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryNavy,
              ),
            ),
            if (isMoving)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.safeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Bergerak',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.safeGreen,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            // Jarak
            Expanded(
              child: _buildMetricTile(
                label: 'JARAK',
                value: '${trackingState.totalDistanceKm.toStringAsFixed(2)} KM',
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: const Color(0xFFF1EFE9),
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            // Durasi
            Expanded(
              child: _buildMetricTile(
                label: 'DURASI',
                value: DateFormatter.formatDuration(trackingState.durationSeconds),
              ),
            ),
            // Kecepatan (Only rendered when moving)
            if (isMoving) ...[
              Container(
                width: 1,
                height: 40,
                color: const Color(0xFFF1EFE9),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Expanded(
                child: _buildMetricTile(
                  label: 'KECEPATAN',
                  value: '${trackingState.currentSpeedKmh.toStringAsFixed(0)} km/j',
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showVehiclePickerModal(
    BuildContext context,
    List<VehicleModel> vehicles,
    VehicleModel currentVehicle,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pilih Kendaraan Perjalanan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  Text(
                    '${vehicles.length} Kendaraan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: vehicles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final v = vehicles[index];
                    final isSelected = v.id == currentVehicle.id;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryNavy
                              : AppColors.borderSubtle,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      tileColor: isSelected
                          ? AppColors.primaryNavy.withValues(alpha: 0.04)
                          : AppColors.surfaceWhite,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                          icon: v.isMotorcycle
                              ? HugeIcons.strokeRoundedMotorbike01
                              : HugeIcons.strokeRoundedCar01,
                          color: AppColors.primaryNavy,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        v.displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      subtitle: Text(
                        '${v.year} • ${DateFormatter.formatKm(v.currentKilometer, includeUnit: false)} KM',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.secondarySteel,
                          fontSize: 11,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.safeGreen,
                              size: 20,
                            )
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
