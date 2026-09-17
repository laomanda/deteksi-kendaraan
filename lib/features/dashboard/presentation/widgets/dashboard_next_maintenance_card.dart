import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../maintenance/presentation/widgets/maintenance_detail_bottom_sheet.dart';
import '../../../maintenance/presentation/widgets/vehicle_part_icon_badge.dart';
import '../../../maintenance/providers/maintenance_prediction_providers.dart';

/// Intelligent Warning Experience Card for RideCare Dashboard (DESIGN.md Section 14)
/// Highlights nearest recommended maintenance without looking like an alarm siren
class DashboardNextMaintenanceCard extends ConsumerWidget {
  final VoidCallback? onNavigateToMaintenance;

  const DashboardNextMaintenanceCard({
    super.key,
    this.onNavigateToMaintenance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    if (activeVehicle == null) {
      return const SizedBox.shrink();
    }

    final upcomingAsync = ref.watch(upcomingMaintenanceProvider(activeVehicle.id));

    return upcomingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06102A43),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0FDF4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.safeGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semua Komponen Prima',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primaryNavy,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Tidak ada jadwal perawatan mendesak saat ini.',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.secondarySteel,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final nextItem = items.first;
        final isOverdue = nextItem.isOverdue;
        final isDueSoon = nextItem.isDueSoon;

        final Color statusColor;
        final Color statusLightBg;
        final Color statusBorder;
        final String statusPillLabel;
        final String recommendationText;

        if (isOverdue) {
          statusColor = AppColors.dangerRed;
          statusLightBg = const Color(0xFFFEF2F2);
          statusBorder = const Color(0xFFFECACA);
          statusPillLabel = 'Lewat Jadwal';
          recommendationText = 'Disarankan ganti segera (0 KM lagi)';
        } else if (isDueSoon) {
          statusColor = AppColors.warningAmber;
          statusLightBg = const Color(0xFFFFFBEB);
          statusBorder = const Color(0xFFFDE68A);
          statusPillLabel = 'Perlu Perhatian';
          final kmText = nextItem.remainingKm > 0
              ? '${DateFormatter.formatKm(nextItem.remainingKm.toDouble(), includeUnit: false)} KM'
              : '0 KM';
          recommendationText = 'Disarankan dalam $kmText lagi';
        } else {
          statusColor = AppColors.accentCyan;
          statusLightBg = const Color(0xFFF0FDFA);
          statusBorder = const Color(0xFFCCFBF1);
          statusPillLabel = 'Jadwal Berkala';
          final kmText = nextItem.remainingKm > 0
              ? '${DateFormatter.formatKm(nextItem.remainingKm.toDouble(), includeUnit: false)} KM'
              : '0 KM';
          recommendationText = 'Disarankan dalam $kmText lagi';
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isOverdue ? const Color(0xFFFECACA) : AppColors.borderSubtle,
              width: isOverdue ? 1.4 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08102A43),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                MaintenanceDetailBottomSheet.show(
                  context,
                  prediction: nextItem,
                  vehicleId: activeVehicle.id,
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Section label & Status Tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Perawatan Berikutnya',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.primaryNavy,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusLightBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusBorder),
                          ),
                          child: Text(
                            statusPillLabel,
                            style: GoogleFonts.plusJakartaSans(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Component Details & Icon Badge
                    Row(
                      children: [
                        VehiclePartIconBadge(
                          componentName: nextItem.componentName,
                          category: nextItem.category,
                          status: nextItem.status,
                          healthPercentage: nextItem.currentHealth,
                          size: 46,
                          iconSize: 24,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nextItem.componentName,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primaryNavy,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                recommendationText,
                                style: GoogleFonts.plusJakartaSans(
                                  color: isOverdue ? AppColors.dangerRed : AppColors.secondarySteel,
                                  fontSize: 12,
                                  fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF1EFE9)),
                    const SizedBox(height: 12),

                    // Bottom Row: Clear Companion CTA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Rekomendasi Servis',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
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
                                'Lihat Perawatan',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primaryNavy,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppColors.primaryNavy,
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
}
