import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../vehicle/presentation/pages/vehicle_detail_page.dart';
import '../providers/dashboard_providers.dart';

/// Simplified Human-Centric Vehicle Status Card for RideCare Dashboard
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

        // Visual properties based on Smart Priority Status
        Color statusColor;
        Color statusBgColor;
        IconData statusIcon;

        if (summary.isOverdue) {
          statusColor = AppColors.healthCritical;
          statusBgColor = Colors.red.withValues(alpha: 0.1);
          statusIcon = Icons.error_rounded;
        } else if (summary.isDueSoon) {
          statusColor = AppColors.healthWarning;
          statusBgColor = Colors.orange.withValues(alpha: 0.1);
          statusIcon = Icons.warning_rounded;
        } else {
          statusColor = AppColors.healthOptimal;
          statusBgColor = Colors.green.withValues(alpha: 0.1);
          statusIcon = Icons.check_circle_rounded;
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: AppSpacing.cardBorderRadius,
            border: Border.all(
              color: summary.isOverdue || summary.isDueSoon
                  ? statusColor.withValues(alpha: 0.4)
                  : AppColors.borderSubtle,
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
                  // 1. Header: Identitas Kendaraan & Navigasi ke Detail
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
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicle.displayName,
                                    style: AppTypography.heading2.copyWith(fontSize: 18),
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
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.space16),

                  // 2. STATUS KENDARAAN (Pesan Utama dalam Bahasa Manusia)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.space16),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              summary.humanStatusTitle,
                              style: AppTypography.heading2.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          summary.humanStatusSubtitle,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.space16),

                  // 3. INFORMASI PENDUKUNG (Total Jarak Kendaraan & Aksi/Biaya)
                  Row(
                    children: [
                      // Total Jarak Kendaraan
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Jarak Kendaraan',
                              style: AppTypography.captionSubtle.copyWith(fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormatter.formatKm(vehicle.currentKilometer),
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Estimasi Biaya jika ada servis yang perlu diperhatikan
                      if (summary.isOverdue || summary.isDueSoon) ...[
                        Container(
                          height: 32,
                          width: 1,
                          color: AppColors.borderSubtle,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Perkiraan Biaya',
                                style: AppTypography.captionSubtle.copyWith(fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                summary.formattedUpcomingCost,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBlue,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
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
