import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../vehicle/presentation/pages/vehicle_detail_page.dart';
import '../providers/dashboard_providers.dart';

/// Visual Anchor Summary Card for RideCare Dashboard
class DashboardVehicleSummaryCard extends ConsumerWidget {
  const DashboardVehicleSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return summaryAsync.when(
      loading: () => _buildLoadingSkeleton(),
      error: (err, _) => _buildErrorCard(err.toString()),
      data: (summary) {
        if (summary == null) {
          return const SizedBox.shrink();
        }

        final vehicle = summary.vehicle;
        final healthScore = summary.healthScore.round();

        // Color and badges based on Smart Priority Status
        Color statusColor;
        Color statusBgColor;
        String statusLabel;

        switch (summary.status) {
          case 'OVERDUE':
            statusColor = AppColors.healthCritical;
            statusBgColor = Colors.red.withValues(alpha: 0.12);
            statusLabel = 'OVERDUE';
            break;
          case 'DUE SOON':
            statusColor = AppColors.healthWarning;
            statusBgColor = Colors.orange.withValues(alpha: 0.12);
            statusLabel = 'DUE SOON';
            break;
          case 'GOOD':
          default:
            statusColor = AppColors.healthOptimal;
            statusBgColor = Colors.green.withValues(alpha: 0.12);
            statusLabel = 'GOOD';
            break;
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: AppSpacing.cardBorderRadius,
            border: Border.all(
              color: summary.isOverdue
                  ? AppColors.healthCritical.withValues(alpha: 0.5)
                  : (summary.isDueSoon
                      ? AppColors.healthWarning.withValues(alpha: 0.5)
                      : AppColors.borderSubtle),
              width: summary.isOverdue || summary.isDueSoon ? 1.5 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VehicleDetailPage(vehicle: vehicle),
                ),
              );
            },
            borderRadius: AppSpacing.cardBorderRadius,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Vehicle Identity & Status Chip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: vehicle.isMotorcycle
                                    ? AppColors.primaryBlue.withValues(alpha: 0.1)
                                    : AppColors.secondaryTeal.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                vehicle.isMotorcycle
                                    ? Icons.two_wheeler_rounded
                                    : Icons.directions_car_rounded,
                                color: vehicle.isMotorcycle
                                    ? AppColors.primaryBlue
                                    : AppColors.secondaryTeal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicle.displayName,
                                    style: AppTypography.heading2.copyWith(fontSize: 17),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${vehicle.year} • ${vehicle.vehicleType.toUpperCase()}',
                                    style: AppTypography.captionSubtle,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: AppSpacing.chipBorderRadius,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: AppTypography.captionBadge.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.space16),

                  // Section 3: VEHICLE HEALTH (Main Headline)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space12),
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VEHICLE HEALTH',
                              style: AppTypography.captionBadge.copyWith(
                                color: AppColors.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$healthScore%',
                              style: AppTypography.heading1.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 26,
                              ),
                            ),
                          ],
                        ),
                        // Circular Health Indicator
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                value: healthScore / 100.0,
                                strokeWidth: 4.5,
                                backgroundColor: statusColor.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                              ),
                            ),
                            Icon(
                              summary.isOverdue
                                  ? Icons.error_outline_rounded
                                  : (summary.isDueSoon
                                      ? Icons.warning_amber_rounded
                                      : Icons.check_circle_outline_rounded),
                              color: statusColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.space16),

                  // Section 4: QUICK STATUS (4-Item Grid)
                  Row(
                    children: [
                      // 1. Current Odometer
                      Expanded(
                        child: _buildQuickStatusBox(
                          label: 'Current Odometer',
                          value: DateFormatter.formatKm(vehicle.currentKilometer),
                          icon: Icons.speed_rounded,
                          iconColor: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space8),
                      // 2. Upcoming Maintenance
                      Expanded(
                        child: _buildQuickStatusBox(
                          label: 'Upcoming',
                          value: '${summary.totalUpcomingCount} item',
                          icon: Icons.schedule_rounded,
                          iconColor: summary.dueSoonCount > 0
                              ? AppColors.healthWarning
                              : AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  Row(
                    children: [
                      // 3. Overdue Items
                      Expanded(
                        child: _buildQuickStatusBox(
                          label: 'Overdue',
                          value: '${summary.overdueCount} items',
                          icon: Icons.error_outline_rounded,
                          iconColor: summary.overdueCount > 0
                              ? AppColors.healthCritical
                              : AppColors.textSecondary,
                          valueColor: summary.overdueCount > 0
                              ? AppColors.healthCritical
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space8),
                      // 4. Estimated Upcoming Cost
                      Expanded(
                        child: _buildQuickStatusBox(
                          label: 'Estimated Cost',
                          value: summary.formattedUpcomingCost,
                          icon: Icons.payments_outlined,
                          iconColor: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStatusBox({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.captionSubtle.copyWith(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.cardBorderRadius,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.cardBorderRadius,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Data kendaraan belum dapat dimuat lengkap.',
              style: AppTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
