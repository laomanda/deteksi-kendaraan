import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../providers/dashboard_providers.dart';

/// Card showing current month ride activity statistics
class DashboardMonthlyActivityCard extends ConsumerWidget {
  const DashboardMonthlyActivityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(monthlyRideStatsProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.cardBorderRadius,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'THIS MONTH ACTIVITY',
                style: AppTypography.captionBadge.copyWith(
                  color: AppColors.primaryBlue,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          Row(
            children: [
              // Distance
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.alt_route_rounded,
                  label: 'Distance',
                  value: stats.hasActivity ? stats.formattedDistance : '0 KM',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.borderSubtle,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              // Trips
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.two_wheeler_rounded,
                  label: 'Trips',
                  value: stats.hasActivity ? '${stats.tripCount}' : '0',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.borderSubtle,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              // Ride Time
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.timer_outlined,
                  label: 'Ride Time',
                  value: stats.hasActivity ? stats.formattedRideTime : '0 min',
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
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.captionSubtle),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.heading3.copyWith(fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
