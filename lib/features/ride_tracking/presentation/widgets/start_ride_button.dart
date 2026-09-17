import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/ride_tracking_controller.dart';

/// StartRideButton with hold-to-finish interaction (DESIGN.md & DSS Section 8.5)
/// Styled for Personal Vehicle Companion experience
class StartRideButton extends ConsumerStatefulWidget {
  final VoidCallback? onStart;
  final Function(RideCompletionResult? result)? onFinished;

  const StartRideButton({
    super.key,
    this.onStart,
    this.onFinished,
  });

  @override
  ConsumerState<StartRideButton> createState() => _StartRideButtonState();
}

class _StartRideButtonState extends ConsumerState<StartRideButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _holdController;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Smooth 800ms hold
    );
    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _executeFinish();
      }
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _holdController.dispose();
    super.dispose();
  }

  void _promptConfirmFinish() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flag_rounded, color: AppColors.dangerRed, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Selesaikan Perjalanan?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Perjalanan akan disimpan dan jarak tempuh otomatis ditambahkan ke total kilometer kendaraan Anda.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.secondarySteel,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Lanjutkan Perjalanan',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppColors.secondarySteel,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _executeFinish();
            },
            child: Text(
              'Ya, Selesaikan',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _executeFinish() async {
    _holdController.reset();
    final session = await ref.read(rideTrackingProvider.notifier).finishRide();
    widget.onFinished?.call(session);
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(rideTrackingProvider);

    switch (trackingState.status) {
      case RideTrackingStatus.idle:
        return _buildIdleButton();

      case RideTrackingStatus.acquiring:
        return _buildAcquiringButton();

      case RideTrackingStatus.recording:
      case RideTrackingStatus.paused:
        return _buildActiveTrackingControls(trackingState.status);
    }
  }

  Widget _buildIdleButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Color(0x18102A43),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () async {
            final started =
                await ref.read(rideTrackingProvider.notifier).startRide();
            if (started) {
              widget.onStart?.call();
            } else {
              final err = ref.read(rideTrackingProvider).errorMessage;
              if (err != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err),
                    backgroundColor: AppColors.warningAmber,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedRoute01,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mulai Rekam Perjalanan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Catat rute, jarak, dan waktu perjalanan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFCBD2D9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAcquiringButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(rideTrackingProvider.notifier).forceStartNow();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14102A43),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Mengunci Sinyal GPS... (Ketuk untuk Mulai)',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTrackingControls(RideTrackingStatus status) {
    final isPaused = status == RideTrackingStatus.paused;

    return Row(
      children: [
        // 1. Pause / Resume Button
        Expanded(
          flex: 1,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.primaryNavy,
              elevation: 0,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.borderSubtle, width: 1),
              ),
            ),
            onPressed: () {
              if (isPaused) {
                ref.read(rideTrackingProvider.notifier).resumeRide();
              } else {
                ref.read(rideTrackingProvider.notifier).pauseRide();
              }
            },
            icon: Icon(
              isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 22,
              color: AppColors.primaryNavy,
            ),
            label: Text(
              isPaused ? 'Lanjut' : 'Jeda',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 2. Finish Button (Click to prompt confirmation, or hold to finish directly)
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _promptConfirmFinish,
            onLongPressStart: (_) {
              _holdController.forward();
            },
            onLongPressEnd: (_) {
              if (_holdController.status != AnimationStatus.completed) {
                _holdController.reverse();
              }
            },
            onLongPressCancel: () {
              _holdController.reverse();
            },
            child: AnimatedBuilder(
              animation: _holdController,
              builder: (context, child) {
                return Stack(
                  children: [
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.dangerRed,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x20DC2626),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stop_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            _holdController.value > 0.05
                                ? 'Menyelesaikan...'
                                : 'Selesaikan Perjalanan',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Hold progress overlay
                    if (_holdController.value > 0)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _holdController.value,
                            heightFactor: 1.0,
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
