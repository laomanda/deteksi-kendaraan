import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/component_catalog.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../shared/providers/repository_providers.dart';

/// Screen displaying the paginated historical ledger of completed services (PRD Section 6 & DSS Section 9.3)
class ServiceHistoryScreen extends ConsumerStatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  ConsumerState<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends ConsumerState<ServiceHistoryScreen> {
  static const int _pageSize = 15;
  int _visibleCount = _pageSize;

  @override
  Widget build(BuildContext context) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    final repo = ref.watch(maintenanceRepositoryProvider);

    if (activeVehicle == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Riwayat Servis', style: AppTypography.heading2)),
        body: const Center(child: Text('Kendaraan belum dipilih')),
      );
    }

    final logs = repo.getServiceHistoryForVehicle(activeVehicle.id);
    final displayCount = math.min(_visibleCount, logs.length);
    final hasMore = logs.length > displayCount;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Riwayat Servis', style: AppTypography.heading2),
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: () async {
            ref.invalidate(maintenanceRepositoryProvider);
            await Future.delayed(const Duration(milliseconds: 200));
            setState(() {});
          },
          child: logs.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  itemCount: displayCount + (hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.space12),
                  itemBuilder: (context, index) {
                    if (index == displayCount) {
                      return _buildLoadMoreFooter(logs.length, displayCount);
                    }

                    final log = logs[index];
                    final meta = ComponentCatalog.findMetadata(
                      activeVehicle.vehicleType,
                      log.componentType,
                    );
                    final name = meta?.displayName ?? log.componentType;

                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.space16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: AppSpacing.cardBorderRadius,
                        border: AppSpacing.cardBorder,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(name, style: AppTypography.heading3),
                              Text(
                                DateFormatter.formatDate(log.serviceDate),
                                style: AppTypography.captionSubtle,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.space8),
                          Row(
                            children: [
                              Text(
                                'Odometer: ${DateFormatter.formatKm(log.serviceKm)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (log.cost > 0) ...[
                                const SizedBox(width: AppSpacing.space16),
                                Text(
                                  'Biaya: ${DateFormatter.formatCurrency(log.cost)}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.secondaryTeal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (log.notes.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.space8),
                            Text(
                              log.notes,
                              style: AppTypography.captionSubtle.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
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
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.space12),
            Text(
              'Belum Ada Catatan Servis',
              style: AppTypography.heading2,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'Catatan penggantian oli atau suku cadang akan tersimpan secara teratur di sini.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreFooter(int total, int showing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Text(
            'Menampilkan $showing dari $total catatan servis',
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
}
