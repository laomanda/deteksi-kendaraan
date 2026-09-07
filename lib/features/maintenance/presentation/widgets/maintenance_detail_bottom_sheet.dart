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
    if (prediction.isOverdue) {
      statusColor = AppColors.healthCritical;
    } else if (prediction.isDueSoon) {
      statusColor = AppColors.healthWarning;
    } else {
      statusColor = AppColors.healthOptimal;
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

              // Title & Status
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
                        const SizedBox(height: 4),
                        Text(
                          'Kategori: ${prediction.category.toUpperCase()}',
                          style: AppTypography.captionSubtle,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.chipBorderRadius,
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      prediction.status,
                      style: AppTypography.captionBadge.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space24),

              // Health & Sisa Metrics
              Container(
                padding: const EdgeInsets.all(AppSpacing.space16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: AppSpacing.cardBorderRadius,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricCol(
                          'KESEHATAN',
                          '${prediction.currentHealth.round()}%',
                          statusColor,
                        ),
                        _buildMetricCol(
                          'SISA JARAK',
                          '${DateFormatter.formatKm(prediction.remainingKm.toDouble())} KM',
                          AppColors.textPrimary,
                        ),
                        _buildMetricCol(
                          'SISA WAKTU',
                          '${prediction.remainingDays > 0 ? prediction.remainingDays : 0} hari',
                          AppColors.textPrimary,
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.borderSubtle),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target Servis Berikutnya:', style: AppTypography.captionBadge),
                        Text(
                          '${DateFormatter.formatKm(prediction.nextServiceOdometer.toDouble())} KM',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Perkiraan Tanggal Servis:', style: AppTypography.captionBadge),
                        Text(
                          DateFormatter.formatDate(prediction.estimatedNextServiceDate),
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space16),

              // Whichever comes first advisory
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: AppSpacing.chipBorderRadius,
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: statusColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Service due in ${prediction.whicheverComesFirstText} (whichever comes first).',
                        style: AppTypography.bodySmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space24),

              // Cost Estimation Breakdown
              Text('ESTIMASI BIAYA PERAWATAN', style: AppTypography.captionBadge),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(AppSpacing.space16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: AppSpacing.cardBorderRadius,
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildCostRow('Suku Cadang (Part)', prediction.formattedPartRange),
                    const SizedBox(height: 8),
                    _buildCostRow('Biaya Jasa (Labor)', prediction.formattedLaborRange),
                    const Divider(height: 20, color: AppColors.borderSubtle),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Estimasi',
                          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          prediction.formattedTotalRange,
                          style: AppTypography.heading3.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space12),

              // Disclaimer
              Text(
                MaintenancePriceModel.priceDisclaimer,
                style: AppTypography.captionSubtle.copyWith(fontSize: 11),
              ),
              const SizedBox(height: AppSpacing.space24),

              // CTA Catat Servis
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.buttonBorderRadius,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  final vehicles = ref.read(vehicleListProvider).value ?? [];
                  final vehicle = vehicles.where((v) => v.id == vehicleId).firstOrNull;
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
                icon: const Icon(Icons.build_rounded, size: 20),
                label: const Text(
                  'Catat Servis Komponen Ini',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.captionBadge),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.heading3.copyWith(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(String label, String range) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        Text(range, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
