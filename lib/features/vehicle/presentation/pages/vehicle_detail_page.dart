import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';
import '../../../maintenance/presentation/pages/maintenance_page.dart';
import '../../../maintenance/providers/maintenance_intelligence_providers.dart';
import '../../../maintenance/presentation/widgets/maintenance_detail_bottom_sheet.dart';
import '../../../maintenance/providers/maintenance_prediction_providers.dart';
import 'add_vehicle_page.dart';

/// Page displaying detailed information, specifications, and actions for a vehicle
class VehicleDetailPage extends ConsumerStatefulWidget {
  final VehicleModel vehicle;

  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  ConsumerState<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends ConsumerState<VehicleDetailPage> {
  late VehicleModel _vehicle;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kendaraan?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${_vehicle.displayName}"? Data lokal dan cloud akan dihapus.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await ref.read(vehicleProvider.notifier).deleteVehicle(_vehicle.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_vehicle.displayName} berhasil dihapus.'),
            backgroundColor: Colors.black87,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus kendaraan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _handleEdit() async {
    final updated = await Navigator.push<VehicleModel?>(
      context,
      MaterialPageRoute(
        builder: (_) => AddVehiclePage(vehicleToEdit: _vehicle),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _vehicle = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep local model in sync with provider updates
    final vehiclesAsync = ref.watch(vehicleProvider);
    final latest = vehiclesAsync.value?.where((v) => v.id == _vehicle.id).firstOrNull;
    if (latest != null) {
      _vehicle = latest;
    }

    final activeVehicle = ref.watch(activeVehicleProvider);
    final isActive = activeVehicle?.id == _vehicle.id;
    final healthSummaryAsync = ref.watch(maintenanceHealthProvider(_vehicle.id));

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(_vehicle.displayName, style: AppTypography.heading2),
        elevation: 0,
        backgroundColor: AppColors.surfaceWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            tooltip: 'Edit Kendaraan',
            onPressed: _handleEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: 'Hapus Kendaraan',
            onPressed: _isDeleting ? null : _handleDelete,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Vehicle Header Banner (with Status & Total Jarak Kendaraan)
              _buildHeaderBanner(isActive, healthSummaryAsync),

              const SizedBox(height: AppSpacing.space16),

              // 2. Next Maintenance Card (Most Urgent Service)
              _buildNextMaintenanceCard(),

              const SizedBox(height: AppSpacing.space16),

              // 3. Maintenance Preview (Component Health)
              _buildMaintenancePreviewCard(healthSummaryAsync),

              const SizedBox(height: AppSpacing.space16),

              // 4. Specifications Card (Collapsible)
              _buildSpecificationCard(),

              const SizedBox(height: AppSpacing.space16),

              // 5. Ride History Preview
              _buildRideHistoryPreviewCard(),

              const SizedBox(height: AppSpacing.space24),

              // 6. Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleEdit,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.buttonBorderRadius,
                        ),
                        side: const BorderSide(color: AppColors.primaryBlue),
                      ),
                      icon: const Icon(Icons.edit_rounded, color: AppColors.primaryBlue),
                      label: const Text('Edit Kendaraan', style: TextStyle(color: AppColors.primaryBlue)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isDeleting ? null : _handleDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.buttonBorderRadius,
                          side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      label: const Text('Hapus Kendaraan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(bool isActive, AsyncValue<VehicleHealthSummary> healthSummaryAsync) {
    final isMotor = _vehicle.isMotorcycle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.cardBorderRadius,
        border: Border.all(
          color: isActive ? AppColors.primaryBlue : AppColors.borderSubtle,
          width: isActive ? 1.5 : 1.0,
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
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isMotor
                      ? AppColors.primaryBlue.withValues(alpha: 0.1)
                      : AppColors.secondaryTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMotor ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
                  color: isMotor ? AppColors.primaryBlue : AppColors.secondaryTeal,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vehicle.displayName,
                      style: AppTypography.heading2,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_vehicle.year} • ${_vehicle.isMotorcycle ? 'Sepeda Motor' : 'Mobil'}${_vehicle.licensePlate != null ? ' • ${_vehicle.licensePlate}' : ''}',
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

          // Total Jarak & Status Kendaraan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL JARAK KENDARAAN', style: AppTypography.captionBadge),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormatter.formatKm(_vehicle.currentKilometer)} KM',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              healthSummaryAsync.when(
                loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (summary) {
                  Color statusColor;
                  String statusText;
                  IconData statusIcon;

                  if (summary.overdueCount > 0) {
                    statusColor = AppColors.healthCritical;
                    statusText = 'Perlu Servis';
                    statusIcon = Icons.error_rounded;
                  } else if (summary.dueSoonCount > 0) {
                    statusColor = AppColors.healthWarning;
                    statusText = 'Perlu Perhatian';
                    statusIcon = Icons.warning_amber_rounded;
                  } else {
                    statusColor = AppColors.healthOptimal;
                    statusText = 'Kondisi Aman';
                    statusIcon = Icons.check_circle_rounded;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Active vehicle status / toggle
          if (isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Kendaraan Aktif Utama',
                    style: AppTypography.captionBadge.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  await ref.read(activeVehicleProvider.notifier).setActiveVehicle(_vehicle.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${_vehicle.displayName} disetel sebagai kendaraan aktif.'),
                        backgroundColor: AppColors.primaryBlue,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.radio_button_unchecked, size: 16),
                label: const Text('Jadikan Kendaraan Aktif'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecificationCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.cardBorderRadius,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: const Icon(Icons.tune_rounded, size: 20, color: AppColors.primaryBlue),
          title: Text(
            'Detail & Spesifikasi Kendaraan',
            style: AppTypography.heading3.copyWith(fontSize: 14),
          ),
          subtitle: Text(
            'Kapasitas mesin, transmisi, bahan bakar, warna',
            style: AppTypography.captionBadge.copyWith(
              fontWeight: FontWeight.normal,
              color: AppColors.textSecondary,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _buildSpecRow(
                    icon: Icons.speed_rounded,
                    label: 'Kapasitas Mesin',
                    value: _vehicle.engineCc != null ? '${_vehicle.engineCc} CC' : '-',
                  ),
                  const Divider(height: 16, color: AppColors.borderSubtle),
                  _buildSpecRow(
                    icon: Icons.settings_suggest_rounded,
                    label: 'Transmisi',
                    value: _vehicle.transmission ?? 'Automatic',
                  ),
                  const Divider(height: 16, color: AppColors.borderSubtle),
                  _buildSpecRow(
                    icon: Icons.local_gas_station_rounded,
                    label: 'Bahan Bakar',
                    value: _vehicle.fuelType ?? 'Gasoline',
                  ),
                  if (_vehicle.color != null && _vehicle.color!.isNotEmpty) ...[
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    _buildSpecRow(
                      icon: Icons.palette_outlined,
                      label: 'Warna',
                      value: _vehicle.color!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildNextMaintenanceCard() {
    final upcomingAsync = ref.watch(upcomingMaintenanceProvider(_vehicle.id));

    return upcomingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        final nextItem = items.first;

        final Color badgeColor;
        final Color badgeBgColor;
        final String statusLabel;

        if (nextItem.isOverdue) {
          badgeColor = AppColors.healthCritical;
          badgeBgColor = Colors.red.withValues(alpha: 0.1);
          statusLabel = 'Lewat Jadwal';
        } else if (nextItem.isDueSoon) {
          badgeColor = AppColors.healthWarning;
          badgeBgColor = Colors.orange.withValues(alpha: 0.1);
          statusLabel = 'Segera Diganti';
        } else {
          badgeColor = AppColors.healthOptimal;
          badgeBgColor = Colors.green.withValues(alpha: 0.1);
          statusLabel = 'Kondisi Baik';
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: AppSpacing.cardBorderRadius,
            border: Border.all(
              color: nextItem.isOverdue
                  ? AppColors.healthCritical.withValues(alpha: 0.4)
                  : (nextItem.isDueSoon
                      ? AppColors.healthWarning.withValues(alpha: 0.4)
                      : AppColors.borderSubtle),
              width: nextItem.isOverdue || nextItem.isDueSoon ? 1.5 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => MaintenanceDetailBottomSheet.show(
              context,
              prediction: nextItem,
              vehicleId: _vehicle.id,
            ),
            borderRadius: AppSpacing.cardBorderRadius,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.build_circle_rounded,
                            size: 18,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Text('PERKIRAAN SERVIS TERDEKAT', style: AppTypography.captionBadge),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: AppSpacing.chipBorderRadius,
                        ),
                        child: Text(
                          statusLabel,
                          style: AppTypography.captionBadge.copyWith(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextItem.componentName,
                              style: AppTypography.heading3.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Perkiraan: ${nextItem.remainingKm > 0 ? DateFormatter.formatKm(nextItem.remainingKm.toDouble()) : '0'} KM lagi (${nextItem.remainingDays > 0 ? '${nextItem.remainingDays} hari' : 'Hari ini'})',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Perkiraan Biaya: ${nextItem.formattedTotalRange}',
                              style: AppTypography.captionBadge.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMaintenancePreviewCard(AsyncValue<VehicleHealthSummary> healthSummaryAsync) {
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
              const Icon(Icons.build_circle_outlined, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text('KONDISI PERAWATAN', style: AppTypography.captionBadge),
              const Spacer(),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MaintenancePage(initialVehicleId: _vehicle.id),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Semua',
                      style: AppTypography.captionBadge.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primaryBlue),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          healthSummaryAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Row(
              children: [
                const Icon(Icons.health_and_safety_rounded, color: AppColors.healthOptimal, size: 20),
                const SizedBox(width: 8),
                Text('Kondisi Kendaraan: Baik', style: AppTypography.bodyMedium),
              ],
            ),
            data: (summary) {
              final sortedItems = [...summary.healthItems];
              sortedItems.sort((a, b) => a.remainingKm.compareTo(b.remainingKm));
              final previewItems = sortedItems.take(3).toList();

              Color statusColor;
              String statusText;
              if (summary.overdueCount > 0) {
                statusColor = AppColors.healthCritical;
                statusText = '${summary.overdueCount} komponen perlu servis segera';
              } else if (summary.dueSoonCount > 0) {
                statusColor = AppColors.healthWarning;
                statusText = '${summary.dueSoonCount} komponen mendekati jadwal ganti';
              } else {
                statusColor = AppColors.healthOptimal;
                statusText = 'Semua komponen dalam kondisi baik';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.health_and_safety_rounded, color: statusColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  if (previewItems.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    const SizedBox(height: 10),
                    ...previewItems.map((item) {
                      Color itemColor;
                      String itemStatusText;
                      if (item.isOverdue) {
                        itemColor = AppColors.healthCritical;
                        itemStatusText = 'Lewat Jadwal';
                      } else if (item.isDueSoon) {
                        itemColor = AppColors.healthWarning;
                        itemStatusText = 'Segera Diganti';
                      } else {
                        itemColor = AppColors.healthOptimal;
                        itemStatusText = 'Baik';
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: itemColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.item.itemName ?? 'Komponen',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  item.isOverdue
                                      ? 'Lewat ${DateFormatter.formatKm(item.remainingKm.abs().toDouble())} KM'
                                      : '${DateFormatter.formatKm(item.remainingKm.toDouble())} KM lagi',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: itemColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: itemColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    itemStatusText,
                                    style: TextStyle(
                                      color: itemColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Pantau perkiraan jadwal servis, estimasi biaya komponen & riwayat pemakaian.',
            style: AppTypography.captionSubtle,
          ),
        ],
      ),
    );
  }

  Widget _buildRideHistoryPreviewCard() {
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
              const Icon(Icons.route_rounded, size: 18, color: Colors.indigo),
              const SizedBox(width: 8),
              Text('RIWAYAT PERJALANAN', style: AppTypography.captionBadge),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Segera Hadir', style: AppTypography.captionSubtle.copyWith(fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            'Sesi tracking berkendara menggunakan kendaraan ini akan tercatat otomatis pada riwayat rute perjalanan.',
            style: AppTypography.captionSubtle,
          ),
        ],
      ),
    );
  }
}
