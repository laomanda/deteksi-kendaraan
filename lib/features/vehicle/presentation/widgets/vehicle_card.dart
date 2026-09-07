import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/vehicle_model.dart';

/// Modern Automotive Card representation for a Vehicle
class VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final bool isActive;
  final VoidCallback? onTap;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMotor = vehicle.isMotorcycle;
    final healthPct = 1.0; // Default 100% health
    final healthColor = AppColors.getHealthColor(healthPct);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.cardBorderRadius,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: AppSpacing.cardBorderRadius,
            border: Border.all(
              color: isActive ? AppColors.primaryBlue : AppColors.borderSubtle,
              width: isActive ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? AppColors.primaryBlue.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Icon, Brand & Model, Active Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isMotor
                          ? AppColors.primaryBlue.withValues(alpha: 0.1)
                          : AppColors.secondaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
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
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${vehicle.year}',
                              style: AppTypography.captionSubtle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (vehicle.engineCc != null && vehicle.engineCc! > 0) ...[
                              Text(' • ', style: AppTypography.captionSubtle),
                              Text(
                                '${vehicle.engineCc} CC',
                                style: AppTypography.captionSubtle.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (vehicle.licensePlate != null &&
                                vehicle.licensePlate!.isNotEmpty) ...[
                              Text(' • ', style: AppTypography.captionSubtle),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: AppColors.borderSubtle, width: 0.5),
                                ),
                                child: Text(
                                  vehicle.licensePlate!,
                                  style: AppTypography.captionBadge.copyWith(
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Aktif',
                            style: AppTypography.captionBadge.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.space16),
              const Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: AppSpacing.space12),

              // Metrics Row: Odometer & Health
              Row(
                children: [
                  // Odometer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
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

                  // Health Status
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
                              'Health',
                              style: AppTypography.captionSubtle,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '100%',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: healthColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(Baik)',
                              style: AppTypography.captionSubtle.copyWith(
                                color: healthColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow indicator
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
      ),
    );
  }
}
