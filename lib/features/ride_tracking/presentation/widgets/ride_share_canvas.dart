import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/ride_session_model.dart';

/// RideShareCanvas (DSS Section 8.6, Table 10 & PRD Section 11)
/// 4:5 aspect ratio graphic canvas exportable to high-res image
class RideShareCanvas extends StatelessWidget {
  final RideSessionModel session;
  final String vehicleName;

  const RideShareCanvas({
    super.key,
    required this.session,
    required this.vehicleName,
  });

  static Future<void> showModal(
    BuildContext context, {
    required RideSessionModel session,
    required String vehicleName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.modalTopRadius,
      ),
      builder: (_) => _RideShareModal(session: session, vehicleName: vehicleName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppSpacing.cardBorderRadius,
          border: AppSpacing.cardBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. STATS HERO BANNER (Total Jarak & Durasi)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL JARAK',
                      style: AppTypography.captionSubtle.copyWith(
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          session.totalDistanceKm.toStringAsFixed(2),
                          style: AppTypography.displayLarge.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'KM',
                          style: AppTypography.captionBadge.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'WAKTU TEMPUH',
                      style: AppTypography.captionSubtle.copyWith(
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.formatDuration(session.durationSeconds),
                      style: AppTypography.heading1.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space16),

            // 2. Realistic OpenStreetMap Container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: AppSpacing.cardBorderRadius,
                  border: Border.all(color: AppColors.borderSubtle, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: AppSpacing.cardBorderRadius,
                  child: _buildRealisticMap(session),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),

            // 3. Telemetry Block Container
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
                vertical: AppSpacing.space12,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: AppSpacing.cardBorderRadius,
                border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'KEC. MAKS',
                      '${session.maxSpeedKmh.toStringAsFixed(1)} km/j',
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'RATA-RATA',
                      '${session.averageSpeedKmh.toStringAsFixed(1)} km/j',
                      align: CrossAxisAlignment.center,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'TANGGAL',
                      DateFormatter.formatDate(session.startTime),
                      align: CrossAxisAlignment.end,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space8),

            // 4. Subtle Watermark (discreet)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shield_rounded,
                  size: 13,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 4),
                Text(
                  'RideCare Telemetry',
                  style: AppTypography.captionSubtle.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value, {
    CrossAxisAlignment align = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.captionSubtle.copyWith(
            fontSize: 10,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.captionBadge.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRealisticMap(RideSessionModel session) {
    final hasPoints = session.points.isNotEmpty;
    final polylinePoints = session.points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    CameraFit? cameraFit;
    LatLng initialCenter = const LatLng(-6.2088, 106.8456);

    if (hasPoints) {
      initialCenter = polylinePoints.first;

      double minLat = session.points.first.latitude;
      double maxLat = session.points.first.latitude;
      double minLon = session.points.first.longitude;
      double maxLon = session.points.first.longitude;

      for (final p in session.points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLon) minLon = p.longitude;
        if (p.longitude > maxLon) maxLon = p.longitude;
      }

      final latSpan = maxLat - minLat;
      final lonSpan = maxLon - minLon;

      // When there is travel from Point A to Point B, automatically fit the full route bounds!
      if (polylinePoints.length > 1 && (latSpan > 0.0001 || lonSpan > 0.0001)) {
        cameraFit = CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(polylinePoints),
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 28.0),
        );
      }
    }

    return Stack(
      children: [
        IgnorePointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 16.0,
              initialCameraFit: cameraFit,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                fallbackUrl:
                    'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ridecare.ridecare',
                maxZoom: 19,
              ),
              if (polylinePoints.length > 1) ...[
                PolylineLayer(
                  polylines: [
                    // Outer glow
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 9.0,
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    ),
                    // High-contrast white border
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 6.5,
                      color: Colors.white,
                    ),
                    // Primary blue polyline
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 4.5,
                      color: AppColors.primaryBlue,
                    ),
                  ],
                ),
              ],
              if (hasPoints)
                MarkerLayer(
                  markers: [
                    // Titik A (Start Marker)
                    Marker(
                      point: polylinePoints.first,
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.healthOptimal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Titik B (Finish Marker)
                    if (polylinePoints.length > 1 &&
                        (polylinePoints.first != polylinePoints.last))
                      Marker(
                        point: polylinePoints.last,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.healthCritical,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'B',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        // Subtle top gradient overlay for depth
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RideShareModal extends StatefulWidget {
  final RideSessionModel session;
  final String vehicleName;

  const _RideShareModal({required this.session, required this.vehicleName});

  @override
  State<_RideShareModal> createState() => _RideShareModalState();
}

class _RideShareModalState extends State<_RideShareModal> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isProcessing = false;

  Future<Uint8List?> _captureCardBytes() async {
    // 1. Try capturing from live on-screen widget (contains all ancestors and loaded map tiles)
    try {
      final bytes = await _screenshotController.capture(pixelRatio: 2.5);
      if (bytes != null && bytes.isNotEmpty) return bytes;
    } catch (_) {}

    // 2. Offscreen fallback explicitly wrapped in Directionality & MediaQuery to prevent missing ancestor errors
    if (!mounted) return null;
    final mediaQueryData = MediaQuery.maybeOf(context) ??
        MediaQueryData.fromView(View.of(context));

    return await _screenshotController.captureFromWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: mediaQueryData,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 360,
              height: 450,
              child: RideShareCanvas(
                session: widget.session,
                vehicleName: widget.vehicleName,
              ),
            ),
          ),
        ),
      ),
      pixelRatio: 2.5,
    );
  }

  Future<void> _downloadCard() async {
    setState(() => _isProcessing = true);
    try {
      final imageBytes = await _captureCardBytes();
      if (imageBytes == null) throw Exception('Gagal memproses gambar');

      final shortId = widget.session.id.length > 8
          ? widget.session.id.substring(0, 8)
          : widget.session.id;
      final fileName = 'ridecare_trip_$shortId.png';
      final xFile = XFile.fromData(
        imageBytes,
        mimeType: 'image/png',
        name: fileName,
      );

      await xFile.saveTo(fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gambar kartu perjalanan berhasil diunduh!'),
            backgroundColor: AppColors.healthOptimal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunduh gambar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _shareCard() async {
    setState(() => _isProcessing = true);
    try {
      final imageBytes = await _captureCardBytes();
      if (imageBytes == null) throw Exception('Gagal memproses gambar');

      final shortId = widget.session.id.length > 8
          ? widget.session.id.substring(0, 8)
          : widget.session.id;
      final fileName = 'ridecare_share_$shortId.png';
      final xFile = XFile.fromData(
        imageBytes,
        mimeType: 'image/png',
        name: fileName,
      );

      final shareText =
          'Perjalanan ${widget.session.totalDistanceKm.toStringAsFixed(2)} km dalam ${DateFormatter.formatDuration(widget.session.durationSeconds)} tercatat di RideCare!';

      if (kIsWeb) {
        try {
          await Share.shareXFiles([xFile], text: shareText);
        } catch (_) {
          // Direct web download fallback if Web Share API is blocked by browser
          await xFile.saveTo(fileName);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Browser tidak mendukung Web Share, gambar otomatis diunduh!'),
                backgroundColor: AppColors.healthOptimal,
              ),
            );
          }
        }
      } else {
        await Share.shareXFiles([xFile], text: shareText);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membagikan kartu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.space16),
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Kartu Perjalanan (4:5)', style: AppTypography.heading2),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'Format 4:5 optimal untuk Instagram Stories dan status media sosial',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.space16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 360,
                height: 450,
                child: Screenshot(
                  controller: _screenshotController,
                  child: RideShareCanvas(
                    session: widget.session,
                    vehicleName: widget.vehicleName,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          Row(
            children: [
              // 1. Download Button
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonBorderRadius,
                    ),
                  ),
                  onPressed: _isProcessing ? null : _downloadCard,
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: Text(
                    'Unduh PNG',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              // 2. Share Button
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonBorderRadius,
                    ),
                  ),
                  onPressed: _isProcessing ? null : _shareCard,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                  label: Text(
                    _isProcessing ? 'Memproses...' : 'Bagikan',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }
}
