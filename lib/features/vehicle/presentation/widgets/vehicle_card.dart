import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../maintenance/providers/maintenance_intelligence_providers.dart';
import '../../data/models/vehicle_model.dart';

/// Modern Automotive Card representation for a Vehicle with real health & selection support
class VehicleCard extends ConsumerWidget {
  final VehicleModel vehicle;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.isActive = false,
    this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectChanged,
  });

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderSubtle, width: 0.8),
      ),
      child: Text(
        text,
        style: AppTypography.captionSubtle.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPlatePill(String plate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        plate.toUpperCase(),
        style: AppTypography.captionBadge.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMotor = vehicle.isMotorcycle;
    final healthSummaryAsync = ref.watch(maintenanceHealthProvider(vehicle.id));
    final double healthPct = healthSummaryAsync.value?.overallScore ?? 1.0;
    final healthColor = AppColors.getHealthColor(healthPct);
    final healthLabel = AppColors.getHealthStatusLabel(healthPct);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryBlue.withValues(alpha: 0.04)
            : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryBlue
              : (isActive ? AppColors.primaryBlue : AppColors.borderSubtle),
          width: isSelected ? 2.0 : (isActive ? 1.5 : 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.12)
                : (isActive
                    ? AppColors.primaryBlue.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.03)),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSelectionMode
              ? () => onSelectChanged?.call(!isSelected)
              : onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSelectionMode) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 8),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: onSelectChanged,
                      activeColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Vehicle Icon, Details, and Active Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isMotor
                                    ? [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)]
                                    : [const Color(0xFFF0FDFA), const Color(0xFFCCFBF1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isMotor
                                    ? AppColors.primaryBlue.withValues(alpha: 0.15)
                                    : AppColors.secondaryTeal.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                isMotor
                                    ? Icons.two_wheeler_rounded
                                    : Icons.directions_car_rounded,
                                color: isMotor
                                    ? AppColors.primaryBlue
                                    : AppColors.secondaryTeal,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle.displayName,
                                  style: AppTypography.heading3.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _buildPill('${vehicle.year}'),
                                    if (vehicle.engineCc != null && vehicle.engineCc! > 0)
                                      _buildPill('${vehicle.engineCc} CC'),
                                    if (vehicle.licensePlate != null &&
                                        vehicle.licensePlate!.isNotEmpty)
                                      _buildPlatePill(vehicle.licensePlate!),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isActive && !isSelectionMode) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 13,
                                    color: AppColors.primaryBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Aktif',
                                    style: AppTypography.captionBadge.copyWith(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      const Divider(height: 1, color: AppColors.borderSubtle),
                      const SizedBox(height: AppSpacing.space12),

                      // Metrics Row: Odometer & Real Health Status
                      Row(
                        children: [
                          // Odometer
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.speed_rounded,
                                      size: 14,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Odometer',
                                      style: AppTypography.captionSubtle,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormatter.formatKm(vehicle.currentKilometer),
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Real Health
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.health_and_safety_outlined,
                                      size: 14,
                                      color: healthColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Kesehatan',
                                      style: AppTypography.captionSubtle,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${(healthPct * 100).round()}%',
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: healthColor,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '($healthLabel)',
                                        style: AppTypography.captionSubtle.copyWith(
                                          color: healthColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          if (!isSelectionMode)
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                        ],
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
  }
}
