import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../maintenance/presentation/pages/add_service_page.dart';
import '../../../maintenance/presentation/pages/maintenance_page.dart';

/// Cockpit Action Area for RideCare Dashboard
/// Premium automotive action deck using HugeIcons and cohesive brand hierarchy
class DashboardQuickActions extends ConsumerWidget {
  final VoidCallback? onStartRide;
  final VoidCallback? onNavigateToMaintenance;
  final VoidCallback? onNavigateToGarage;

  const DashboardQuickActions({
    super.key,
    this.onStartRide,
    this.onNavigateToMaintenance,
    this.onNavigateToGarage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Primary Action: Mulai Perjalanan (Midnight Navy Cockpit Button)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onStartRide,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedRoute01,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Mulai Perjalanan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Secondary Interactive Action Tiles
        Row(
          children: [
            // Catat Servis
            Expanded(
              child: _buildActionTile(
                context: context,
                icon: HugeIcons.strokeRoundedWrench01,
                title: 'Catat Servis',
                subtitle: 'Riwayat perawatan',
                onTap: () {
                  if (activeVehicle == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pilih kendaraan terlebih dahulu.'),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddServicePage(vehicle: activeVehicle),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            // Cek Kendaraan / Kondisi Komponen
            Expanded(
              child: _buildActionTile(
                context: context,
                icon: HugeIcons.strokeRoundedShield01,
                title: 'Cek Kendaraan',
                subtitle: 'Status komponen',
                onTap: () {
                  if (onNavigateToMaintenance != null) {
                    onNavigateToMaintenance!();
                  } else if (activeVehicle != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MaintenancePage(
                          initialVehicleId: activeVehicle.id,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required dynamic icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08102A43),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: icon,
                      color: AppColors.primaryNavy,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primaryNavy,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.secondarySteel,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
