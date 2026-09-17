import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06102A43),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: activeVehicle.isMotorcycle
                  ? HugeIcons.strokeRoundedMotorbike01
                  : HugeIcons.strokeRoundedCar01,
              size: 16,
              color: AppColors.primaryNavy,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                activeVehicle.displayName,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.primaryNavy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasMultiple) ...[
              const SizedBox(width: 2),
              const Icon(
                Icons.arrow_drop_down_rounded,
                size: 18,
                color: AppColors.secondarySteel,
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.modalTopRadius,
      ),
      backgroundColor: AppColors.surfaceWhite,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
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
                    Text(
                      'Pilih Kendaraan Aktif',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    Text(
                      '${vehicles.length} Kendaraan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: vehicles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final v = vehicles[index];
                      final isSelected = v.id == activeVehicle.id;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primaryNavy
                                : AppColors.borderSubtle,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        tileColor: isSelected
                            ? AppColors.primaryNavy.withValues(alpha: 0.04)
                            : AppColors.surfaceWhite,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: HugeIcon(
                            icon: v.isMotorcycle
                                ? HugeIcons.strokeRoundedMotorbike01
                                : HugeIcons.strokeRoundedCar01,
                            color: AppColors.primaryNavy,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          v.displayName,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.primaryNavy,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${v.year} • ${DateFormatter.formatKm(v.currentKilometer, includeUnit: false)} KM',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.secondarySteel,
                            fontSize: 11,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.safeGreen,
                                size: 20,
                              )
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
                ),
                const SizedBox(height: AppSpacing.space16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primaryNavy),
                    label: Text(
                      'Tambah Kendaraan Lain',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
