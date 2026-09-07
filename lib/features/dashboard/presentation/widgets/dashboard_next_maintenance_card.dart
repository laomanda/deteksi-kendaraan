import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../maintenance/presentation/pages/maintenance_page.dart';
import '../../../maintenance/presentation/widgets/maintenance_detail_bottom_sheet.dart';
import '../../../maintenance/providers/maintenance_prediction_providers.dart';

/// Next Maintenance Card with Smart Priority (OVERDUE > DUE SOON > GOOD)
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
              color: AppColors.surfaceWhite,
              borderRadius: AppSpacing.cardBorderRadius,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.healthOptimal,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semua Komponen Optimal',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Belum ada jadwal servis yang mendesak.',
                        style: AppTypography.captionSubtle,
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

        Color badgeColor;
        Color badgeBgColor;
        Color cardBorderColor;
        IconData headerIcon;
        String headerTitle;

        if (isOverdue) {
          badgeColor = AppColors.healthCritical;
          badgeBgColor = Colors.red.withValues(alpha: 0.12);
          cardBorderColor = AppColors.healthCritical.withValues(alpha: 0.6);
          headerIcon = Icons.warning_rounded;
          headerTitle = 'MAINTENANCE REQUIRED';
        } else if (isDueSoon) {
          badgeColor = AppColors.healthWarning;
          badgeBgColor = Colors.orange.withValues(alpha: 0.12);
          cardBorderColor = AppColors.healthWarning.withValues(alpha: 0.5);
          headerIcon = Icons.build_circle_rounded;
          headerTitle = 'NEXT MAINTENANCE';
        } else {
          badgeColor = AppColors.healthOptimal;
          badgeBgColor = Colors.green.withValues(alpha: 0.12);
          cardBorderColor = AppColors.borderSubtle;
          headerIcon = Icons.event_available_rounded;
          headerTitle = 'SCHEDULED MAINTENANCE';
        }

        return Container(
          decoration: BoxDecoration(
            color: isOverdue ? const Color(0xFFFFF7F7) : AppColors.surfaceWhite,
            borderRadius: AppSpacing.cardBorderRadius,
            border: Border.all(
              color: cardBorderColor,
              width: isOverdue || isDueSoon ? 1.5 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              MaintenanceDetailBottomSheet.show(
                context,
                prediction: nextItem,
                vehicleId: activeVehicle.id,
              );
            },
            borderRadius: AppSpacing.cardBorderRadius,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with Icon, Title, and Urgency Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            headerIcon,
                            size: 18,
                            color: isOverdue
                                ? AppColors.healthCritical
                                : AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            headerTitle,
                            style: AppTypography.captionBadge.copyWith(
                              color: isOverdue
                                  ? AppColors.healthCritical
                                  : AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
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
                          color: badgeBgColor,
                          borderRadius: AppSpacing.chipBorderRadius,
                        ),
                        child: Text(
                          nextItem.status,
                          style: AppTypography.captionBadge.copyWith(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.space12),

                  // Component Name
                  Text(
                    nextItem.componentName,
                    style: AppTypography.heading2.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 4),

                  // Sisa KM and Days
                  Text(
                    isOverdue
                        ? 'Servis terlewat! Segera lakukan penggantian di bengkel.'
                        : '${nextItem.remainingKm > 0 ? DateFormatter.formatKm(nextItem.remainingKm.toDouble()) : '0 KM'} remaining • ${nextItem.remainingDays > 0 ? '${nextItem.remainingDays} days' : 'Hari ini'}',
                    style: AppTypography.bodySmall.copyWith(
                      color: isOverdue
                          ? AppColors.healthCritical
                          : AppColors.textSecondary,
                      fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  const SizedBox(height: 10),

                  // Bottom Row: Estimated Cost and View Maintenance CTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estimated:', style: AppTypography.captionSubtle),
                          const SizedBox(height: 1),
                          Text(
                            nextItem.formattedCompactRange,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          if (onNavigateToMaintenance != null) {
                            onNavigateToMaintenance!();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MaintenancePage(
                                  initialVehicleId: activeVehicle.id,
                                ),
                              ),
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                        icon: const Text('View Maintenance'),
                        label: const Icon(Icons.arrow_forward_rounded, size: 16),
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
}
