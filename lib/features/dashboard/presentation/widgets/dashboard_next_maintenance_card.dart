import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../maintenance/presentation/widgets/maintenance_detail_bottom_sheet.dart';
import '../../../maintenance/presentation/widgets/vehicle_part_icon_badge.dart';
import '../../../maintenance/providers/maintenance_prediction_providers.dart';

/// Single Source of Truth for Nearest / Urgent Maintenance Action
/// Cohesive, harmonious color styling without conflicting hues
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
            padding: const EdgeInsets.all(AppSpacing.space16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 22,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semua Komponen Terawat',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tidak ada jadwal servis mendesak saat ini.',
                        style: TextStyle(
                          color: Color(0xFF15803D),
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

        // Scoped unified color scheme for this card to prevent clashing
        final Color themeColor;
        final Color themeLightBg;
        final Color themeBorder;
        final IconData headerIcon;
        final String statusLabel;

        if (isOverdue) {
          themeColor = const Color(0xFFDC2626);
          themeLightBg = const Color(0xFFFEF2F2);
          themeBorder = const Color(0xFFFECACA);
          headerIcon = Icons.error_outline_rounded;
          statusLabel = 'Lewat Jadwal';
        } else if (isDueSoon) {
          themeColor = const Color(0xFFD97706);
          themeLightBg = const Color(0xFFFFFBEB);
          themeBorder = const Color(0xFFFDE68A);
          headerIcon = Icons.warning_amber_rounded;
          statusLabel = 'Perlu Perhatian';
        } else {
          themeColor = const Color(0xFF2563EB);
          themeLightBg = const Color(0xFFEFF6FF);
          themeBorder = const Color(0xFFBFDBFE);
          headerIcon = Icons.event_note_rounded;
          statusLabel = 'Jadwal Berkala';
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isOverdue ? themeBorder : const Color(0xFFE2E8F0),
              width: isOverdue ? 1.2 : 1.0,
            ),
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
                MaintenanceDetailBottomSheet.show(
                  context,
                  prediction: nextItem,
                  vehicleId: activeVehicle.id,
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: Section title & status pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              headerIcon,
                              size: 17,
                              color: themeColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Tindakan Disarankan',
                              style: TextStyle(
                                color: AppColors.textPrimary,
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
                            color: themeLightBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: themeBorder),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Component Name & Icon (Both themed harmoniously)
                    Row(
                      children: [
                        VehiclePartIconBadge(
                          componentName: nextItem.componentName,
                          category: nextItem.category,
                          status: nextItem.status,
                          size: 42,
                          iconSize: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nextItem.componentName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isOverdue
                                    ? 'Sudah melewati batas pemakaian. Segera servis.'
                                    : 'Perkiraan: ${nextItem.remainingKm > 0 ? DateFormatter.formatKm(nextItem.remainingKm.toDouble()) : '0 km'} lagi (${nextItem.remainingDays > 0 ? '${nextItem.remainingDays} hari' : 'segera'})',
                                style: TextStyle(
                                  color: isOverdue
                                      ? const Color(0xFFDC2626)
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight:
                                      isOverdue ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),

                    // Bottom Row: Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Jadwal Servis Berkala',
                          style: TextStyle(
                            color: Color(0xFF64748B),
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
                            color: themeLightBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: themeBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lihat Detail',
                                style: TextStyle(
                                  color: themeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: themeColor,
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
