import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../maintenance/domain/maintenance_prediction_service.dart';
import '../../../maintenance/presentation/pages/add_service_page.dart';
import '../../../maintenance/presentation/pages/maintenance_page.dart';
import '../../../maintenance/presentation/widgets/maintenance_detail_bottom_sheet.dart';
import '../../../maintenance/presentation/widgets/vehicle_part_icon_badge.dart';
import '../../../maintenance/providers/maintenance_intelligence_providers.dart';
import '../../../maintenance/providers/maintenance_prediction_providers.dart';
import '../../../ride_tracking/presentation/controllers/ride_tracking_controller.dart';
import '../../../ride_tracking/presentation/screens/ride_history_screen.dart';
import '../../data/models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';
import 'add_vehicle_page.dart';

/// Digital Vehicle Profile Page conforming strictly to DESIGN.md
/// "Profil digital kendaraan pribadi - Saya mengenal kondisi kendaraan saya."
class VehicleDetailPage extends ConsumerStatefulWidget {
  final VehicleModel vehicle;

  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  ConsumerState<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends ConsumerState<VehicleDetailPage> {
  late VehicleModel _vehicle;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
  }

  String _getSilhouetteAsset(VehicleModel v) {
    if (!v.isMotorcycle) {
      return 'assets/vehicles/vehicle_silhouette_car.svg';
    }
    final trans = (v.transmission ?? '').toLowerCase();
    if (trans.contains('manual') || trans.contains('kopling') || trans.contains('sport')) {
      return 'assets/vehicles/vehicle_silhouette_manual.svg';
    }
    return 'assets/vehicles/vehicle_silhouette_scooter.svg';
  }

  String _formatKm(double km) {
    final formatted = NumberFormat('#,##0', 'id_ID').format(km.round());
    return '$formatted KM';
  }

  String _formatTransmission(String? val) {
    final isCar = _vehicle.vehicleType.toLowerCase() == 'car';
    if (val == null || val.isEmpty) {
      return isCar ? 'Otomatis (Matic)' : 'Matic';
    }
    final lower = val.toLowerCase();
    if (lower == 'automatic' || lower == 'otomatis' || lower == 'matic') {
      return isCar ? 'Otomatis (Matic)' : 'Matic';
    }
    if (lower == 'manual') return 'Manual';
    return val;
  }

  String _formatFuelType(String? val) {
    if (val == null || val.isEmpty) return 'Bensin';
    final lower = val.toLowerCase();
    if (lower == 'gasoline' || lower == 'petrol' || lower == 'bensin') return 'Bensin';
    if (lower == 'diesel' || lower == 'solar') return 'Diesel';
    if (lower == 'hybrid') return 'Hybrid';
    if (lower == 'electric' || lower == 'listrik') return 'Listrik';
    return val;
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
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
              child: const Icon(Icons.delete_sweep_rounded, color: AppColors.danger, size: 24),
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Text(
                'Hapus Kendaraan?',
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
          'Apakah Anda yakin ingin menghapus "${_vehicle.displayName}"? Seluruh data riwayat servis dan perjalanan akan dihapus permanen.',
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'Hapus',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(vehicleProvider.notifier).deleteVehicle(_vehicle.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_vehicle.displayName} berhasil dihapus dari garasi.',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus kendaraan: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
    // Keep local model synchronized with latest state
    final vehiclesAsync = ref.watch(vehicleProvider);
    final latest = vehiclesAsync.value?.where((v) => v.id == _vehicle.id).firstOrNull;
    if (latest != null) {
      _vehicle = latest;
    }

    final activeVehicle = ref.watch(activeVehicleProvider);
    final isActive = activeVehicle?.id == _vehicle.id;
    final healthSummaryAsync = ref.watch(maintenanceHealthProvider(_vehicle.id));
    final upcomingAsync = ref.watch(upcomingMaintenanceProvider(_vehicle.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EF),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. VEHICLE IDENTITY HERO (DESIGN.md Section 12)
              _buildVehicleHero(isActive, healthSummaryAsync),
              const SizedBox(height: 20),

              // 2. CURRENT VEHICLE CONDITION ("Kondisi Kendaraan")
              _buildConditionSection(healthSummaryAsync, upcomingAsync),
              const SizedBox(height: 20),

              // 3. MAINTENANCE PRIORITY ("Perawatan Berikutnya")
              _buildMaintenancePrioritySection(upcomingAsync),
              const SizedBox(height: 20),

              // 4. MAINTENANCE SUMMARY ("Ringkasan Perawatan")
              _buildMaintenanceSummarySection(healthSummaryAsync),
              const SizedBox(height: 20),

              // 5. VEHICLE SPECIFICATION (Expandable)
              _buildSpecificationSection(),
              const SizedBox(height: 20),

              // 6. JOURNEY HISTORY ("Riwayat Perjalanan")
              _buildJourneyHistorySection(),
              const SizedBox(height: 28),

              // 7. ACTIONS (Contextual Primary CTA)
              _buildBottomAction(context),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFFF7F5EF),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryNavy, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Profil Kendaraan',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryNavy,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.secondarySteel),
          tooltip: 'Edit Kendaraan',
          onPressed: _handleEdit,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.secondarySteel),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) {
            if (val == 'edit') {
              _handleEdit();
            } else if (val == 'delete') {
              _handleDelete();
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_rounded, size: 18, color: AppColors.primaryNavy),
                  const SizedBox(width: 10),
                  Text(
                    'Edit Kendaraan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                  const SizedBox(width: 10),
                  Text(
                    'Hapus Kendaraan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // ==================================================
  // 1. VEHICLE IDENTITY HERO
  // ==================================================
  Widget _buildVehicleHero(bool isActive, AsyncValue<VehicleHealthSummary> healthSummaryAsync) {
    final silhouetteAsset = _getSilhouetteAsset(_vehicle);

    final summary = healthSummaryAsync.value;
    String conditionBadge = 'Kondisi Prima';
    Color conditionColor = AppColors.success;

    if (summary != null && summary.overdueCount > 0) {
      conditionBadge = 'Perlu Perhatian';
      conditionColor = AppColors.danger;
    } else if (summary != null && summary.dueSoonCount > 0) {
      conditionBadge = 'Perlu Perhatian Ringan';
      conditionColor = AppColors.warning;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Vehicle name, Year, and Active Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vehicle.displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                        letterSpacing: -0.4,
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
                            '${_vehicle.year}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondarySteel,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _vehicle.isMotorcycle ? 'Sepeda Motor' : 'Mobil',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondarySteel,
                            ),
                          ),
                        ),
                        if (_vehicle.licensePlate != null && _vehicle.licensePlate!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _vehicle.licensePlate!.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
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

              // Active Badge or Set Active Action
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                        'Aktif',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  onTap: () async {
                    await ref.read(activeVehicleProvider.notifier).setActiveVehicle(_vehicle.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${_vehicle.displayName} sekarang disetel sebagai kendaraan aktif.',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: AppColors.primaryNavy,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      'Jadikan Aktif',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondarySteel,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Vehicle Silhouette Stage
          Container(
            height: 125,
            width: double.infinity,
            alignment: Alignment.center,
            child: SvgPicture.asset(
              silhouetteAsset,
              height: 115,
              fit: BoxFit.contain,
            ),
          ).animate().fadeIn(duration: 350.ms),
          const SizedBox(height: 16),

          // Telemetry Row: Odometer in Space Grotesk & Condition Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5EF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL JARAK',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatKm(_vehicle.currentKilometer),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: conditionColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: conditionColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: conditionColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        conditionBadge,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: conditionColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // 2. CURRENT VEHICLE CONDITION ("Kondisi Kendaraan")
  // ==================================================
  Widget _buildConditionSection(
    AsyncValue<VehicleHealthSummary> healthSummaryAsync,
    AsyncValue<List<MaintenancePrediction>> upcomingAsync,
  ) {
    final summary = healthSummaryAsync.value;
    final upcomingList = upcomingAsync.value ?? [];

    String headline = 'Kondisi prima';
    String description = 'Semua sistem dan komponen siap digunakan berkendara.';
    Color conditionColor = AppColors.success;
    IconData conditionIcon = Icons.check_circle_outline_rounded;

    if (summary != null && summary.overdueCount > 0) {
      headline = 'Perlu perhatian';
      conditionColor = AppColors.danger;
      conditionIcon = Icons.warning_amber_rounded;
      final overdueItem = upcomingList.where((p) => p.isOverdue).firstOrNull;
      description = overdueItem != null
          ? '${overdueItem.componentName} melewati jadwal perawatan.'
          : 'Ada komponen yang telah melewati jadwal perawatan berkala.';
    } else if (summary != null && summary.dueSoonCount > 0) {
      headline = 'Perlu perhatian ringan';
      conditionColor = AppColors.warning;
      conditionIcon = Icons.info_outline_rounded;
      final dueSoonItem = upcomingList.where((p) => p.isDueSoon).firstOrNull;
      description = dueSoonItem != null
          ? '${dueSoonItem.componentName} mendekati jadwal servis berkala.'
          : 'Beberapa komponen mendekati batas pemakaian wajar.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kondisi Kendaraan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: conditionColor.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: conditionColor.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: conditionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(conditionIcon, size: 22, color: conditionColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: conditionColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.secondarySteel,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================================================
  // 3. MAINTENANCE PRIORITY ("Perawatan Berikutnya")
  // ==================================================
  Widget _buildMaintenancePrioritySection(AsyncValue<List<MaintenancePrediction>> upcomingAsync) {
    final upcomingList = upcomingAsync.value ?? [];

    if (upcomingList.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perawatan Berikutnya',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semua Perawatan Lengkap',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Belum ada jadwal servis mendesak untuk kendaraan ini.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.secondarySteel,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final topItem = upcomingList.first;

    String urgencyTitle = 'Perawatan Berikutnya';
    String urgencyStatusText = 'Jadwal servis berkala';
    Color urgencyColor = AppColors.success;

    if (topItem.isOverdue) {
      urgencyStatusText = 'Sudah waktunya dilakukan';
      urgencyColor = AppColors.danger;
    } else if (topItem.isDueSoon) {
      urgencyStatusText = 'Mendekati batas pemakaian';
      urgencyColor = AppColors.warning;
    }

    final costRange = topItem.formattedTotalRange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              urgencyTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
            Text(
              'Rekomendasi Utama',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.secondarySteel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: topItem.isOverdue || topItem.isDueSoon
                  ? urgencyColor.withValues(alpha: 0.4)
                  : AppColors.borderSubtle,
              width: topItem.isOverdue || topItem.isDueSoon ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => MaintenanceDetailBottomSheet.show(
                context,
                prediction: topItem,
                vehicleId: _vehicle.id,
              ),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VehiclePartIconBadge(
                          componentName: topItem.componentName,
                          category: topItem.category,
                          status: topItem.status,
                          healthPercentage: topItem.currentHealth,
                          size: 48,
                          iconSize: 26,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topItem.componentName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                urgencyStatusText,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: urgencyColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                topItem.remainingKm <= 0
                                    ? 'Perkiraan: Lewat jadwal'
                                    : 'Perkiraan: ${DateFormatter.formatKm(topItem.remainingKm.toDouble())} lagi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.secondarySteel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimasi Biaya',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondarySteel,
                          ),
                        ),
                        Text(
                          costRange,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================================================
  // 4. MAINTENANCE SUMMARY ("Ringkasan Perawatan")
  // ==================================================
  Widget _buildMaintenanceSummarySection(AsyncValue<VehicleHealthSummary> healthSummaryAsync) {
    final summary = healthSummaryAsync.value;
    final int attentionCount = (summary?.overdueCount ?? 0) + (summary?.dueSoonCount ?? 0);
    final int goodCount = summary?.goodCount ?? 0;
    const int uninspectedCount = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ringkasan Perawatan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primaryNavy),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Reassuring 3-Column Summary Deck
        Row(
          children: [
            Expanded(
              child: _buildSummaryBadge(
                label: 'Perlu Perhatian',
                count: attentionCount,
                color: attentionCount > 0 ? AppColors.warning : AppColors.secondarySteel,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryBadge(
                label: 'Kondisi Baik',
                count: goodCount,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryBadge(
                label: 'Belum Diperiksa',
                count: uninspectedCount,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryBadge({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.secondarySteel,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==================================================
  // 5. VEHICLE SPECIFICATION (Expandable)
  // ==================================================
  Widget _buildSpecificationSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune_rounded, size: 20, color: AppColors.primaryNavy),
          ),
          title: Text(
            'Spesifikasi Kendaraan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Kapasitas mesin, transmisi, bahan bakar, warna',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.secondarySteel,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _buildSpecRow(
                    icon: Icons.two_wheeler_rounded,
                    label: 'Jenis Kendaraan',
                    value: _vehicle.isMotorcycle ? 'Sepeda Motor' : 'Mobil',
                  ),
                  const Divider(height: 16, color: AppColors.borderSubtle),
                  _buildSpecRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Tahun Pembuatan',
                    value: '${_vehicle.year}',
                  ),
                  const Divider(height: 16, color: AppColors.borderSubtle),
                  _buildSpecRow(
                    icon: Icons.speed_rounded,
                    label: 'Kapasitas Mesin',
                    value: _vehicle.engineCc != null ? '${_vehicle.engineCc} CC' : '-',
                  ),
                  const Divider(height: 16, color: AppColors.borderSubtle),
                  _buildSpecRow(
                    icon: Icons.settings_suggest_rounded,
                    label: 'Transmisi',
                    value: _formatTransmission(_vehicle.transmission),
                  ),
                  const Divider(height: 16, color: AppColors.borderSubtle),
                  _buildSpecRow(
                    icon: Icons.local_gas_station_rounded,
                    label: 'Bahan Bakar',
                    value: _formatFuelType(_vehicle.fuelType),
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
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.secondarySteel,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNavy,
          ),
        ),
      ],
    );
  }

  // ==================================================
  // 6. JOURNEY HISTORY ("Riwayat Perjalanan")
  // ==================================================
  Widget _buildJourneyHistorySection() {
    final allRides = ref.watch(rideHistoryListProvider);
    final vehicleRides = allRides.where((r) => r.vehicleId == _vehicle.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Perjalanan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
            if (vehicleRides.isNotEmpty)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RideHistoryScreen()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Semua',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primaryNavy),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (vehicleRides.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/experience/empty_tracking_stage.svg',
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 14),
                Text(
                  'Belum ada perjalanan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mulai perjalanan untuk melihat riwayat kendaraan.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.secondarySteel,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else ...[
          // Recent ride highlight
          Container(
            padding: const EdgeInsets.all(14),
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
                    color: AppColors.primaryNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.route_rounded, color: AppColors.primaryNavy, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicleRides.length} Sesi Perjalanan Tercatat',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total jarak riwayat tersimpan untuk kendaraan ini.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.secondarySteel,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ==================================================
  // 7. ACTION DESIGN (Contextual Primary CTA)
  // ==================================================
  Widget _buildBottomAction(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddServicePage(vehicle: _vehicle),
            ),
          );
        },
        icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.accentCyan),
        label: Text(
          'Catat Servis Baru',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
