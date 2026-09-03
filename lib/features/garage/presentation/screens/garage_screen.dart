import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/image_helper.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../data/models/vehicle_model.dart';
import '../controllers/active_vehicle_controller.dart';
import 'vehicle_form_screen.dart';

/// Layar 4: Garage Screen (DSS Section 9.4 & PRD Section 7.1)
class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    final allVehicles = ref.watch(vehicleListProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Garasi Kendaraan', style: AppTypography.heading2),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            tooltip: 'Tambah Kendaraan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: allVehicles.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 180,
                        child: SvgPicture.asset(
                          'assets/illustrations/empty_garage.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      Text('Garasi Masih Kosong', style: AppTypography.heading2),
                      const SizedBox(height: AppSpacing.space8),
                      Text(
                        'Tambahkan profil motor atau mobil Anda untuk memantau kesehatannya.',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          minimumSize: const Size(200, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.buttonBorderRadius,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, color: Colors.white),
                        label: const Text('Tambah Kendaraan'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.space16),
                itemCount: allVehicles.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.space12),
                itemBuilder: (context, index) {
                  final vehicle = allVehicles[index];
                  final isActive = vehicle.id == activeVehicle?.id;
                  return _buildVehicleCard(context, ref, vehicle, isActive);
                },
              ),
      ),
    );
  }

  Widget _buildVehicleCard(
    BuildContext context,
    WidgetRef ref,
    VehicleModel vehicle,
    bool isActive,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.cardBorderRadius,
        border: Border.all(
          color: isActive ? AppColors.primaryBlue : AppColors.borderSubtle,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Vehicle Photo or Fallback Icon
              Builder(
                builder: (context) {
                  final imageProvider = ImageHelper.getVehicleImageProvider(vehicle.photoPath);
                  return Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                      image: imageProvider != null
                          ? DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageProvider == null
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset(
                              vehicle.isMotorcycle
                                  ? 'assets/illustrations/motorcycle.svg'
                                  : 'assets/illustrations/car.svg',
                              fit: BoxFit.contain,
                            ),
                          )
                        : null,
                  );
                },
              ),
              const SizedBox(width: AppSpacing.space16),

              // Title and specs
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vehicle.displayName,
                            style: AppTypography.heading3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.12),
                              borderRadius: AppSpacing.chipBorderRadius,
                            ),
                            child: Text(
                              'AKTIF',
                              style: AppTypography.captionBadge.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tahun ${vehicle.year} • ${vehicle.isMotorcycle ? 'Sepeda Motor' : 'Mobil'}',
                      style: AppTypography.captionSubtle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatter.formatKm(vehicle.currentKilometer),
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          const Divider(),
          const SizedBox(height: AppSpacing.space8),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isActive)
                TextButton(
                  onPressed: () {
                    ref.read(activeVehicleProvider.notifier).setActiveVehicle(vehicle.id);
                  },
                  child: Text(
                    'Pilih Aktif',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Ubah Data',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VehicleFormScreen(vehicleToEdit: vehicle),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: AppColors.healthCritical,
                tooltip: 'Hapus Kendaraan',
                onPressed: () => _confirmDelete(context, ref, vehicle),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, VehicleModel vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardBorderRadius),
        title: Text('Hapus Kendaraan?', style: AppTypography.heading2),
        content: Text(
          'Seluruh data servis dan riwayat perjalanan ${vehicle.displayName} akan dihapus permanen.',
          style: AppTypography.bodySmall,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonBorderRadius,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.healthCritical,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonBorderRadius,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final vehicleRepo = ref.read(vehicleRepositoryProvider);
                    final maintenanceRepo = ref.read(maintenanceRepositoryProvider);
                    final rideRepo = ref.read(rideHistoryRepositoryProvider);

                    await maintenanceRepo.deleteItemsForVehicle(vehicle.id);
                    await rideRepo.deleteRidesForVehicle(vehicle.id);
                    await vehicleRepo.deleteVehicle(vehicle.id);
                    ref.read(activeVehicleProvider.notifier).refresh();
                  },
                  child: const Text('Hapus'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
