import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../controllers/maintenance_status_controller.dart';
import '../widgets/maintenance_card.dart';
import 'service_history_screen.dart';

enum MaintenanceFilter {
  all,
  needsAttention,
  optimal,
}

/// Layar 3: Maintenance Screen (DSS Section 9.3 & PRD Section 6)
/// Menampilkan ringkasan status kesehatan suku cadang kendaraan dengan DynamicFillIcon
class MaintenanceScreen extends ConsumerStatefulWidget {
  final String? initialVehicleId;

  const MaintenanceScreen({
    super.key,
    this.initialVehicleId,
  });

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  MaintenanceFilter _filter = MaintenanceFilter.all;

  @override
  void initState() {
    super.initState();
    if (widget.initialVehicleId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeVehicleProvider.notifier).setActiveVehicle(widget.initialVehicleId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    final maintenanceAsync = ref.watch(maintenanceStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Kesehatan Kendaraan',
          style: AppTypography.heading2.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 24),
            color: AppColors.textPrimary,
            tooltip: 'Riwayat Servis',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServiceHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Filter Chips Row
            Container(
              color: AppColors.surfaceWhite,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
                vertical: AppSpacing.space12,
              ),
              child: Row(
                children: [
                  _buildFilterChip(
                    title: 'Semua Komponen',
                    filter: MaintenanceFilter.all,
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  _buildFilterChip(
                    title: 'Perlu Perhatian',
                    filter: MaintenanceFilter.needsAttention,
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  _buildFilterChip(
                    title: 'Optimal',
                    filter: MaintenanceFilter.optimal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space8),

            // 2. Component List
            Expanded(
              child: maintenanceAsync.when(
                data: (state) {
                  if (activeVehicle == null || state.results.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(maintenanceStatusProvider);
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: Center(
                              child: Text(
                                'Belum ada komponen yang dipantau.',
                                style: AppTypography.bodySmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final filtered = state.results.where((res) {
                    switch (_filter) {
                      case MaintenanceFilter.all:
                        return true;
                      case MaintenanceFilter.needsAttention:
                        return res.isWarning || res.isCritical;
                      case MaintenanceFilter.optimal:
                        return res.isOptimal || res.isModerate;
                    }
                  }).toList();

                  if (filtered.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(maintenanceStatusProvider);
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.space24),
                                child: Text(
                                  _filter == MaintenanceFilter.needsAttention
                                      ? 'Luar biasa! Tidak ada komponen yang membutuhkan tindakan mendesak.'
                                      : 'Tidak ada data untuk filter yang dipilih.',
                                  style: AppTypography.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(maintenanceStatusProvider);
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space16,
                        vertical: AppSpacing.space8,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final result = filtered[index];
                        return MaintenanceCard(
                          result: result,
                          vehicle: activeVehicle,
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (err, _) => Center(
                  child: Text('Error: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String title,
    required MaintenanceFilter filter,
  }) {
    final isSelected = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.borderSubtle.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
