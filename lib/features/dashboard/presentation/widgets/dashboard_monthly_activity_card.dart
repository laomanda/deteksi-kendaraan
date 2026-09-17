import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/dashboard_providers.dart';

/// Card showing current month ride activity statistics
/// Features a humanized empty state when 0 km / no trips exist
class DashboardMonthlyActivityCard extends ConsumerWidget {
  final VoidCallback? onStartRide;

  const DashboardMonthlyActivityCard({
    super.key,
    this.onStartRide,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(monthlyRideStatsProvider);

    if (!stats.hasActivity) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06102A43),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedRoute01,
                  color: AppColors.secondarySteel,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belum Ada Perjalanan',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.primaryNavy,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mulai perjalanan pertama untuk melihat statistik kendaraan.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.secondarySteel,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06102A43),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedAnalytics01,
                size: 18,
                color: AppColors.primaryNavy,
              ),
              const SizedBox(width: 8),
              Text(
                'Aktivitas Bulan Ini',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primaryNavy,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Jarak Tempuh
              Expanded(
                child: _buildMetricItem(
                  icon: HugeIcons.strokeRoundedRoute01,
                  label: 'Jarak Tempuh',
                  value: stats.formattedDistance.toUpperCase(),
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: const Color(0xFFF1EFE9),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              // Perjalanan
              Expanded(
                child: _buildMetricItem(
                  icon: HugeIcons.strokeRoundedMotorbike01,
                  label: 'Perjalanan',
                  value: '${stats.tripCount} kali',
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: const Color(0xFFF1EFE9),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              // Waktu Tempuh
              Expanded(
                child: _buildMetricItem(
                  icon: HugeIcons.strokeRoundedClock01,
                  label: 'Waktu Tempuh',
                  value: stats.formattedRideTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required dynamic icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HugeIcon(
              icon: icon,
              size: 13,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.primaryNavy,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
