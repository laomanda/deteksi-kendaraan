import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../vehicle/presentation/pages/vehicle_detail_page.dart';
import '../providers/dashboard_providers.dart';

/// Clean, Harmonious Hero Vehicle Card for RideCare Dashboard
/// Matches the app's clean porcelain aesthetic with zero clashing colors
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

        // Visual properties strictly scoped by status for harmonious palette
        final Color statusBg;
        final Color statusBorder;
        final Color statusColor;
        final IconData statusIcon;
        final String statusText;

        if (summary.isOverdue) {
          statusBg = const Color(0xFFFEF2F2);
          statusBorder = const Color(0xFFFECACA);
          statusColor = const Color(0xFFDC2626);
          statusIcon = Icons.error_outline_rounded;
          statusText = summary.mostUrgentPrediction != null
              ? 'Perlu Servis: ${summary.mostUrgentPrediction!.componentName}'
              : 'Perlu Servis Segera';
        } else if (summary.isDueSoon) {
          statusBg = const Color(0xFFFFFBEB);
          statusBorder = const Color(0xFFFDE68A);
          statusColor = const Color(0xFFD97706);
          statusIcon = Icons.warning_amber_rounded;
          statusText = summary.mostUrgentPrediction != null
              ? 'Perlu Perhatian: ${summary.mostUrgentPrediction!.componentName}'
              : 'Perlu Perhatian';
        } else {
          statusBg = const Color(0xFFF0FDF4);
          statusBorder = const Color(0xFFBBF7D0);
          statusColor = const Color(0xFF16A34A);
          statusIcon = Icons.check_circle_outline_rounded;
          statusText = 'Kondisi Prima • Semua Komponen Terawat';
        }

        final healthPct = summary.healthScore.clamp(0.0, 100.0);
        final healthColor = summary.isOverdue
            ? const Color(0xFFDC2626)
            : (healthPct < 50 ? const Color(0xFFD97706) : const Color(0xFF16A34A));

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VehicleDetailPage(vehicle: vehicle),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header: Vehicle Identity & Detail Action
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF), // Soft clean blue
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            vehicle.isMotorcycle
                                ? Icons.two_wheeler_rounded
                                : Icons.directions_car_rounded,
                            color: const Color(0xFF2563EB),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.displayName,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${vehicle.isMotorcycle ? 'Sepeda Motor' : 'Mobil'} • ${vehicle.year}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Detail',
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF64748B),
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 2. Status Capsule (Harmonious pastel background with clear dark text)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Divider hairline
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),

                    const SizedBox(height: 12),

                    // 3. Supporting Metrics: Odometer & Health Score
                    Row(
                      children: [
                        // Total Odometer
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL JARAK',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                DateFormatter.formatKm(vehicle.currentKilometer),
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Vertical Separator
                        Container(
                          width: 1,
                          height: 30,
                          color: const Color(0xFFF1F5F9),
                        ),
                        const SizedBox(width: 16),

                        // Vehicle Health
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'KESEHATAN MESIN',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: healthColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${healthPct.round()}%',
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      summary.isOverdue
                                          ? 'Perlu Servis'
                                          : (healthPct < 50 ? 'Waspada' : 'Prima'),
                                      style: TextStyle(
                                        color: healthColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Data kendaraan belum dapat dimuat.',
              style: AppTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
