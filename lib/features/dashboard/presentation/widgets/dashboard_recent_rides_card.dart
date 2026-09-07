import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../ride_tracking/data/models/ride_session_model.dart';
import '../../../ride_tracking/presentation/screens/ride_history_screen.dart';
import '../providers/dashboard_providers.dart';

/// Card presenting up to 3 most recent rides with clean compact layout
class DashboardRecentRidesCard extends ConsumerWidget {
  final VoidCallback? onStartRide;

  const DashboardRecentRidesCard({
    super.key,
    this.onStartRide,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentRides = ref.watch(recentRidesProvider);

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
          // Header Row with CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RECENT RIDES',
                    style: AppTypography.captionBadge.copyWith(
                      color: AppColors.primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RideHistoryScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'View Ride History',
                      style: AppTypography.captionBadge.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space12),

          if (recentRides.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.route_outlined,
                      size: 32,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Belum ada perjalanan.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (onStartRide != null) ...[
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: onStartRide,
                        child: const Text('Mulai Perjalanan Sekarang'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentRides.length,
              separatorBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 6.0),
                child: Divider(height: 1, color: AppColors.borderSubtle),
              ),
              itemBuilder: (_, index) {
                final session = recentRides[index];
                return _buildRideItem(session);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRideItem(RideSessionModel session) {
    final now = DateTime.now();
    final start = session.startTime;
    final isToday = start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
    final isYesterday = start.year == now.year &&
        start.month == now.month &&
        start.day == now.day - 1;

    String dateLabel;
    if (isToday) {
      dateLabel = 'Hari ini';
    } else if (isYesterday) {
      dateLabel = 'Kemarin';
    } else {
      dateLabel = DateFormatter.formatDate(start);
    }

    final durationMin = (session.durationSeconds / 60).round();
    final durationText = durationMin > 0 ? '$durationMin min' : '< 1 min';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.directions_bike_rounded,
              size: 18,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${DateFormatter.formatTime(start)} - ${DateFormatter.formatTime(session.endTime)}',
                  style: AppTypography.captionSubtle.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormatter.formatKm(session.totalDistanceKm),
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
              Text(
                durationText,
                style: AppTypography.captionSubtle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
