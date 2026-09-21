import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/vehicle_asset_resolver.dart';
import '../../../maintenance/providers/maintenance_intelligence_providers.dart';
import '../../../maintenance/providers/maintenance_prediction_providers.dart';
import '../../data/models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';
import '../widgets/vehicle_card.dart';
import 'add_vehicle_page.dart';
import 'vehicle_detail_page.dart';

/// Redesigned Digital Garage Page adhering strictly to DESIGN.md
/// "Digital garage pribadi pengguna - Ini adalah koleksi kendaraan saya."
class GaragePage extends ConsumerStatefulWidget {
  const GaragePage({super.key});

  @override
  ConsumerState<GaragePage> createState() => _GaragePageState();
}

class _GaragePageState extends ConsumerState<GaragePage> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  late final PageController _heroPageController;

  @override
  void initState() {
    super.initState();
    _heroPageController = PageController();
  }

  @override
  void dispose() {
    _heroPageController.dispose();
    super.dispose();
  }

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

  String _getSilhouetteAsset(VehicleModel v) =>
      VehicleAssetResolver.getSilhouetteAsset(v);

  String _formatKm(double km) {
    final formatted = NumberFormat('#,##0', 'id_ID').format(km.round());
    return '$formatted KM';
  }

  Future<void> _confirmDeleteSelected() async {
    final count = _selectedIds.length;
    if (count == 0) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: AppColors.danger,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Text(
                count == 1 ? 'Hapus Kendaraan?' : 'Hapus $count Kendaraan?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          count == 1
              ? 'Data kendaraan beserta riwayat servis dan perjalanannya akan dihapus permanen dari garasi.'
              : 'Semua $count kendaraan yang dipilih beserta seluruh catatan servis dan perjalanannya akan dihapus permanen.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'Hapus ($count)',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
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
          content: Text(
            'Berhasil menghapus $count kendaraan dari garasi.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus kendaraan: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showVehicleBottomSheet(BuildContext context, VehicleModel vehicle, bool isActive) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final upcomingAsync = ref.watch(upcomingMaintenanceProvider(vehicle.id));
            final healthSummaryAsync = ref.watch(maintenanceHealthProvider(vehicle.id));

            final summary = healthSummaryAsync.value;
            final upcomingList = upcomingAsync.value ?? [];

            String conditionLabel = 'Kondisi Baik';
            String conditionReason = 'Semua komponen dalam kondisi terawat';
            Color conditionColor = AppColors.success;

            if (summary != null && summary.overdueCount > 0) {
              conditionLabel = 'Perlu Perhatian Segera';
              conditionColor = AppColors.danger;
              final overdueItem = upcomingList.where((p) => p.isOverdue).firstOrNull;
              conditionReason = overdueItem != null
                  ? '${overdueItem.componentName} melewati jadwal servis'
                  : 'Beberapa komponen memerlukan penggantian';
            } else if (summary != null && summary.dueSoonCount > 0) {
              conditionLabel = 'Perlu Perhatian Ringan';
              conditionColor = AppColors.warning;
              final dueSoonItem = upcomingList.where((p) => p.isDueSoon).firstOrNull;
              conditionReason = dueSoonItem != null
                  ? '${dueSoonItem.componentName} mendekati jadwal servis'
                  : 'Pemeriksaan berkala dianjurkan';
            } else if (upcomingList.isNotEmpty) {
              conditionReason = 'Servis berikutnya: ${upcomingList.first.componentName}';
            }

            final silhouetteAsset = _getSilhouetteAsset(vehicle);

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: AppColors.borderStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header Row: Vehicle Silhouette + Basic Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 64,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F5EF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: SvgPicture.asset(
                          silhouetteAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.displayName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSubtle,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${vehicle.year}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                if (vehicle.engineCc != null && vehicle.engineCc! > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceSubtle,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${vehicle.engineCc} CC',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                if (vehicle.licensePlate != null && vehicle.licensePlate!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      vehicle.licensePlate!.toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  const SizedBox(height: 16),

                  // Metrics: Space Grotesk Odometer & Humanized Condition
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F5EF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ODOMETER',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatKm(vehicle.currentKilometer),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: conditionColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: conditionColor.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STATUS KONDISI',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: conditionColor,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                conditionLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: conditionColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Recommendation Callout
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5EF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: conditionColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            conditionReason,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  if (!isActive) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ref.read(activeVehicleProvider.notifier).setActiveVehicle(vehicle.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${vehicle.displayName} sekarang menjadi kendaraan aktif.',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: AppColors.primaryNavy,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded, color: AppColors.accentCyan, size: 20),
                      label: Text(
                        'Jadikan Kendaraan Aktif',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryNavy,
                      side: const BorderSide(color: AppColors.borderStrong),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VehicleDetailPage(vehicle: vehicle),
                        ),
                      );
                    },
                    icon: const Icon(Icons.speed_rounded, size: 20),
                    label: Text(
                      'Buka Detail & Riwayat',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehicleProvider);
    final activeVehicle = ref.watch(activeVehicleProvider);
    final vehicles = vehiclesAsync.value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EF),
      appBar: _buildAppBar(vehicles),
      body: SafeArea(
        child: vehiclesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryNavy),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                  const SizedBox(height: AppSpacing.space16),
                  Text(
                    'Gagal memuat garasi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    err.toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => ref.read(vehicleProvider.notifier).loadVehicles(),
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    label: Text(
                      'Coba Lagi',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (vehicleList) {
            if (vehicleList.isEmpty) {
              return _buildEmptyState(context);
            }

            // Resolve target hero vehicle: active vehicle or first vehicle
            final heroVehicle = activeVehicle ?? vehicleList.first;
            final otherVehicles = vehicleList.where((v) => v.id != heroVehicle.id).toList();

            return RefreshIndicator(
              color: AppColors.primaryNavy,
              backgroundColor: Colors.white,
              onRefresh: () => ref.read(vehicleProvider.notifier).loadVehicles(forceRemote: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  // 1. ACTIVE VEHICLE HERO (DESIGN.md Section 12 & Hero Driven Layout)
                  _buildHeroCard(context, heroVehicle, vehicleList),
                  const SizedBox(height: 24),

                  // 2. VEHICLE COLLECTION (Compact List for other vehicles)
                  _buildCollectionSection(context, otherVehicles, heroVehicle, vehicleList),
                ],
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
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          tooltip: 'Batal',
          onPressed: _exitSelectionMode,
        ),
        title: Text(
          '${_selectedIds.length} Dipilih',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNavy,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
              color: AppColors.primaryNavy,
            ),
            tooltip: allSelected ? 'Batalkan Semua' : 'Pilih Semua',
            onPressed: () => _toggleSelectAll(vehicles),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: _selectedIds.isNotEmpty ? AppColors.danger : AppColors.textMuted,
            ),
            tooltip: 'Hapus yang Dipilih',
            onPressed: _selectedIds.isNotEmpty ? () => _confirmDeleteSelected() : null,
          ),
        ],
      );
    }

    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFFF7F5EF),
      centerTitle: false,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Garasi Saya',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            vehicles.isEmpty
                ? 'Belum ada kendaraan'
                : '${vehicles.length} kendaraan tersimpan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.secondarySteel,
            ),
          ),
        ],
      ),
      actions: [
        if (vehicles.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.checklist_rounded, color: AppColors.secondarySteel),
            tooltip: 'Pilih Massal',
            onPressed: () => _enterSelectionMode(),
          ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.secondarySteel),
          tooltip: 'Sinkronisasi',
          onPressed: () => ref.read(vehicleProvider.notifier).loadVehicles(forceRemote: true),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/illustrations/empty_garage.svg',
              width: 260,
              height: 190,
              fit: BoxFit.contain,
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 24),
            Text(
              'Garasi Masih Kosong',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan motor atau mobil Anda untuk memantau performa, riwayat perjalanan, dan rekomendasi perawatan.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                minimumSize: const Size(220, 50),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, VehicleModel heroVehicle, List<VehicleModel> allVehicles) {
    final upcomingAsync = ref.watch(upcomingMaintenanceProvider(heroVehicle.id));
    final healthSummaryAsync = ref.watch(maintenanceHealthProvider(heroVehicle.id));

    final summary = healthSummaryAsync.value;
    final upcomingList = upcomingAsync.value ?? [];

    String conditionBadge = 'Kondisi prima';
    Color conditionColor = AppColors.success;
    String recommendationText = 'Semua komponen dalam kondisi terawat';

    if (summary != null && summary.overdueCount > 0) {
      conditionBadge = 'Perlu perhatian';
      conditionColor = AppColors.danger;
      final overdueItem = upcomingList.where((p) => p.isOverdue).firstOrNull;
      recommendationText = overdueItem != null
          ? '${overdueItem.componentName} melewati jadwal'
          : 'Ada komponen melewati batas perawatan';
    } else if (summary != null && summary.dueSoonCount > 0) {
      conditionBadge = 'Perlu perhatian ringan';
      conditionColor = AppColors.warning;
      final dueSoonItem = upcomingList.where((p) => p.isDueSoon).firstOrNull;
      recommendationText = dueSoonItem != null
          ? 'Perawatan berikut: ${dueSoonItem.componentName}'
          : 'Pemeriksaan berkala dianjurkan';
    } else if (upcomingList.isNotEmpty) {
      conditionBadge = 'Kondisi baik';
      conditionColor = AppColors.success;
      recommendationText = 'Perawatan berikut: ${upcomingList.first.componentName}';
    }

    final silhouetteAsset = _getSilhouetteAsset(heroVehicle);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryNavy, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showVehicleBottomSheet(context, heroVehicle, true),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Name, Year, and Active Chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  heroVehicle.displayName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${heroVehicle.year}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (heroVehicle.licensePlate != null && heroVehicle.licensePlate!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              heroVehicle.licensePlate!.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Active Badge Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.accentCyan,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Kendaraan Aktif',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Vehicle Silhouette Hero Visual
                Container(
                  height: 130,
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    silhouetteAsset,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ).animate().fadeIn(duration: 350.ms),
                const SizedBox(height: 16),

                // Telemetry & Condition Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Space Grotesk Odometer
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ODOMETER',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatKm(heroVehicle.currentKilometer),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Humanized Condition Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: conditionColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: conditionColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: conditionColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            conditionBadge,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: conditionColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Recommendation Card Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5EF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.build_circle_outlined,
                        size: 18,
                        color: conditionColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recommendationText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionSection(
    BuildContext context,
    List<VehicleModel> otherVehicles,
    VehicleModel heroVehicle,
    List<VehicleModel> allVehicles,
  ) {
    if (otherVehicles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.primaryNavy,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tambah Kendaraan Lain',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Simpan semua motor & mobil Anda dalam satu garasi digital.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddVehiclePage()),
                );
              },
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Koleksi Kendaraan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${otherVehicles.length}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
              ],
            ),
            if (!_isSelectionMode)
              Text(
                'Ketuk untuk detail',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Compact Vehicle Cards List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: otherVehicles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final vehicle = otherVehicles[index];
            final isSelected = _selectedIds.contains(vehicle.id);

            return VehicleCard(
              vehicle: vehicle,
              isActive: false,
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
                  _showVehicleBottomSheet(context, vehicle, false);
                }
              },
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
        backgroundColor: AppColors.danger,
        elevation: 4,
        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
        label: Text(
          'Hapus (${_selectedIds.length})',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
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
      backgroundColor: AppColors.primaryNavy,
      elevation: 4,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: Text(
        'Tambah Kendaraan',
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
