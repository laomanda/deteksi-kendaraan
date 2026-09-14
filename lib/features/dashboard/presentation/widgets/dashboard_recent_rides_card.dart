import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Perjalanan Terakhir',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'Lihat Semua',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (recentRides.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.route_outlined,
                        size: 22,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Belum ada catatan perjalanan.',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Mulai catat rute dan jarak tempuh kendaraan Anda.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                    if (onStartRide != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: onStartRide,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF93C5FD)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: const Text(
                          'Mulai Sekarang',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
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
    final durationText = durationMin > 0 ? '$durationMin mnt' : '< 1 mnt';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.navigation_rounded,
              size: 16,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${DateFormatter.formatTime(start)} • $durationText',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormatter.formatKm(session.totalDistanceKm),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }
}
