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
              // 1. Vehicle Header Banner
              _buildHeaderBanner(isActive),

              const SizedBox(height: AppSpacing.space24),

              // 2. Specifications Card
              _buildSpecificationCard(),

              const SizedBox(height: AppSpacing.space16),

              // 3. Mileage & Odometer Card
              _buildMileageCard(),

              const SizedBox(height: AppSpacing.space16),

              // 4. Maintenance Preview (Coming Soon)
              _buildMaintenancePreviewCard(),

              const SizedBox(height: AppSpacing.space16),

              // 5. Ride History Preview (Coming Soon)
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
                      label: const Text('Edit Vehicle', style: TextStyle(color: AppColors.primaryBlue)),
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
                      label: const Text('Delete Vehicle'),
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

  Widget _buildHeaderBanner(bool isActive) {
    final isMotor = _vehicle.isMotorcycle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space24),
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
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isMotor
                  ? AppColors.primaryBlue.withValues(alpha: 0.1)
                  : AppColors.secondaryTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMotor ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
              color: isMotor ? AppColors.primaryBlue : AppColors.secondaryTeal,
              size: 36,
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          Text(
            _vehicle.displayName,
            style: AppTypography.heading1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${_vehicle.year} • ${_vehicle.vehicleType.toUpperCase()}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          if (_vehicle.licensePlate != null && _vehicle.licensePlate!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                _vehicle.licensePlate!,
                style: AppTypography.captionBadge.copyWith(
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space16),
          // Active vehicle status / toggle
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue, size: 16),
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
            TextButton.icon(
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
        ],
      ),
    );
  }

  Widget _buildSpecificationCard() {
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
              const Icon(Icons.tune_rounded, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text('SPECIFICATION', style: AppTypography.captionBadge),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),
          _buildSpecRow(
            icon: Icons.speed_rounded,
            label: 'Engine',
            value: _vehicle.engineCc != null ? '${_vehicle.engineCc} CC' : '-',
          ),
          const Divider(height: 16, color: AppColors.borderSubtle),
          _buildSpecRow(
            icon: Icons.settings_suggest_rounded,
            label: 'Transmission',
            value: _vehicle.transmission ?? 'Automatic',
          ),
          const Divider(height: 16, color: AppColors.borderSubtle),
          _buildSpecRow(
            icon: Icons.local_gas_station_rounded,
            label: 'Fuel',
            value: _vehicle.fuelType ?? 'Gasoline',
          ),
          if (_vehicle.color != null && _vehicle.color!.isNotEmpty) ...[
            const Divider(height: 16, color: AppColors.borderSubtle),
            _buildSpecRow(
              icon: Icons.palette_outlined,
              label: 'Color',
              value: _vehicle.color!,
            ),
          ],
        ],
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

  Widget _buildMileageCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.cardBorderRadius,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_road_rounded, color: AppColors.secondaryTeal, size: 24),
          ),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MILEAGE / ODOMETER', style: AppTypography.captionBadge),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.formatKm(_vehicle.currentKilometer),
                  style: AppTypography.heading1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenancePreviewCard() {
    final healthSummaryAsync = ref.watch(maintenanceHealthProvider(_vehicle.id));

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
              Text('MAINTENANCE INTELLIGENCE', style: AppTypography.captionBadge),
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
                      'Buka Detail',
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
                Text('Health Status: 100% (Baik)', style: AppTypography.bodyMedium),
              ],
            ),
            data: (summary) {
              final score = summary.overallScore.round();
              final isGood = score >= 80;
              final scoreColor = isGood
                  ? AppColors.healthOptimal
                  : (score >= 50 ? Colors.orangeAccent : Colors.redAccent);

              return Row(
                children: [
                  Icon(Icons.health_and_safety_rounded, color: scoreColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Overall Health: $score% (${isGood ? 'Kondisi Baik' : 'Perlu Perhatian'})',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            'Pantau interval servis, estimasi biaya suku cadang & jasa, serta riwayat servis berkala.',
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
              Text('RIDE HISTORY', style: AppTypography.captionBadge),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Coming soon', style: AppTypography.captionSubtle.copyWith(fontSize: 10)),
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
