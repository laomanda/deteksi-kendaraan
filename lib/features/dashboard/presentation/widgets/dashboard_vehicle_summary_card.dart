import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../vehicle/data/models/vehicle_model.dart';
import '../../../vehicle/presentation/pages/vehicle_detail_page.dart';
import '../providers/dashboard_providers.dart';

/// Hero Vehicle Experience Card for RideCare Dashboard
/// Transforms raw data into a humanized personal companion presentation
class DashboardVehicleSummaryCard extends ConsumerWidget {
  const DashboardVehicleSummaryCard({super.key});

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
        final isOverdue = summary.isOverdue;
        final isDueSoon = summary.isDueSoon;

        // Humanized condition copywriting (DESIGN.md Section 8 & Prompt)
        final Color statusColor;
        final Color statusDotColor;
        final String statusLabel;
        final String conditionSentence;

        if (isOverdue) {
          statusColor = AppColors.dangerRed;
          statusDotColor = AppColors.dangerRed;
          statusLabel = 'Perlu Servis';
          conditionSentence = summary.mostUrgentPrediction != null
              ? '${summary.mostUrgentPrediction!.componentName} sudah lewat batas pemakaian'
              : 'Ada komponen yang perlu diservis segera';
        } else if (isDueSoon) {
          statusColor = AppColors.warningAmber;
          statusDotColor = AppColors.warningAmber;
          statusLabel = 'Perlu Perhatian';
          conditionSentence = summary.mostUrgentPrediction != null
              ? '${summary.mostUrgentPrediction!.componentName} mendekati jadwal perawatan'
              : 'Pemeriksaan berkala disarankan dalam waktu dekat';
        } else {
          statusColor = AppColors.safeGreen;
          statusDotColor = AppColors.safeGreen;
          statusLabel = 'Siap Digunakan';
          conditionSentence = 'Semua sistem dan komponen dalam kondisi prima';
        }

        final silhouettePath = _getSilhouetteAsset(vehicle);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOverdue ? const Color(0xFFFECACA) : AppColors.borderSubtle,
              width: isOverdue ? 1.5 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A102A43),
                blurRadius: 14,
                offset: Offset(0, 4),
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
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Bar: Vehicle Info & Silhouette Art
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status pill (Solid status indicator)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusDotColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusDotColor.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: statusDotColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      statusLabel,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Vehicle Name
                              Text(
                                vehicle.displayName,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primaryNavy,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),

                              // Category & Plate
                              Text(
                                '${vehicle.isMotorcycle ? 'Sepeda Motor' : 'Mobil'} • ${vehicle.year}${vehicle.licensePlate != null && vehicle.licensePlate!.isNotEmpty ? ' • ${vehicle.licensePlate}' : ''}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.secondarySteel,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Vehicle Silhouette Graphic
                        SizedBox(
                          width: 86,
                          height: 72,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 76,
                                height: 76,
                                decoration: const BoxDecoration(
                                  color: AppColors.background,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SvgPicture.asset(
                                silhouettePath,
                                width: 70,
                                height: 52,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF1EFE9)),
                    const SizedBox(height: 14),

                    // 2. Metrics & Companion Condition
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Kilometer in Space Grotesk (Hero visual)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL JARAK',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${DateFormatter.formatKm(vehicle.currentKilometer, includeUnit: false)} KM',
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.primaryNavy,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tap for detail button
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Detail Kendaraan',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primaryNavy,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColors.secondarySteel,
                                size: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 3. Human Condition Description Strip
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? const Color(0xFFFEF2F2)
                            : (isDueSoon ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isOverdue
                              ? const Color(0xFFFECACA)
                              : (isDueSoon ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isOverdue
                                ? Icons.warning_amber_rounded
                                : (isDueSoon ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded),
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              conditionSentence,
                              style: GoogleFonts.plusJakartaSans(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
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
        border: Border.all(color: AppColors.borderSubtle),
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
