import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../garage/data/models/vehicle_model.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../maintenance/presentation/controllers/maintenance_status_controller.dart';

/// VehicleHeaderCard (DSS Section 8.1 & Table 10)
class VehicleHeaderCard extends ConsumerWidget {
  const VehicleHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    final allVehicles = ref.watch(vehicleListProvider);
    final maintenanceStateAsync = ref.watch(maintenanceStatusProvider);

    if (activeVehicle == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space24),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppSpacing.cardBorderRadius,
          border: AppSpacing.cardBorder,
        ),
        child: Center(
          child: Text(
            'Belum ada kendaraan terdaftar',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final double aggregateScore = maintenanceStateAsync.value?.aggregateHealthScore ?? 100.0;
    final String? warningMsg = maintenanceStateAsync.value?.warningMessage;
    final statusColor = AppColors.getHealthColor(aggregateScore / 100.0);
    final statusLabel = AppColors.getHealthStatusLabel(aggregateScore / 100.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.cardBorderRadius,
        border: Border.all(
          color: warningMsg != null ? AppColors.healthWarning : AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Vehicle Identity Header & Quick Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: SvgPicture.asset(
                        activeVehicle.isMotorcycle
                            ? 'assets/illustrations/motorcycle.svg'
                            : 'assets/illustrations/car.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Expanded(
                      child: Text(
                        activeVehicle.displayName,
                        style: AppTypography.heading2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                tooltip: 'Perbarui Odometer',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.minTouchTarget,
                  minHeight: AppSpacing.minTouchTarget,
                ),
                onPressed: () => _showQuickKmUpdateDialog(context, ref, activeVehicle),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),

          // Row 2: Odometer Readout
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                DateFormatter.formatKm(activeVehicle.currentKilometer, includeUnit: false),
                style: AppTypography.displayLarge,
              ),
              const SizedBox(width: AppSpacing.space4),
              Text(
                'km',
                style: AppTypography.heading3.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),

          // Row 3: Aggregated Health Score Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space8,
                  vertical: AppSpacing.space4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.chipBorderRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space4),
                    Text(
                      '${aggregateScore.toInt()}% - $statusLabel',
                      style: AppTypography.captionBadge.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (warningMsg != null) ...[
                const SizedBox(width: AppSpacing.space8),
                Expanded(
                  child: Text(
                    warningMsg,
                    style: AppTypography.captionSubtle.copyWith(
                      color: AppColors.healthWarning,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),

          // Multi-vehicle indicator dots if user has > 1 vehicle
          if (allVehicles.length > 1) ...[
            const SizedBox(height: AppSpacing.space12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: allVehicles.map((v) {
                final isActive = v.id == activeVehicle.id;
                return GestureDetector(
                  onTap: () => ref.read(activeVehicleProvider.notifier).setActiveVehicle(v.id),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primaryBlue : AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showQuickKmUpdateDialog(
    BuildContext context,
    WidgetRef ref,
    VehicleModel vehicle,
  ) {
    final controller = TextEditingController(
      text: vehicle.currentKilometer.toInt().toString(),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardBorderRadius),
          title: Text('Perbarui Odometer', style: AppTypography.heading2),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masukkan total kilometer terkini kendaraan Anda:',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.space12),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    suffixText: 'km',
                    hintText: 'Contoh: 15200',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Kilometer wajib diisi';
                    }
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null) {
                      return 'Harus berupa angka valid';
                    }
                    if (parsed < vehicle.currentKilometer) {
                      return 'Tidak boleh kurang dari ${vehicle.currentKilometer.toInt()} km';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                minimumSize: const Size(100, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.buttonBorderRadius,
                ),
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final newKm = double.parse(controller.text.trim());
                  await ref.read(activeVehicleProvider.notifier).updateOdometer(newKm);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
