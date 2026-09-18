import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../maintenance/providers/maintenance_intelligence_providers.dart';
import '../../../maintenance/providers/maintenance_prediction_providers.dart';
import '../../data/models/vehicle_model.dart';

/// Compact automotive collection card adhering to DESIGN.md
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

  String _getSilhouetteAsset(VehicleModel v) {
    if (!v.isMotorcycle) {
      return 'assets/vehicles/vehicle_silhouette_car.svg';
    }
    final trans = (v.transmission ?? '').toLowerCase();
    if (trans.contains('manual') || trans.contains('kopling') || trans.contains('sport')) {
      return 'assets/vehicles/vehicle_silhouette_manual.svg';
    }
    return 'assets/vehicles/vehicle_silhouette_scooter.svg';
  }

  String _formatKm(double km) {
    final formatted = NumberFormat('#,##0', 'id_ID').format(km.round());
    return '$formatted KM';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingMaintenanceProvider(vehicle.id));
    final healthSummaryAsync = ref.watch(maintenanceHealthProvider(vehicle.id));

    // Humanized condition derivation (DESIGN.md Section 4 & 5)
    String conditionLabel = 'Kondisi prima';
    String conditionReason = 'Siap digunakan';
    Color conditionColor = AppColors.success;

    final summary = healthSummaryAsync.value;
    final upcomingList = upcomingAsync.value ?? [];

    if (summary != null && summary.overdueCount > 0) {
      conditionLabel = 'Perlu perhatian';
      conditionColor = AppColors.danger;
      final overdueItem = upcomingList.where((p) => p.isOverdue).firstOrNull;
      conditionReason = overdueItem != null
          ? '${overdueItem.componentName}: perlu dilakukan segera'
          : 'Perlu dilakukan segera';
    } else if (summary != null && summary.dueSoonCount > 0) {
      conditionLabel = 'Perlu perhatian';
      conditionColor = AppColors.warning;
      final dueSoonItem = upcomingList.where((p) => p.isDueSoon).firstOrNull;
      conditionReason = dueSoonItem != null
          ? '${dueSoonItem.componentName}: mendekati jadwal perawatan'
          : 'Mendekati jadwal perawatan';
    } else if (upcomingList.isNotEmpty) {
      conditionLabel = 'Kondisi prima';
      conditionColor = AppColors.success;
      final firstItem = upcomingList.first;
      conditionReason = '${firstItem.componentName}: disarankan dalam ${DateFormatter.formatKm(firstItem.remainingKm.toDouble())}';
    }

    final silhouetteAsset = _getSilhouetteAsset(vehicle);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryNavy.withValues(alpha: 0.05)
            : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryNavy
              : (isActive ? AppColors.accentCyan : AppColors.borderSubtle),
          width: isSelected ? 2.0 : (isActive ? 1.6 : 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? AppColors.accentCyan.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isActive ? 10 : 6,
            offset: const Offset(0, 2),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (isSelectionMode) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: onSelectChanged,
                      activeColor: AppColors.primaryNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],

                // Silhouette Thumbnail Container
                Container(
                  width: 58,
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5EF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle, width: 0.8),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      silhouetteAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),

                // Vehicle Details & Humanized Condition
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              vehicle.displayName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${vehicle.year}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (vehicle.licensePlate != null && vehicle.licensePlate!.isNotEmpty) ...[
                            Text(
                              vehicle.licensePlate!.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                            const SizedBox(width: 6),
                          ],
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: conditionColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              conditionLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: conditionColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        conditionReason,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Space Grotesk Odometer & Active Indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatKm(vehicle.currentKilometer),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isActive) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AppColors.accentCyan,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Aktif',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (!isSelectionMode) ...[
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
