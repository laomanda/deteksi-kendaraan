import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../maintenance/presentation/pages/maintenance_page.dart';
import '../../../maintenance/providers/maintenance_intelligence_providers.dart';
import '../controllers/ride_tracking_controller.dart';
import 'ride_share_canvas.dart';

/// Modal dialog displaying summary after ride completion:
/// Distance, Duration, Vehicle, Odometer change (before -> after),
/// and Maintenance status update with CTA to View Maintenance.
class RideCompletionSummaryDialog extends ConsumerWidget {
  final RideCompletionResult result;

  const RideCompletionSummaryDialog({
    super.key,
    required this.result,
  });

  static Future<void> show(
    BuildContext context, {
    required RideCompletionResult result,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RideCompletionSummaryDialog(result: result),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthSummaryAsync =
        ref.watch(maintenanceHealthProvider(result.vehicleId));

    final isMotorcycle = result.vehicleType.toLowerCase() == 'motorcycle';
    final distanceDiff = result.newOdometer - result.previousOdometer;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.modalTopRadius,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space24,
        AppSpacing.space16,
        AppSpacing.space24,
        AppSpacing.space24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),

            // Header: Icon + Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.healthOptimal.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.healthOptimal,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ride Completed',
                        style: AppTypography.heading1.copyWith(fontSize: 22),
                      ),
                      Text(
                        'Perjalanan tersimpan & odometer bertambah',
                        style: AppTypography.captionSubtle,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: AppColors.primaryBlue),
                  tooltip: 'Bagikan Perjalanan',
                  onPressed: () {
                    Navigator.pop(context);
                    RideShareCanvas.showModal(
                      context,
                      session: result.session,
                      vehicleName: result.vehicleName,
                      isMotorcycle: isMotorcycle,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space24),

            // Metrics: Distance & Duration

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.space12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: AppSpacing.cardBorderRadius,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DISTANCE', style: AppTypography.captionBadge),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              result.session.totalDistanceKm.toStringAsFixed(1),
                              style: AppTypography.heading1.copyWith(
                                color: AppColors.primaryBlue,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('KM', style: AppTypography.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.space12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: AppSpacing.cardBorderRadius,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DURATION', style: AppTypography.captionBadge),
                        const SizedBox(height: 4),
                        Text(
                          DateFormatter.formatDuration(result.session.durationSeconds),
                          style: AppTypography.heading1.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space12),

            // Vehicle & Odometer Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: AppSpacing.cardBorderRadius,
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isMotorcycle
                            ? Icons.two_wheeler_rounded
                            : Icons.directions_car_rounded,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text('VEHICLE', style: AppTypography.captionBadge),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result.vehicleName,
                    style: AppTypography.heading2.copyWith(fontSize: 18),
                  ),
                  const Divider(height: 20, color: AppColors.borderSubtle),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ODOMETER', style: AppTypography.captionBadge),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${DateFormatter.formatKm(result.previousOdometer.toDouble())} KM',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${DateFormatter.formatKm(result.newOdometer.toDouble())} KM',
                                style: AppTypography.heading3.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (distanceDiff > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryTeal.withValues(alpha: 0.12),
                            borderRadius: AppSpacing.chipBorderRadius,
                          ),
                          child: Text(
                            '+$distanceDiff KM',
                            style: AppTypography.captionBadge.copyWith(
                              color: AppColors.secondaryTeal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space12),

            // Maintenance Status Card
            healthSummaryAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (summary) {
                // Find most urgent maintenance item (lowest remaining KM)
                final items = [...summary.healthItems];
                items.sort((a, b) => a.remainingKm.compareTo(b.remainingKm));
                final mostUrgent = items.firstOrNull;

                if (mostUrgent == null) return const SizedBox.shrink();

                Color statusColor;
                if (mostUrgent.isOverdue) {
                  statusColor = AppColors.healthCritical;
                } else if (mostUrgent.isDueSoon) {
                  statusColor = AppColors.healthWarning;
                } else {
                  statusColor = AppColors.healthOptimal;
                }

                return Container(
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: AppSpacing.cardBorderRadius,
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.build_circle_rounded,
                                size: 18,
                                color: statusColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'MAINTENANCE IMPACT',
                                style: AppTypography.captionBadge.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: AppSpacing.chipBorderRadius,
                            ),
                            child: Text(
                              mostUrgent.status,
                              style: AppTypography.captionBadge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            mostUrgent.item.itemName ?? 'Perawatan Komponen',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${DateFormatter.formatKm(mostUrgent.remainingKm.toDouble())} KM remaining',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.space24),

            // Action Buttons

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.buttonBorderRadius,
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MaintenancePage(
                      initialVehicleId: result.vehicleId,
                    ),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.build_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'View Maintenance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space8),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tutup',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
