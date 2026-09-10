import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../vehicle/providers/vehicle_provider.dart';
import '../../data/models/maintenance_price_model.dart';
import '../../domain/maintenance_prediction_service.dart';
import '../pages/add_service_page.dart';

/// Simplified Human-First Maintenance Detail Bottom Sheet
class MaintenanceDetailBottomSheet extends ConsumerWidget {
  final MaintenancePrediction prediction;
  final String vehicleId;

  const MaintenanceDetailBottomSheet({
    super.key,
    required this.prediction,
    required this.vehicleId,
  });

  static Future<void> show(
    BuildContext context, {
    required MaintenancePrediction prediction,
    required String vehicleId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MaintenanceDetailBottomSheet(
        prediction: prediction,
        vehicleId: vehicleId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusColor;
    String statusText;
    String reasonText;

    if (prediction.isOverdue) {
      statusColor = AppColors.healthCritical;
      statusText = 'Lewat Jadwal';
      reasonText = 'Sudah melewati batas pemakaian yang disarankan.';
    } else if (prediction.isDueSoon) {
      statusColor = AppColors.healthWarning;
      statusText = 'Segera Diganti';
      reasonText =
          'Sudah mendekati batas pemakaian (${DateFormatter.formatKm(prediction.remainingKm.toDouble())} KM lagi).';
    } else {
      statusColor = AppColors.healthOptimal;
      statusText = 'Kondisi Baik';
      reasonText = 'Masih dalam batas pemakaian yang aman.';
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.modalTopRadius,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space24,
        AppSpacing.space16,
        AppSpacing.space24,
        AppSpacing.space24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space16),

              // Title & Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prediction.componentName,
                          style: AppTypography.heading1.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prediction.category,
                          style: AppTypography.captionSubtle,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.chipBorderRadius,
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      statusText,
                      style: AppTypography.captionBadge.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space16),

              // 1. Kenapa? (Alasan Jelas & Ramah Awam)
              Container(
                padding: const EdgeInsets.all(AppSpacing.space16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: AppSpacing.cardBorderRadius,
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 18, color: statusColor),
                        const SizedBox(width: 8),
                        Text(
                          'Kondisi Komponen',
                          style: AppTypography.captionBadge.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reasonText,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.space16),

              // 2. Perkiraan Biaya Ringkas
              Container(
                padding: const EdgeInsets.all(AppSpacing.space16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: AppSpacing.cardBorderRadius,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Perkiraan Biaya',
                            style: AppTypography.captionSubtle),
                        const SizedBox(height: 2),
                        Text(
                          prediction.formattedTotalRange,
                          style: AppTypography.heading2.copyWith(
                            color: AppColors.primaryBlue,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.payments_outlined,
                      color: AppColors.primaryBlue,
                      size: 28,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.space16),

              // 3. Tombol Utama: Catat Servis Komponen Ini
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    final vehicle = ref
                        .read(vehicleListProvider)
                        .value
                        ?.where((v) => v.id == vehicleId)
                        .firstOrNull;

                    if (vehicle != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddServicePage(
                            vehicle: vehicle,
                            preselectedItem: prediction.item,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonBorderRadius,
                    ),
                  ),
                  icon: const Icon(Icons.build_rounded, size: 18),
                  label: const Text(
                    'Catat Servis Komponen Ini',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.space16),

              // 4. Detail Teknis & Interval (Lipat / Collapsible untuk user yang ingin tahu)
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Detail Teknis & Interval',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.space16),
                      decoration: BoxDecoration(
                        color: AppColors.bgLight,
                        borderRadius: AppSpacing.cardBorderRadius,
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          _buildCostRow(
                            'Perkiraan Suku Cadang',
                            prediction.formattedPartRange,
                          ),
                          const SizedBox(height: 6),
                          _buildCostRow(
                            'Perkiraan Ongkos Jasa',
                            prediction.formattedLaborRange,
                          ),
                          const Divider(height: 16),
                          _buildCostRow(
                            'Rekomendasi Servis',
                            '${DateFormatter.formatKm(prediction.nextServiceOdometer.toDouble())} KM',
                          ),
                          const SizedBox(height: 6),
                          _buildCostRow(
                            'Perkiraan Waktu',
                            DateFormatter.formatDate(
                                prediction.estimatedNextServiceDate),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            MaintenancePriceModel.priceDisclaimer,
                            style: AppTypography.captionSubtle.copyWith(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
