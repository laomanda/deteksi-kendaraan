import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../controllers/ride_tracking_controller.dart';
import '../../data/models/ride_session_model.dart';

/// StartRideButton with hold-to-finish interaction (DSS Section 8.5)
class StartRideButton extends ConsumerStatefulWidget {
  final VoidCallback? onStart;
  final Function(RideSessionModel? session)? onFinished;

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
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.cardBorderRadius,
        ),
        title: Row(
          children: const [
            Icon(Icons.flag_rounded, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text('Selesaikan Perjalanan?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Perjalanan akan disimpan dan jarak tempuh akan otomatis ditambahkan ke total kilometer kendaraan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.healthCritical,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.chipBorderRadius,
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _executeFinish();
            },
            child: const Text('Ya, Selesaikan'),
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
      decoration: const BoxDecoration(
        boxShadow: AppSpacing.floatingShadow,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.buttonBorderRadius,
          ),
        ),
        onPressed: () async {
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
                  backgroundColor: AppColors.healthWarning,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.navigation_rounded, color: Colors.white, size: 22),
            const SizedBox(width: AppSpacing.space8),
            Text(
              'Mulai Perjalanan',
              style: AppTypography.heading3.copyWith(color: Colors.white),
            ),
          ],
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
        borderRadius: AppSpacing.buttonBorderRadius,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: AppSpacing.buttonBorderRadius,
            boxShadow: AppSpacing.floatingShadow,
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
              const SizedBox(width: AppSpacing.space12),
              Text(
                'Mengunci Sinyal... (Ketuk untuk Mulai)',
                style: AppTypography.heading3.copyWith(
                  color: Colors.white,
                  fontSize: 15,
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
              backgroundColor: AppColors.surfaceSubtle,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.buttonBorderRadius,
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
              size: 24,
              color: AppColors.textPrimary,
            ),
            label: Text(
              isPaused ? 'Lanjut' : 'Jeda',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space12),

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
                        color: AppColors.healthCritical,
                        borderRadius: AppSpacing.buttonBorderRadius,
                        boxShadow: AppSpacing.floatingShadow,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stop_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: AppSpacing.space8),
                          Text(
                            _holdController.value > 0.05
                                ? 'Menyelesaikan...'
                                : 'Selesai',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Hold progress overlay
                    if (_holdController.value > 0)
                      ClipRRect(
                        borderRadius: AppSpacing.buttonBorderRadius,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _holdController.value,
                            heightFactor: 1.0,
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.3),
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
