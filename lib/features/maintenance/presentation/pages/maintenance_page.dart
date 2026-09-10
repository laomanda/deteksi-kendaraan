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
import '../widgets/maintenance_cost_forecast_card.dart';
import '../widgets/upcoming_maintenance_card.dart';
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

    String statusText;
    String reasonText;
    if (itemHealth.isOverdue) {
      statusText = 'Lewat Jadwal';
      reasonText = 'Sudah melewati batas pemakaian yang disarankan.';
    } else if (itemHealth.isDueSoon) {
      statusText = 'Segera Diganti';
      reasonText =
          'Sudah mendekati batas pemakaian (${numberFormat.format(itemHealth.remainingKm)} KM lagi).';
    } else {
      statusText = 'Kondisi Baik';
      reasonText = 'Masih dalam batas pemakaian yang aman.';
    }

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
          child: SingleChildScrollView(
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
                            itemHealth.item.itemCategory ?? 'Komponen Perawatan',
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
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Penjelasan Singkat (Kenapa?)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        itemHealth.isOverdue
                            ? Icons.error_outline_rounded
                            : (itemHealth.isDueSoon
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline_rounded),
                        color: statusColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          reasonText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Estimated Cost Section
                Text('PERKIRAAN BIAYA PERAWATAN', style: AppTypography.captionBadge),
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
                            const Text('Total Perkiraan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                            Text('Perkiraan Sparepart', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                            Text(itemHealth.priceEstimate!.formattedPartRange, style: AppTypography.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Perkiraan Jasa Bengkel', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                            Text(itemHealth.priceEstimate!.formattedLaborRange, style: AppTypography.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    MaintenancePriceModel.priceDisclaimer,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Perkiraan biaya belum tersedia untuk komponen ini.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 20),

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
                const SizedBox(height: 12),

                // Collapsible Technical Information
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Detail Teknis & Interval',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bgLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          children: [
                            _buildMetricRow(
                              label: 'Jarak Tempuh Saat Ini',
                              value: '${numberFormat.format(vehicle.currentOdometer)} KM',
                            ),
                            const Divider(height: 14),
                            _buildMetricRow(
                              label: 'Servis Terakhir pada',
                              value: '${numberFormat.format(itemHealth.item.lastServiceOdometer)} KM',
                            ),
                            const Divider(height: 14),
                            _buildMetricRow(
                              label: 'Jadwal Servis Berikutnya',
                              value: '${numberFormat.format(itemHealth.nextServiceOdometer)} KM',
                            ),
                            const Divider(height: 14),
                            _buildMetricRow(
                              label: 'Sisa Jarak Rekomendasi',
                              value: '${numberFormat.format(itemHealth.remainingKm)} KM',
                              valueColor: statusColor,
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
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
        title: const Text('Perawatan Kendaraan'),
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

          // 2. Human-First Status Summary Card
          healthSummaryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (summary) {
              final numberFormat = NumberFormat.decimalPattern('id_ID');

              // Status visual yang jelas
              Color statusColor;
              String statusTitle;
              String statusDesc;
              IconData statusIcon;

              if (summary.overdueCount > 0) {
                statusColor = AppColors.healthCritical;
                statusTitle = 'Perlu Servis Segera';
                statusDesc = '${summary.overdueCount} komponen sudah melewati batas pemakaian.';
                statusIcon = Icons.error_rounded;
              } else if (summary.dueSoonCount > 0) {
                statusColor = AppColors.healthWarning;
                statusTitle = 'Perlu Perhatian';
                statusDesc = '${summary.dueSoonCount} komponen mendekati jadwal servis.';
                statusIcon = Icons.warning_amber_rounded;
              } else {
                statusColor = AppColors.healthOptimal;
                statusTitle = 'Kendaraan Aman';
                statusDesc = 'Semua komponen masih dalam kondisi prima.';
                statusIcon = Icons.check_circle_rounded;
              }

              return Container(
                padding: const EdgeInsets.all(AppSpacing.space16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: AppSpacing.cardBorderRadius,
                  border: Border.all(
                    color: summary.overdueCount > 0
                        ? AppColors.healthCritical.withValues(alpha: 0.4)
                        : (summary.dueSoonCount > 0
                            ? AppColors.healthWarning.withValues(alpha: 0.4)
                            : AppColors.borderSubtle),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Banner
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(statusIcon, color: statusColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusTitle,
                                style: AppTypography.heading2.copyWith(color: statusColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                statusDesc,
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Total Jarak Kendaraan & Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TOTAL JARAK KENDARAAN', style: AppTypography.captionBadge),
                            const SizedBox(height: 2),
                            Text(
                              '${numberFormat.format(vehicle.currentOdometer)} KM',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _buildStatusChip('Aman', summary.goodCount, AppColors.successGreen),
                            const SizedBox(width: 6),
                            if (summary.dueSoonCount > 0) ...[
                              _buildStatusChip('Perhatian', summary.dueSoonCount, Colors.orangeAccent),
                              const SizedBox(width: 6),
                            ],
                            if (summary.overdueCount > 0)
                              _buildStatusChip('Servis', summary.overdueCount, Colors.redAccent),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.space16),

          // 2B. Estimated Upcoming Cost & Budget Forecast Card
          MaintenanceCostForecastCard(vehicleId: vehicle.id),
          const SizedBox(height: AppSpacing.space16),

          // 2C. UPCOMING MAINTENANCE Section
          UpcomingMaintenanceCard(vehicleId: vehicle.id),
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

    String statusBadgeText;
    if (itemHealth.isOverdue) {
      statusBadgeText = 'Lewat Jadwal';
    } else if (itemHealth.isDueSoon) {
      statusBadgeText = 'Segera Diganti';
    } else {
      statusBadgeText = 'Kondisi Baik';
    }

    final String timingText;
    if (itemHealth.isOverdue) {
      timingText = 'Perkiraan: Terlewat ${numberFormat.format(itemHealth.remainingKm.abs())} KM';
    } else {
      timingText = 'Perkiraan: ${numberFormat.format(itemHealth.remainingKm)} KM lagi';
    }

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
                ? AppColors.healthCritical.withValues(alpha: 0.5)
                : (itemHealth.isDueSoon
                    ? AppColors.healthWarning.withValues(alpha: 0.4)
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusBadgeText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Friendly Timing text
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: itemHealth.isOverdue
                      ? AppColors.healthCritical
                      : (itemHealth.isDueSoon ? AppColors.healthWarning : AppColors.textSecondary),
                ),
                const SizedBox(width: 6),
                Text(
                  timingText,
                  style: TextStyle(
                    color: itemHealth.isOverdue
                        ? AppColors.healthCritical
                        : (itemHealth.isDueSoon ? AppColors.textPrimary : AppColors.textSecondary),
                    fontWeight: itemHealth.isDueSoon || itemHealth.isOverdue
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            // Estimasi Biaya ringkas jika ada
            if (itemHealth.priceEstimate != null) ...[
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
                    const SizedBox(width: 6),
                    Text(
                      'Perkiraan Biaya: ${itemHealth.priceEstimate!.formattedTotalRange}',
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
