import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../providers/vehicle_provider.dart';
import '../widgets/vehicle_card.dart';
import 'add_vehicle_page.dart';
import 'vehicle_detail_page.dart';

/// Clean modern Garage Page (DSS Section 9.4 & PRD Section 7.1)
class GaragePage extends ConsumerWidget {
  const GaragePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehicleProvider);
    final activeVehicle = ref.watch(activeVehicleProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('My Garage', style: AppTypography.heading1),
        elevation: 0,
        backgroundColor: AppColors.surfaceWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: 'Sinkronisasi dengan Cloud',
            onPressed: () => ref.read(vehicleProvider.notifier).loadVehicles(forceRemote: true),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryBlue, size: 28),
            tooltip: 'Tambah Kendaraan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddVehiclePage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: vehiclesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                  const SizedBox(height: AppSpacing.space16),
                  Text('Gagal memuat garasi', style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    err.toString(),
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.buttonBorderRadius,
                      ),
                    ),
                    onPressed: () => ref.read(vehicleProvider.notifier).loadVehicles(),
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    label: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.garage_rounded,
                          size: 54,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space24),
                      Text('Belum ada kendaraan', style: AppTypography.heading1),
                      const SizedBox(height: AppSpacing.space8),
                      Text(
                        'Tambahkan profil motor atau mobil Anda untuk memantau kesehatan dan riwayat berkendara.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          minimumSize: const Size(220, 50),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.buttonBorderRadius,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddVehiclePage()),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                        label: Text(
                          '+ Tambah Kendaraan',
                          style: AppTypography.heading3.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primaryBlue,
              onRefresh: () => ref.read(vehicleProvider.notifier).loadVehicles(forceRemote: true),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.space16),
                itemCount: vehicles.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.space12),
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  final isActive = vehicle.id == activeVehicle?.id;

                  return VehicleCard(
                    vehicle: vehicle,
                    isActive: isActive,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VehicleDetailPage(vehicle: vehicle),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: vehiclesAsync.value != null && vehiclesAsync.value!.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddVehiclePage()),
                );
              },
              backgroundColor: AppColors.primaryBlue,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Tambah Kendaraan', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}
