import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/component_catalog.dart';
import '../../../garage/data/models/vehicle_model.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../maintenance/data/models/maintenance_item_model.dart';
import '../../../maintenance/domain/health_calculation_service.dart';
import '../../../navigation/main_navigation_screen.dart';
import '../../../shared/providers/repository_providers.dart';

enum InitialConditionOption {
  brandNew,
  existingHeuristic,
  existingManual,
}

/// Initial Condition Setup Screen (PRD Section 7.2 & DSS Section 10.1)
class InitialConditionSetupScreen extends ConsumerStatefulWidget {
  final String vehicleType;
  final String brand;
  final String model;
  final int year;
  final double currentKilometer;
  final String? photoPath;

  const InitialConditionSetupScreen({
    super.key,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.year,
    required this.currentKilometer,
    this.photoPath,
  });

  @override
  ConsumerState<InitialConditionSetupScreen> createState() =>
      _InitialConditionSetupScreenState();
}

class _InitialConditionSetupScreenState
    extends ConsumerState<InitialConditionSetupScreen> {
  InitialConditionOption _selectedOption = InitialConditionOption.brandNew;
  bool _isSaving = false;

  // For manual input per component (if user chooses manual)
  late final Map<String, TextEditingController> _kmControllers;

  @override
  void initState() {
    super.initState();
    final catalog = ComponentCatalog.getCatalogForVehicleType(widget.vehicleType);
    _kmControllers = {
      for (final comp in catalog)
        comp.key: TextEditingController(
          text: comp.intervalKm > 0
              ? (widget.currentKilometer - (0.75 * comp.intervalKm))
                  .clamp(0.0, widget.currentKilometer)
                  .toInt()
                  .toString()
              : '0',
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _kmControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _completeSetup() async {
    setState(() => _isSaving = true);
    try {
      const uuid = Uuid();
      final vehicleId = uuid.v4();

      final vehicle = VehicleModel(
        id: vehicleId,
        vehicleType: widget.vehicleType,
        brand: widget.brand,
        model: widget.model,
        year: widget.year,
        currentKilometer: widget.currentKilometer,
        photoPath: widget.photoPath,
        createdAt: DateTime.now(),
      );

      final catalog = ComponentCatalog.getCatalogForVehicleType(widget.vehicleType);
      final now = DateTime.now();

      final List<MaintenanceItemModel> items = [];

      for (final meta in catalog) {
        double lastKm;
        DateTime lastDate;

        if (_selectedOption == InitialConditionOption.brandNew) {
          // Kondisi A: Kendaraan Baru -> 100% health
          lastKm = widget.currentKilometer;
          lastDate = now;
        } else if (_selectedOption == InitialConditionOption.existingHeuristic) {
          // Kondisi B (Heuristic Default): 25% warning level
          final heuristic =
              HealthCalculationService.calculateUnknownHistoryInitialCondition(
            currentOdometer: widget.currentKilometer,
            intervalKm: meta.intervalKm,
            intervalDays: meta.intervalDays,
            now: now,
          );
          lastKm = heuristic.lastServiceKm;
          lastDate = heuristic.lastServiceDate;
        } else {
          // Manual input
          final inputVal = double.tryParse(_kmControllers[meta.key]?.text ?? '');
          lastKm = inputVal ??
              (widget.currentKilometer - (0.75 * meta.intervalKm))
                  .clamp(0.0, widget.currentKilometer);
          lastDate = now.subtract(Duration(days: (meta.intervalDays * 0.75).round()));
        }

        items.add(
          MaintenanceItemModel(
            id: uuid.v4(),
            vehicleId: vehicleId,
            componentType: meta.key,
            intervalKm: meta.intervalKm,
            intervalDays: meta.intervalDays,
            lastServiceKm: lastKm,
            lastServiceDate: lastDate,
          ),
        );
      }

      // Save vehicle & maintenance items
      final vehicleRepo = ref.read(vehicleRepositoryProvider);
      final maintenanceRepo = ref.read(maintenanceRepositoryProvider);

      await vehicleRepo.saveVehicle(vehicle);
      await maintenanceRepo.saveItems(items);
      await ref.read(activeVehicleProvider.notifier).setActiveVehicle(vehicleId);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: AppBar(
        title: Text('Kondisi Awal Komponen', style: AppTypography.heading2),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kondisi Awal Servis',
                style: AppTypography.heading1,
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Pilih status awal untuk memulai pemantauan komponen.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.space24),

              // Option A: Brand New Vehicle
              _buildOptionCard(
                option: InitialConditionOption.brandNew,
                title: 'Kendaraan Baru',
                subtitle:
                    'Semua komponen 100% prima, baru dari dealer atau baru servis besar.',
                badge: '100% Prima',
                badgeColor: AppColors.healthOptimal,
              ),
              const SizedBox(height: AppSpacing.space16),

              // Option B: Existing Vehicle (Heuristic Default)
              _buildOptionCard(
                option: InitialConditionOption.existingHeuristic,
                title: 'Estimasi Otomatis',
                subtitle:
                    'Riwayat servis belum dicatat. Sistem akan mulai memantau komponen Anda.',
                badge: 'Rekomendasi',
                badgeColor: AppColors.healthWarning,
              ),
              const SizedBox(height: AppSpacing.space16),

              // Option C: Manual Entry per component
              _buildOptionCard(
                option: InitialConditionOption.existingManual,
                title: 'Catat Manual',
                subtitle:
                    'Tentukan kilometer terakhir servis masing-masing komponen.',
                badge: 'Manual',
                badgeColor: AppColors.primaryBlue,
              ),

              // If manual selected, show input fields
              if (_selectedOption == InitialConditionOption.existingManual) ...[
                const SizedBox(height: AppSpacing.space24),
                Text('Kilometer Servis Terakhir', style: AppTypography.heading3),
                const SizedBox(height: AppSpacing.space8),
                ...ComponentCatalog.getCatalogForVehicleType(widget.vehicleType).map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.space12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(m.displayName, style: AppTypography.bodyMedium),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _kmControllers[m.key],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              suffixText: 'km',
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: AppSpacing.space32),

              // Finalize button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.buttonBorderRadius,
                  ),
                ),
                onPressed: _isSaving ? null : _completeSetup,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Selesai & Buka Dashboard',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.space16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required InitialConditionOption option,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
  }) {
    final isSelected = _selectedOption == option;
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = option),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceWhite : AppColors.surfaceSubtle,
          borderRadius: AppSpacing.cardBorderRadius,
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.heading3.copyWith(
                      color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: AppSpacing.chipBorderRadius,
                  ),
                  child: Text(
                    badge,
                    style: AppTypography.captionBadge.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
