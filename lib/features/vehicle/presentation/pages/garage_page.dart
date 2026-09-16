import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';
import '../widgets/vehicle_card.dart';
import 'add_vehicle_page.dart';
import 'vehicle_detail_page.dart';

/// Clean, professional & elegant Garage Page with batch multi-selection support (PRD Section 7.1)
class GaragePage extends ConsumerStatefulWidget {
  const GaragePage({super.key});

  @override
  ConsumerState<GaragePage> createState() => _GaragePageState();
}

class _GaragePageState extends ConsumerState<GaragePage> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  void _enterSelectionMode([String? initialVehicleId]) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.clear();
      if (initialVehicleId != null) {
        _selectedIds.add(initialVehicleId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleItemSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll(List<VehicleModel> vehicles) {
    setState(() {
      if (_selectedIds.length == vehicles.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(vehicles.map((v) => v.id));
      }
    });
  }

  Future<void> _confirmDeleteSelected() async {
    final count = _selectedIds.length;
    if (count == 0) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardBorderRadius),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.healthCritical.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: AppColors.healthCritical,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Text(
                count == 1 ? 'Hapus Kendaraan?' : 'Hapus $count Kendaraan?',
                style: AppTypography.heading2,
              ),
            ),
          ],
        ),
        content: Text(
          count == 1
              ? 'Data kendaraan beserta riwayat servis dan perjalanannya akan dihapus permanen dari garasi.'
              : 'Semua $count kendaraan yang dipilih beserta seluruh catatan servis dan perjalanannya akan dihapus permanen.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
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
                  onPressed: () => Navigator.pop(ctx, false),
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
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Hapus ($count)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;
    final idsToDelete = _selectedIds.toList();
    _exitSelectionMode();

    try {
      await ref.read(vehicleProvider.notifier).deleteMultipleVehicles(idsToDelete);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil menghapus $count kendaraan.'),
          backgroundColor: AppColors.healthOptimal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus kendaraan: $e'),
          backgroundColor: AppColors.healthCritical,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehicleProvider);
    final activeVehicle = ref.watch(activeVehicleProvider);
    final vehicles = vehiclesAsync.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: _buildAppBar(vehicles),
      body: SafeArea(
        child: vehiclesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                  const SizedBox(height: AppSpacing.space16),
                  Text('Gagal memuat garasi', style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    err.toString(),
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.buttonBorderRadius,
                      ),
                    ),
                    onPressed: () => ref.read(vehicleProvider.notifier).loadVehicles(),
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    label: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          data: (vehicleList) {
            if (vehicleList.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.garage_rounded,
                          size: 54,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space24),
                      Text('Belum ada kendaraan', style: AppTypography.heading1),
                      const SizedBox(height: AppSpacing.space8),
                      Text(
                        'Tambahkan profil motor atau mobil Anda untuk memantau kesehatan dan riwayat berkendara.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          minimumSize: const Size(220, 50),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.buttonBorderRadius,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddVehiclePage()),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                        label: Text(
                          'Tambah Kendaraan',
                          style: AppTypography.heading3.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primaryBlue,
              onRefresh: () => ref.read(vehicleProvider.notifier).loadVehicles(forceRemote: true),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space16,
                  AppSpacing.space16,
                  AppSpacing.space16,
                  96, // Ample space for FAB and navigation bar
                ),
                itemCount: vehicleList.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.space12),
                itemBuilder: (context, index) {
                  final vehicle = vehicleList[index];
                  final isActive = vehicle.id == activeVehicle?.id;
                  final isSelected = _selectedIds.contains(vehicle.id);

                  return VehicleCard(
                    vehicle: vehicle,
                    isActive: isActive,
                    isSelectionMode: _isSelectionMode,
                    isSelected: isSelected,
                    onSelectChanged: (_) => _toggleItemSelection(vehicle.id),
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        _enterSelectionMode(vehicle.id);
                      }
                    },
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleItemSelection(vehicle.id);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VehicleDetailPage(vehicle: vehicle),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(vehicles),
    );
  }

  PreferredSizeWidget _buildAppBar(List<VehicleModel> vehicles) {
    if (_isSelectionMode) {
      final allSelected = vehicles.isNotEmpty && _selectedIds.length == vehicles.length;

      return AppBar(
        elevation: 1,
        backgroundColor: AppColors.surfaceWhite,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          tooltip: 'Batal',
          onPressed: _exitSelectionMode,
        ),
        title: Text(
          '${_selectedIds.length} Dipilih',
          style: AppTypography.heading2.copyWith(color: AppColors.primaryBlue),
        ),
        actions: [
          IconButton(
            icon: Icon(
              allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
              color: AppColors.primaryBlue,
            ),
            tooltip: allSelected ? 'Batalkan Semua' : 'Pilih Semua',
            onPressed: () => _toggleSelectAll(vehicles),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: _selectedIds.isNotEmpty ? AppColors.healthCritical : AppColors.textMuted,
            ),
            tooltip: 'Hapus yang Dipilih',
            onPressed: _selectedIds.isNotEmpty ? () => _confirmDeleteSelected() : null,
          ),
        ],
      );
    }

    return AppBar(
      title: Row(
        children: [
          Text('Garasi Saya', style: AppTypography.heading1),
          if (vehicles.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.space8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${vehicles.length}',
                style: AppTypography.captionBadge.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
      elevation: 0,
      backgroundColor: AppColors.surfaceWhite,
      actions: [
        if (vehicles.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.checklist_rounded, color: AppColors.textSecondary),
            tooltip: 'Pilih / Hapus Massal',
            onPressed: () => _enterSelectionMode(),
          ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
          tooltip: 'Sinkronisasi dengan Cloud',
          onPressed: () => ref.read(vehicleProvider.notifier).loadVehicles(forceRemote: true),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryBlue, size: 26),
          tooltip: 'Tambah Kendaraan',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddVehiclePage()),
            );
          },
        ),
      ],
    );
  }

  Widget? _buildFloatingActionButton(List<VehicleModel> vehicles) {
    if (_isSelectionMode) {
      if (_selectedIds.isEmpty) return null;
      return FloatingActionButton.extended(
        onPressed: () => _confirmDeleteSelected(),
        backgroundColor: AppColors.healthCritical,
        elevation: 4,
        icon: const Icon(Icons.delete_rounded, color: Colors.white),
        label: Text(
          'Hapus (${_selectedIds.length})',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (vehicles.isEmpty) return null;

    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddVehiclePage()),
        );
      },
      backgroundColor: AppColors.primaryBlue,
      elevation: 3,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        'Tambah Kendaraan',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
