import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/constants/component_catalog.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../garage/data/models/vehicle_model.dart';
import '../../data/models/maintenance_price_model.dart';
import '../../data/models/vehicle_maintenance_model.dart';
import '../../domain/health_calculation_service.dart';
import '../../domain/maintenance_prediction_service.dart';
import 'maintenance_detail_bottom_sheet.dart';
import 'record_service_sheet.dart';
import 'vehicle_part_icon_badge.dart';

/// MaintenanceCard (DESIGN.md & DSS Section 8.3)
/// Rich companion presentation with genuine SVG part art, accurate condition colors, and Space Grotesk pricing
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

    // Resolve realistic status copy and colors
    final Color statusColor;
    final Color statusLightBg;
    final Color statusBorder;
    final String statusLabel;
    final String remainingText;

    if (result.isCritical) {
      statusColor = AppColors.dangerRed;
      statusLightBg = const Color(0xFFFEF2F2);
      statusBorder = const Color(0xFFFECACA);
      statusLabel = 'Waktunya melakukan perawatan';
      remainingText = 'Perkiraan: 0 KM lagi (Lewat jadwal)';
    } else if (result.isWarning) {
      statusColor = AppColors.warningAmber;
      statusLightBg = const Color(0xFFFFFBEB);
      statusBorder = const Color(0xFFFDE68A);
      statusLabel = 'Mendekati jadwal perawatan';
      final remKmStr = DateFormatter.formatKm(result.remainingKm);
      remainingText = 'Perkiraan: $remKmStr lagi';
    } else {
      statusColor = AppColors.safeGreen;
      statusLightBg = const Color(0xFFF0FDF4);
      statusBorder = const Color(0xFFBBF7D0);
      statusLabel = 'Kondisi prima';
      final remKmStr = DateFormatter.formatKm(result.remainingKm);
      remainingText = result.item.intervalKm > 0
          ? 'Perkiraan: $remKmStr lagi'
          : 'Perkiraan: ≈ ${result.remainingDays} hari lagi';
    }

    final lastServiceKmStr = DateFormatter.formatKm(result.item.lastServiceKm);
    final lastServiceDateStr = DateFormatter.formatDate(result.item.lastServiceDate);
    final lastServiceText = 'Riwayat perawatan terakhir: $lastServiceKmStr ($lastServiceDateStr)';

    // Price forecast lookup
    final priceEstimate = MaintenancePriceModel.getPriceForMaintenance(
      componentName,
      vehicleType: vehicle.vehicleType,
    );
    final String priceText;
    if (priceEstimate != null) {
      priceText = priceEstimate.formattedTotalRange;
    } else {
      priceText = 'Rp50.000 - Rp150.000';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: result.isCritical ? const Color(0xFFFECACA) : AppColors.borderSubtle,
          width: result.isCritical ? 1.4 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06102A43),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final vm = VehicleMaintenanceModel(
              id: result.item.id,
              vehicleId: vehicle.id,
              maintenanceId: result.item.componentType,
              itemName: componentName,
              lastServiceDate: result.item.lastServiceDate,
              lastServiceOdometer: result.item.lastServiceKm.toInt(),
              healthPercentage: result.healthPercentage.toInt(),
              status: result.isCritical
                  ? 'OVERDUE'
                  : (result.isWarning ? 'DUE SOON' : 'GOOD'),
              intervalKm: result.item.intervalKm.toInt(),
            );
            final pred = MaintenancePrediction(
              item: vm,
              componentName: componentName,
              category: 'Perawatan',
              currentHealth: result.healthPercentage,
              remainingKm: result.remainingKm.toInt(),
              usedKm: result.deltaKm.toInt(),
              nextServiceOdometer: (result.item.lastServiceKm + result.item.intervalKm).toInt(),
              remainingDays: result.remainingDays,
              estimatedNextServiceDate: DateTime.now().add(Duration(days: result.remainingDays)),
              status: result.isCritical
                  ? 'OVERDUE'
                  : (result.isWarning ? 'DUE SOON' : 'GOOD'),
              urgencyGroup: result.isCritical ? 'URGENT' : 'UPCOMING',
              whicheverComesFirstText: 'Berdasarkan kilometer atau waktu',
              priceEstimate: priceEstimate,
              partMin: priceEstimate?.minPrice ?? 40000,
              partMax: priceEstimate?.maxPrice ?? 120000,
              laborMin: priceEstimate?.laborMin ?? 20000,
              laborMax: priceEstimate?.laborMax ?? 40000,
              totalMin: priceEstimate?.minTotal ?? 60000,
              totalMax: priceEstimate?.maxTotal ?? 160000,
            );
            MaintenanceDetailBottomSheet.show(
              context,
              prediction: pred,
              vehicleId: vehicle.id,
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: SVG Part Thumbnail & Name & Status Tag
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VehiclePartIconBadge(
                      componentName: componentName,
                      category: 'Perawatan',
                      status: result.isCritical
                          ? 'OVERDUE'
                          : (result.isWarning ? 'DUE SOON' : 'GOOD'),
                      healthPercentage: result.healthPercentage,
                      size: 48,
                      iconSize: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  componentName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryNavy,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Humanized Condition Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusLightBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: statusBorder),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Estimated remaining
                          Text(
                            remainingText,
                            style: GoogleFonts.plusJakartaSans(
                              color: result.isCritical
                                  ? AppColors.dangerRed
                                  : AppColors.secondarySteel,
                              fontSize: 12,
                              fontWeight: result.isCritical ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1EFE9)),
                const SizedBox(height: 10),

                // 2. Metrics & Cost Estimate
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cost Estimate in Space Grotesk
                    Row(
                      children: [
                        Text(
                          'Estimasi: ',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          priceText,
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.primaryNavy,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    // Action: Simpan Perawatan
                    InkWell(
                      onTap: () => RecordServiceSheet.show(
                        context,
                        result: result,
                        vehicle: vehicle,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
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
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedWrench01,
                              size: 14,
                              color: AppColors.primaryNavy,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Simpan Perawatan',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.primaryNavy,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // 3. Service History Footnote
                Text(
                  lastServiceText,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
