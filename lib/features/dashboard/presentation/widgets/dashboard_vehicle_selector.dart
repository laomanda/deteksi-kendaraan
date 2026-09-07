import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../vehicle/data/models/vehicle_model.dart';
import '../../../vehicle/presentation/pages/add_vehicle_page.dart';

/// Interactive Vehicle Selector widget for Dashboard
class DashboardVehicleSelector extends ConsumerWidget {
  const DashboardVehicleSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    final allVehicles = ref.watch(vehicleListProvider);

    if (activeVehicle == null) {
      return const SizedBox.shrink();
    }

    final hasMultiple = allVehicles.length > 1;

    return InkWell(
      onTap: hasMultiple
          ? () => _showVehiclePickerModal(context, ref, activeVehicle, allVehicles)
          : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              activeVehicle.isMotorcycle
                  ? Icons.two_wheeler_rounded
                  : Icons.directions_car_rounded,
              size: 18,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                activeVehicle.displayName,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasMultiple) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_drop_down_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showVehiclePickerModal(
    BuildContext context,
    WidgetRef ref,
    VehicleModel activeVehicle,
    List<VehicleModel> vehicles,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.modalTopRadius,
      ),
      backgroundColor: AppColors.surfaceWhite,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space24,
              vertical: AppSpacing.space16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: AppSpacing.space16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pilih Kendaraan Aktif', style: AppTypography.heading2),
                    Text(
                      '${vehicles.length} Kendaraan',
                      style: AppTypography.captionSubtle,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vehicles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final v = vehicles[index];
                    final isSelected = v.id == activeVehicle.id;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.cardBorderRadius,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : AppColors.borderSubtle,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      tileColor: isSelected
                          ? AppColors.primaryBlue.withValues(alpha: 0.05)
                          : AppColors.surfaceWhite,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: v.isMotorcycle
                              ? AppColors.primaryBlue.withValues(alpha: 0.1)
                              : AppColors.secondaryTeal.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          v.isMotorcycle
                              ? Icons.two_wheeler_rounded
                              : Icons.directions_car_rounded,
                          color: v.isMotorcycle
                              ? AppColors.primaryBlue
                              : AppColors.secondaryTeal,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        v.displayName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${v.year} • ${DateFormatter.formatKm(v.currentKilometer)}',
                        style: AppTypography.captionSubtle,
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.primaryBlue)
                          : null,
                      onTap: () {
                        ref
                            .read(activeVehicleProvider.notifier)
                            .setActiveVehicle(v.id);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.space16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.buttonBorderRadius,
                      ),
                      side: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah Kendaraan Lain'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddVehiclePage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
