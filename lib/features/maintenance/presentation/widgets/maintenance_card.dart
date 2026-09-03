import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/component_catalog.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../garage/data/models/vehicle_model.dart';
import '../../domain/health_calculation_service.dart';
import 'dynamic_fill_icon.dart';
import 'record_service_sheet.dart';

/// MaintenanceCard (DSS Section 8.3 & Table 10)
class MaintenanceCard extends StatelessWidget {
  final ComponentHealthResult result;
  final VehicleModel vehicle;

  const MaintenanceCard({
    super.key,
    required this.result,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    final meta = ComponentCatalog.findMetadata(
      vehicle.vehicleType,
      result.item.componentType,
    );
    final componentName = meta?.displayName ?? result.item.componentType;

    // Remaining text formulation
    String remainingText;
    if (result.item.intervalKm > 0) {
      final remKmStr = DateFormatter.formatKm(result.remainingKm);
      remainingText = 'Tersisa $remKmStr atau ≈ ${result.remainingDays} hari';
    } else {
      // Time-only component (e.g. battery)
      remainingText = 'Tersisa ≈ ${result.remainingDays} hari';
    }

    if (result.isCritical) {
      remainingText = 'Jatuh tempo! Segera lakukan servis';
    }

    final lastServiceKmStr = DateFormatter.formatKm(result.item.lastServiceKm);
    final lastServiceDateStr = DateFormatter.formatDate(result.item.lastServiceDate);
    final lastServiceText = 'Servis lalu: $lastServiceKmStr ($lastServiceDateStr)';

    final statusColor = AppColors.getHealthColor(result.fraction);

    return Semantics(
      label: 'Status $componentName: $remainingText, $lastServiceText',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space12),
        padding: const EdgeInsets.all(AppSpacing.space16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppSpacing.cardBorderRadius,
          border: Border.all(
            color: result.isCritical
                ? AppColors.healthCritical
                : result.isWarning
                    ? AppColors.healthWarning
                    : AppColors.borderSubtle,
            width: result.isCritical ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Left Anchor: DynamicFillIcon
            DynamicFillIcon(
              componentType: result.item.componentType,
              percentage: result.fraction,
              size: 44.0,
            ),
            const SizedBox(width: AppSpacing.space16),

            // 2. Center Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          componentName,
                          style: AppTypography.heading3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Status dot badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: AppSpacing.chipBorderRadius,
                        ),
                        child: Text(
                          '${result.healthPercentage.toInt()}%',
                          style: AppTypography.captionBadge.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    remainingText,
                    style: AppTypography.bodySmall.copyWith(
                      color: result.isCritical
                          ? AppColors.healthCritical
                          : result.isWarning
                              ? AppColors.healthWarning
                              : AppColors.textSecondary,
                      fontWeight:
                          result.isCritical ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastServiceText,
                    style: AppTypography.captionSubtle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space12),

            // 3. Right Anchor: Catat Servis button
            InkWell(
              onTap: () => RecordServiceSheet.show(
                context,
                result: result,
                vehicle: vehicle,
              ),
              borderRadius: AppSpacing.buttonBorderRadius,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space12,
                  vertical: AppSpacing.space8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: AppSpacing.buttonBorderRadius,
                ),
                child: Text(
                  'Catat Servis',
                  style: AppTypography.captionBadge.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
