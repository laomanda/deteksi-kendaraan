import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../vehicle/providers/vehicle_provider.dart';
import '../../domain/maintenance_prediction_service.dart';
import 'record_service_sheet.dart';
import 'vehicle_part_icon_badge.dart';

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
    String statusTitle;

    if (prediction.isOverdue) {
      statusColor = AppColors.healthCritical;
      statusTitle = 'Perlu Servis Sekarang';
    } else if (prediction.isDueSoon) {
      statusColor = AppColors.healthWarning;
      statusTitle = 'Segera Lakukan Pengecekan';
    } else {
      statusColor = AppColors.healthOptimal;
      statusTitle = 'Kondisi Komponen Baik';
    }

    final String reasonText;
    if (prediction.isOverdue) {
      reasonText = 'Sudah melewati batas pemakaian yang disarankan.';
    } else if (prediction.isDueSoon) {
      reasonText =
          'Sudah mendekati batas pemakaian (${DateFormatter.formatKm(prediction.remainingKm.toDouble())} lagi).';
    } else {
      reasonText = 'Masih dalam batas pemakaian yang aman.';
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Category with Spare Part Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  VehiclePartIconBadge(
                    componentName: prediction.componentName,
                    category: prediction.category,
                    status: prediction.status,
                    healthPercentage: prediction.currentHealth,
                    size: 50,
                    iconSize: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prediction.componentName,
                          style: AppTypography.heading1.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (prediction.item.itemCategory ?? prediction.category).toUpperCase(),
                          style: AppTypography.captionBadge.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space16),

              // 1. Status & Alasan (Humanized Summary)
              Container(
                padding: const EdgeInsets.all(AppSpacing.space16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: AppSpacing.cardBorderRadius,
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          prediction.isOverdue
                              ? Icons.error_outline_rounded
                              : (prediction.isDueSoon
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline_rounded),
                          color: statusColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusTitle,
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

              // 2. Tombol Utama: Catat Servis Komponen Ini
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
                      RecordServiceSheet.show(
                        context,
                        vehicle: vehicle,
                        componentType: prediction.item.itemKey,
                        componentName: prediction.componentName,
                        lastServiceKm: prediction.item.lastServiceOdometer.toDouble(),
                        intervalKm: prediction.item.intervalKm?.toDouble(),
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

              // 3. Detail Teknis & Interval
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
                          _buildInfoRow(
                            'Rekomendasi Servis',
                            DateFormatter.formatKm(prediction.nextServiceOdometer.toDouble()),
                          ),
                          const SizedBox(height: 6),
                          _buildInfoRow(
                            'Perkiraan Waktu',
                            DateFormatter.formatDate(
                                prediction.estimatedNextServiceDate),
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

  Widget _buildInfoRow(String label, String value) {
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
