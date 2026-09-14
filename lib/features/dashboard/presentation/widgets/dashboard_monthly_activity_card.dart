import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/dashboard_providers.dart';

/// Card showing current month ride activity statistics
/// Refined Indonesian copywriting and premium metrics layout
class DashboardMonthlyActivityCard extends ConsumerWidget {
  const DashboardMonthlyActivityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(monthlyRideStatsProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 8),
              Text(
                'Aktivitas Bulan Ini',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Distance (Jarak Tempuh)
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.alt_route_rounded,
                  label: 'Jarak Tempuh',
                  value: stats.hasActivity ? stats.formattedDistance : '0 km',
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: const Color(0xFFF1F5F9),
                margin: const EdgeInsets.symmetric(horizontal: 6),
              ),
              // Trips (Perjalanan)
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.moped_rounded,
                  label: 'Perjalanan',
                  value: stats.hasActivity ? '${stats.tripCount} kali' : '0 kali',
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: const Color(0xFFF1F5F9),
                margin: const EdgeInsets.symmetric(horizontal: 6),
              ),
              // Ride Time (Waktu Berkendara)
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.timer_outlined,
                  label: 'Waktu Tempuh',
                  value: stats.hasActivity ? stats.formattedRideTime : '0 mnt',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
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
