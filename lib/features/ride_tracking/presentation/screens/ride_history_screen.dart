import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../data/models/ride_session_model.dart';
import '../controllers/ride_tracking_controller.dart';
import '../widgets/ride_share_canvas.dart';

enum _HistoryPeriodFilter {
  all('Semua'),
  thisMonth('Bulan Ini'),
  last7Days('7 Hari Terakhir');

  final String label;
  const _HistoryPeriodFilter(this.label);
}

/// Screen displaying the paginated history ledger of rides with period filters (PRD Section 11)
class RideHistoryScreen extends ConsumerStatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  ConsumerState<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends ConsumerState<RideHistoryScreen> {
  static const int _pageSize = 10;
  int _visibleCount = _pageSize;
  _HistoryPeriodFilter _selectedFilter = _HistoryPeriodFilter.all;

  @override
  Widget build(BuildContext context) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    final allRides = ref.watch(rideHistoryListProvider);

    if (activeVehicle == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Riwayat Perjalanan', style: AppTypography.heading2),
        ),
        body: const Center(child: Text('Kendaraan belum dipilih')),
      );
    }

    // Filter rides based on selected period
    final now = DateTime.now();
    final filteredRides = allRides.where((ride) {
      switch (_selectedFilter) {
        case _HistoryPeriodFilter.all:
          return true;
        case _HistoryPeriodFilter.thisMonth:
          return ride.startTime.year == now.year &&
              ride.startTime.month == now.month;
        case _HistoryPeriodFilter.last7Days:
          final sevenDaysAgo = now.subtract(const Duration(days: 7));
          return ride.startTime.isAfter(sevenDaysAgo);
      }
    }).toList();

    final totalRides = filteredRides.length;
    final totalDistance = filteredRides.fold<double>(
      0.0,
      (sum, item) => sum + item.totalDistanceKm,
    );

    final displayCount = math.min(_visibleCount, filteredRides.length);
    final hasMore = filteredRides.length > displayCount;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Riwayat Perjalanan', style: AppTypography.heading2),
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: () async {
            ref.invalidate(rideHistoryListProvider);
            ref.invalidate(recentRideProvider);
            await Future.delayed(const Duration(milliseconds: 250));
          },
          child: filteredRides.isEmpty && allRides.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  itemCount: 2 + displayCount + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Item 0: Summary Stats Card
                    if (index == 0) {
                      return _buildStatsHeader(totalRides, totalDistance);
                    }

                    // Item 1: Period Filter Chips
                    if (index == 1) {
                      return _buildFilterBar();
                    }

                    // Bottom pagination item
                    if (index == 2 + displayCount) {
                      return _buildLoadMoreFooter(filteredRides.length, displayCount);
                    }

                    // Ride Items
                    final rideIndex = index - 2;
                    final session = filteredRides[rideIndex];
                    return _buildRideCard(context, session, activeVehicle);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              'Belum Ada Riwayat Perjalanan',
              style: AppTypography.heading2,
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              'Semua perjalanan yang telah Anda rekam dan selesaikan akan otomatis tersimpan rapi di sini.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(int count, double totalKm) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space12),
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.cardBorderRadius,
        border: AppSpacing.cardBorder,
        boxShadow: AppSpacing.floatingShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/share_card/badge_achievement.svg',
                width: 28,
                height: 28,
              ),
              const SizedBox(width: AppSpacing.space12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL TRIP',
                    style: AppTypography.captionSubtle.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count',
                    style: AppTypography.heading1.copyWith(
                      color: AppColors.primaryBlue,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 1,
            height: 36,
            color: AppColors.borderSubtle,
          ),
          Row(
            children: [
              SvgPicture.asset(
                'assets/share_card/badge_distance.svg',
                width: 28,
                height: 28,
              ),
              const SizedBox(width: AppSpacing.space12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL JARAK',
                    style: AppTypography.captionSubtle.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${totalKm.toStringAsFixed(1)} km',
                    style: AppTypography.heading1.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _HistoryPeriodFilter.values.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(filter.label),
                selected: isSelected,
                selectedColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                backgroundColor: AppColors.surfaceWhite,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryBlue : AppColors.borderSubtle,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedFilter = filter;
                      _visibleCount = _pageSize; // Reset page size on filter change
                    });
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRideCard(
    BuildContext context,
    RideSessionModel session,
    dynamic activeVehicle,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space12),
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.cardBorderRadius,
        border: AppSpacing.cardBorder,
        boxShadow: AppSpacing.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date & Time + Delete Option
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    (activeVehicle.isMotorcycle as bool)
                        ? 'assets/share_card/badge_motorcycle.svg'
                        : 'assets/share_card/badge_vehicle.svg',
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormatter.formatDate(session.startTime),
                    style: AppTypography.captionBadge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '•  ${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}',
                    style: AppTypography.captionSubtle,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                tooltip: 'Hapus Perjalanan',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  _promptDeleteRide(context, session.id);
                },
              ),
            ],
          ),
          const Divider(height: AppSpacing.space16),

          // Distance, Duration, and Speed Readouts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JARAK',
                    style: AppTypography.captionSubtle.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${session.totalDistanceKm.toStringAsFixed(2)} km',
                    style: AppTypography.heading2.copyWith(
                      color: AppColors.primaryBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'DURASI',
                    style: AppTypography.captionSubtle.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatDuration(session.durationSeconds),
                    style: AppTypography.heading3.copyWith(fontSize: 15),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RATA-RATA',
                    style: AppTypography.captionSubtle.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${session.averageSpeedKmh.toStringAsFixed(1)} km/j',
                    style: AppTypography.heading3.copyWith(fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),

          // Action: View / Share Trip Card
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(
                  color: AppColors.borderSubtle,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.chipBorderRadius,
                ),
              ),
              onPressed: () {
                RideShareCanvas.showModal(
                  context,
                  session: session,
                  vehicleName: activeVehicle.displayName as String,
                  isMotorcycle: activeVehicle.isMotorcycle as bool,
                );
              },
              icon: const Icon(Icons.share_outlined, size: 16),
              label: Text(
                'Lihat Peta & Bagikan',
                style: AppTypography.captionBadge.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreFooter(int total, int showing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Text(
            'Menampilkan $showing dari $total perjalanan',
            style: AppTypography.captionSubtle.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(color: AppColors.primaryBlue, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              setState(() {
                _visibleCount += _pageSize;
              });
            },
            icon: const Icon(Icons.expand_more_rounded, size: 18),
            label: const Text('Muat Lebih Banyak'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _promptDeleteRide(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.cardBorderRadius,
        ),
        title: Text('Hapus Perjalanan?', style: AppTypography.heading2),
        content: Text(
          'Catatan ini akan dihapus permanen dari riwayat.',
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
                    await ref
                        .read(rideHistoryListProvider.notifier)
                        .deleteRide(id);
                    ref.invalidate(recentRideProvider);
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
