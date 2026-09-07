import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../vehicle/data/models/vehicle_model.dart';
import '../../../vehicle/providers/vehicle_provider.dart';
import '../../data/models/maintenance_price_model.dart';
import '../../domain/health_calculation_service.dart';
import '../../providers/maintenance_intelligence_providers.dart';
import '../screens/service_history_screen.dart';
import 'add_service_page.dart';

enum MaintenanceViewFilter { all, needsAttention, good }

/// Halaman Utama Maintenance Intelligence (MaintenancePage)
class MaintenancePage extends ConsumerStatefulWidget {
  final String? initialVehicleId;

  const MaintenancePage({super.key, this.initialVehicleId});

  @override
  ConsumerState<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends ConsumerState<MaintenancePage> {
  MaintenanceViewFilter _filter = MaintenanceViewFilter.all;
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.initialVehicleId;
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OVERDUE':
        return Colors.redAccent;
      case 'DUE SOON':
      case 'DUE_SOON':
        return Colors.orangeAccent;
      case 'GOOD':
      default:
        return AppColors.successGreen;
    }
  }

  void _showComponentDetail(
    BuildContext context,
    VehicleMaintenanceHealth itemHealth,
    VehicleModel vehicle,
  ) {
    final statusColor = _getStatusColor(itemHealth.status);
    final numberFormat = NumberFormat.decimalPattern('id_ID');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemHealth.item.itemName ?? itemHealth.item.maintenanceId,
                          style: AppTypography.heading2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kategori: ${(itemHealth.item.itemCategory ?? 'General').toUpperCase()}',
                          style: AppTypography.captionBadge.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      itemHealth.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Metrics Grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: AppSpacing.cardBorderRadius,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildMetricRow(
                      label: 'Current Health',
                      value: '${itemHealth.healthPercentage.toStringAsFixed(0)}%',
                      valueColor: statusColor,
                      isBold: true,
                    ),
                    const Divider(height: 16),
                    _buildMetricRow(
                      label: 'Remaining Odometer',
                      value: '${numberFormat.format(itemHealth.remainingKm)} KM',
                      valueColor: statusColor,
                      isBold: true,
                    ),
                    const Divider(height: 16),
                    _buildMetricRow(
                      label: 'Current Odometer',
                      value: '${numberFormat.format(vehicle.currentOdometer)} KM',
                    ),
                    const Divider(height: 16),
                    _buildMetricRow(
                      label: 'Last Service Odometer',
                      value: '${numberFormat.format(itemHealth.item.lastServiceOdometer)} KM',
                    ),
                    const Divider(height: 16),
                    _buildMetricRow(
                      label: 'Next Recommended Service',
                      value: '${numberFormat.format(itemHealth.nextServiceOdometer)} KM',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Estimated Cost Section
              Text('ESTIMASI BIAYA PERAWATAN', style: AppTypography.captionBadge),
              const SizedBox(height: 8),
              if (itemHealth.priceEstimate != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.05),
                    borderRadius: AppSpacing.cardBorderRadius,
                    border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Estimasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            itemHealth.priceEstimate!.formattedTotalRange,
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Estimasi Sparepart', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                          Text(itemHealth.priceEstimate!.formattedPartRange, style: AppTypography.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Estimasi Jasa Bengkel', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                          Text(itemHealth.priceEstimate!.formattedLaborRange, style: AppTypography.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Price Disclaimer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          MaintenancePriceModel.priceDisclaimer,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber.shade900,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  'Estimasi harga belum tersedia untuk komponen ini.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 24),

              // Button Catat Servis
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddServicePage(
                          vehicle: vehicle,
                          preselectedItem: itemHealth.item,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.build_rounded, size: 18),
                  label: const Text('Catat Servis Komponen Ini'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonBorderRadius,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehicleListProvider);
    final activeVehicleId = ref.watch(activeVehicleProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Maintenance Intelligence'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
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
        child: vehiclesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.garage_rounded, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: AppSpacing.space16),
                    Text('Belum ada kendaraan di Garage', style: AppTypography.heading2),
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      'Tambahkan kendaraan terlebih dahulu untuk memantau kesehatan servis.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              );
            }

            // Pilih kendaraan yang sesuai
            VehicleModel selectedVehicle;
            final targetId = _selectedVehicleId ?? activeVehicleId;
            final matched = vehicles.where((v) => v.id == targetId).firstOrNull;
            selectedVehicle = matched ?? vehicles.first;

            return _buildMaintenanceContent(selectedVehicle, vehicles);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final vehicles = vehiclesAsync.asData?.value ?? [];
          if (vehicles.isNotEmpty) {
            final targetId = _selectedVehicleId ?? activeVehicleId;
            final v = vehicles.where((it) => it.id == targetId).firstOrNull ?? vehicles.first;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddServicePage(vehicle: v)),
            );
          }
        },
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('+ Catat Servis'),
      ),
    );
  }

  Widget _buildMaintenanceContent(VehicleModel vehicle, List<VehicleModel> allVehicles) {
    final healthSummaryAsync = ref.watch(maintenanceHealthProvider(vehicle.id));

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(vehicleMaintenanceProvider(vehicle.id).notifier).refresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.space16),
        children: [
          // 1. Vehicle Selector Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: AppSpacing.cardBorderRadius,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(
                  vehicle.isMotorcycle ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
                  color: AppColors.primaryBlue,
                  size: 26,
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KENDARAAN AKTIF', style: AppTypography.captionBadge),
                      Text(vehicle.displayName, style: AppTypography.heading3),
                    ],
                  ),
                ),
                if (allVehicles.length > 1)
                  DropdownButton<String>(
                    value: vehicle.id,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryBlue),
                    items: allVehicles.map((v) {
                      return DropdownMenuItem<String>(
                        value: v.id,
                        child: Text('${v.brand} ${v.model}'),
                      );
                    }).toList(),
                    onChanged: (newId) {
                      if (newId != null) {
                        setState(() => _selectedVehicleId = newId);
                        ref.read(activeVehicleProvider.notifier).setActiveVehicle(newId);
                      }
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space16),

          // 2. Overall Health Summary Card
          healthSummaryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (summary) {
              final score = summary.overallScore.round();
              final Color scoreColor = score >= 80
                  ? AppColors.successGreen
                  : (score >= 50 ? Colors.orangeAccent : Colors.redAccent);

              return Container(
                padding: const EdgeInsets.all(AppSpacing.space24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: AppSpacing.cardBorderRadius,
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Circular Health Indicator
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: (score / 100).clamp(0.0, 1.0),
                                strokeWidth: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                              ),
                              Center(
                                child: Text(
                                  '$score%',
                                  style: AppTypography.heading2.copyWith(
                                    color: scoreColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Overall Health', style: AppTypography.heading2),
                              const SizedBox(height: 4),
                              Text(
                                score >= 80
                                    ? 'Kendaraan dalam kondisi prima 👍'
                                    : (score >= 50
                                        ? 'Perhatikan komponen yang mendekati servis ⚠️'
                                        : 'Segera lakukan servis komponen kritis 🚨'),
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Odometer: ${NumberFormat.decimalPattern('id_ID').format(vehicle.currentOdometer)} KM',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Summary status count chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatusChip('GOOD', summary.goodCount, AppColors.successGreen),
                        _buildStatusChip('DUE SOON', summary.dueSoonCount, Colors.orangeAccent),
                        _buildStatusChip('OVERDUE', summary.overdueCount, Colors.redAccent),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.space16),

          // 3. Filter Chips
          Row(
            children: [
              _buildFilterChip('Semua Komponen', MaintenanceViewFilter.all),
              const SizedBox(width: 8),
              _buildFilterChip('Perlu Servis', MaintenanceViewFilter.needsAttention),
              const SizedBox(width: 8),
              _buildFilterChip('Kondisi Baik', MaintenanceViewFilter.good),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),

          // 4. Maintenance Items List
          healthSummaryAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (summary) {
              final filtered = summary.healthItems.where((item) {
                switch (_filter) {
                  case MaintenanceViewFilter.all:
                    return true;
                  case MaintenanceViewFilter.needsAttention:
                    return item.isDueSoon || item.isOverdue;
                  case MaintenanceViewFilter.good:
                    return item.isGood;
                }
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Tidak ada komponen pada filter ini.',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final itemHealth = filtered[index];
                  return _buildMaintenanceCard(itemHealth, vehicle);
                },
              );
            },
          ),
          const SizedBox(height: 80), // Padding untuk FloatingActionButton
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, MaintenanceViewFilter filter) {
    final isSelected = _filter == filter;
    return InkWell(
      onTap: () => setState(() => _filter = filter),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceCard(VehicleMaintenanceHealth itemHealth, VehicleModel vehicle) {
    final statusColor = _getStatusColor(itemHealth.status);
    final numberFormat = NumberFormat.decimalPattern('id_ID');
    final healthScore = itemHealth.healthPercentage.round();

    return InkWell(
      onTap: () => _showComponentDetail(context, itemHealth, vehicle),
      borderRadius: AppSpacing.cardBorderRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppSpacing.cardBorderRadius,
          border: Border.all(
            color: itemHealth.isOverdue
                ? Colors.redAccent.withValues(alpha: 0.5)
                : (itemHealth.isDueSoon
                    ? Colors.orangeAccent.withValues(alpha: 0.4)
                    : AppColors.borderSubtle),
            width: itemHealth.isDueSoon || itemHealth.isOverdue ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row Header: Nama Komponen & Badge Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    itemHealth.item.itemName ?? itemHealth.item.maintenanceId,
                    style: AppTypography.heading3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    itemHealth.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress Bar Visual
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (itemHealth.healthPercentage / 100.0).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 8),

            // Info Teks: % remaining & KM remaining
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$healthScore% remaining',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${numberFormat.format(itemHealth.remainingKm)} KM remaining',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Estimasi Biaya ringkas jika ada
            if (itemHealth.priceEstimate != null && (itemHealth.isDueSoon || itemHealth.isOverdue)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.price_change_outlined, size: 14, color: AppColors.primaryBlue),
                    const SizedBox(width: 4),
                    Text(
                      'Estimasi: ${itemHealth.priceEstimate!.formattedTotalRange}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
