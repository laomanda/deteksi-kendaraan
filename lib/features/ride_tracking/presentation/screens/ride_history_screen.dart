import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../controllers/ride_tracking_controller.dart';
import '../widgets/ride_share_canvas.dart';

/// Screen displaying the complete history ledger of all completed rides (PRD Section 11)
class RideHistoryScreen extends ConsumerWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    final rides = ref.watch(rideHistoryListProvider);

    if (activeVehicle == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Riwayat Perjalanan', style: AppTypography.heading2),
        ),
        body: const Center(child: Text('Kendaraan belum dipilih')),
      );
    }

    final totalRides = rides.length;
    final totalDistance = rides.fold<double>(
      0.0,
      (sum, item) => sum + item.totalDistanceKm,
    );

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Riwayat Perjalanan', style: AppTypography.heading2),
        elevation: 0,
      ),
      body: SafeArea(
        child: rides.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 56,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      Text(
                        'Belum Ada Riwayat Perjalanan',
                        style: AppTypography.heading2,
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      Text(
                        'Semua perjalanan yang telah Anda rekam dan selesaikan akan otomatis tersimpan rapi di sini.',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.space16),
                children: [
                  // 1. Stats Summary Header
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: AppSpacing.cardBorderRadius,
                      border: AppSpacing.cardBorder,
                      boxShadow: AppSpacing.floatingShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'TOTAL PERJALANAN',
                              style: AppTypography.captionSubtle.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalRides',
                              style: AppTypography.heading1.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: AppColors.borderSubtle,
                        ),
                        Column(
                          children: [
                            Text(
                              'TOTAL JARAK',
                              style: AppTypography.captionSubtle.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${totalDistance.toStringAsFixed(1)} km',
                              style: AppTypography.heading1.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),

                  // 2. Chronological Trip List
                  ...rides.map((session) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.space12),
                      padding: const EdgeInsets.all(AppSpacing.space16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: AppSpacing.cardBorderRadius,
                        border: AppSpacing.cardBorder,
                        boxShadow: AppSpacing.floatingShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Date & Time + Delete Option
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormatter.formatDate(session.startTime),
                                    style: AppTypography.captionBadge.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '•  ${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}',
                                    style: AppTypography.captionSubtle,
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                                tooltip: 'Hapus Perjalanan',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  _promptDeleteRide(context, ref, session.id);
                                },
                              ),
                            ],
                          ),
                          const Divider(height: AppSpacing.space16),

                          // Distance & Duration Readouts
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'JARAK',
                                    style: AppTypography.captionSubtle.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${session.totalDistanceKm.toStringAsFixed(2)} km',
                                    style: AppTypography.heading2.copyWith(
                                      color: AppColors.primaryBlue,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'DURASI',
                                    style: AppTypography.captionSubtle.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormatter.formatDuration(
                                        session.durationSeconds),
                                    style: AppTypography.heading3,
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'RATA-RATA',
                                    style: AppTypography.captionSubtle.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${session.averageSpeedKmh.toStringAsFixed(1)} km/j',
                                    style: AppTypography.heading3,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.space12),

                          // Action: View / Share Trip Card
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryBlue,
                                side: const BorderSide(
                                  color: AppColors.borderSubtle,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppSpacing.chipBorderRadius,
                                ),
                              ),
                              onPressed: () {
                                RideShareCanvas.showModal(
                                  context,
                                  session: session,
                                  vehicleName: activeVehicle.displayName,
                                );
                              },
                              icon: const Icon(Icons.share_outlined, size: 16),
                              label: Text(
                                'Lihat Peta & Bagikan',
                                style: AppTypography.captionBadge.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  void _promptDeleteRide(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.cardBorderRadius,
        ),
        title: const Text('Hapus Catatan Perjalanan?'),
        content: const Text(
          'Catatan ini akan dihapus dari riwayat perjalanan perangkat Anda.',
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
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(rideHistoryListProvider.notifier)
                  .deleteRide(id);
              ref.invalidate(recentRideProvider);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
