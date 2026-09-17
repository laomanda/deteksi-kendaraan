import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../garage/data/models/vehicle_model.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../providers/maintenance_intelligence_providers.dart';
import '../../providers/maintenance_prediction_providers.dart';
import '../controllers/maintenance_status_controller.dart';
import '../widgets/maintenance_card.dart';
import 'service_history_screen.dart';

enum MaintenanceFilter {
  all,
  needsAttention,
  optimal,
}

/// Layar Kesehatan Kendaraan (Maintenance Health)
/// Single Source of Truth: DESIGN.md - Maintenance Intelligence & Personal Vehicle Companion
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

  Future<void> _handleRefresh(String? vehicleId) async {
    if (vehicleId != null) {
      await ref.read(vehicleMaintenanceProvider(vehicleId).notifier).refresh();
      ref.invalidate(maintenancePredictionProvider(vehicleId));
      ref.invalidate(upcomingMaintenanceProvider(vehicleId));
      ref.invalidate(maintenanceHealthProvider(vehicleId));
    }
    ref.invalidate(maintenanceStatusProvider);
  }

  String _getSilhouetteAsset(VehicleModel vehicle) {
    if (!vehicle.isMotorcycle) {
      return 'assets/vehicles/vehicle_silhouette_car.svg';
    }
    final trans = (vehicle.transmission ?? '').toLowerCase();
    if (trans.contains('manual') || trans.contains('kopling') || trans.contains('sport')) {
      return 'assets/vehicles/vehicle_silhouette_manual.svg';
    }
    return 'assets/vehicles/vehicle_silhouette_scooter.svg';
  }

  @override
  Widget build(BuildContext context) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    final maintenanceAsync = ref.watch(maintenanceStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Text(
          'Kesehatan Kendaraan',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.primaryNavy,
          ),
        ),
        actions: [
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedClock01,
              size: 20,
              color: AppColors.primaryNavy,
            ),
            tooltip: 'Riwayat Servis',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServiceHistoryScreen()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: maintenanceAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
            ),
          ),
          error: (err, _) => Center(
            child: Text('Terjadi kendala memuat data: $err'),
          ),
          data: (state) {
            if (activeVehicle == null || state.results.isEmpty) {
              return RefreshIndicator(
                color: AppColors.primaryNavy,
                onRefresh: () => _handleRefresh(activeVehicle?.id),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Text(
                          'Belum ada komponen yang dipantau.',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.secondarySteel,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final results = state.results;
            final overdueCount = results.where((r) => r.isCritical).length;
            final dueSoonCount = results.where((r) => r.isWarning).length;
            final optimalCount = results.where((r) => r.isOptimal || r.isModerate).length;

            final filtered = results.where((res) {
              switch (_filter) {
                case MaintenanceFilter.all:
                  return true;
                case MaintenanceFilter.needsAttention:
                  return res.isWarning || res.isCritical;
                case MaintenanceFilter.optimal:
                  return res.isOptimal || res.isModerate;
              }
            }).toList();

            return RefreshIndicator(
              color: AppColors.primaryNavy,
              onRefresh: () => _handleRefresh(activeVehicle.id),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Vehicle Health Hero Section
                    _buildVehicleHealthHero(
                      context,
                      activeVehicle,
                      results.length,
                      overdueCount,
                      dueSoonCount,
                    ),
                    const SizedBox(height: 14),

                    // 2. Health Summary (3 Status Indicators)
                    _buildHealthSummaryDeck(
                      overdueCount: overdueCount,
                      dueSoonCount: dueSoonCount,
                      optimalCount: optimalCount,
                    ),
                    const SizedBox(height: 14),

                    // 3. Filter Chips Row
                    _buildFilterRow(),
                    const SizedBox(height: 12),

                    // 5. Component List
                    if (filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        alignment: Alignment.center,
                        child: Text(
                          _filter == MaintenanceFilter.needsAttention
                              ? 'Luar biasa! Tidak ada komponen yang membutuhkan perhatian mendesak saat ini.'
                              : 'Tidak ada data komponen untuk filter ini.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.secondarySteel,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final result = filtered[index];
                          return MaintenanceCard(
                            result: result,
                            vehicle: activeVehicle,
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 1. Vehicle Health Hero
  Widget _buildVehicleHealthHero(
    BuildContext context,
    VehicleModel vehicle,
    int totalComponents,
    int overdueCount,
    int dueSoonCount,
  ) {
    final silhouettePath = _getSilhouetteAsset(vehicle);

    final String conditionTitle;
    final Color conditionColor;

    if (overdueCount > 0) {
      conditionTitle = 'Perlu Perawatan Segera';
      conditionColor = AppColors.dangerRed;
    } else if (dueSoonCount > 0) {
      conditionTitle = 'Perlu Perhatian';
      conditionColor = AppColors.warningAmber;
    } else {
      conditionTitle = 'Kondisi Prima';
      conditionColor = AppColors.safeGreen;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08102A43),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: conditionColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: conditionColor.withValues(alpha: 0.25)),
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
                        conditionTitle,
                        style: GoogleFonts.plusJakartaSans(
                          color: conditionColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Vehicle Name
                Text(
                  vehicle.displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Total Odometer in Space Grotesk
                Text(
                  '${DateFormatter.formatKm(vehicle.currentKilometer, includeUnit: false)} KM • $totalComponents Komponen Dipantau',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: AppColors.secondarySteel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Vehicle Silhouette Artwork
          SizedBox(
            width: 80,
            height: 64,
            child: SvgPicture.asset(
              silhouettePath,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Health Summary Deck
  Widget _buildHealthSummaryDeck({
    required int overdueCount,
    required int dueSoonCount,
    required int optimalCount,
  }) {
    return Row(
      children: [
        // Perlu Segera
        Expanded(
          child: _buildSummaryItem(
            count: overdueCount,
            label: 'Perlu Segera',
            color: AppColors.dangerRed,
            bgColor: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFFECACA),
          ),
        ),
        const SizedBox(width: 10),

        // Mendekati Jadwal
        Expanded(
          child: _buildSummaryItem(
            count: dueSoonCount,
            label: 'Mendekati Jadwal',
            color: AppColors.warningAmber,
            bgColor: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
          ),
        ),
        const SizedBox(width: 10),

        // Kondisi Baik
        Expanded(
          child: _buildSummaryItem(
            count: optimalCount,
            label: 'Kondisi Baik',
            color: AppColors.safeGreen,
            bgColor: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFFBBF7D0),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required int count,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 3. Filter Chips Row
  Widget _buildFilterRow() {
    return Row(
      children: [
        _buildFilterChip('Semua Komponen', MaintenanceFilter.all),
        const SizedBox(width: 8),
        _buildFilterChip('Perlu Perhatian', MaintenanceFilter.needsAttention),
        const SizedBox(width: 8),
        _buildFilterChip('Kondisi Baik', MaintenanceFilter.optimal),
      ],
    );
  }

  Widget _buildFilterChip(String label, MaintenanceFilter filter) {
    final isSelected = _filter == filter;

    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.secondarySteel,
          ),
        ),
      ),
    );
  }
}
