import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
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
/// Simple, clear, and elegant initial maintenance condition selector
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
  late InitialConditionOption _selectedOption;
  bool _isSaving = false;

  // For manual input per component (if user chooses manual)
  late final Map<String, TextEditingController> _kmControllers;

  @override
  void initState() {
    super.initState();
    // Intelligent default: if vehicle has mileage, default to automated estimation
    if (widget.currentKilometer > 0) {
      _selectedOption = InitialConditionOption.existingHeuristic;
    } else {
      _selectedOption = InitialConditionOption.brandNew;
    }

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
          // Kondisi A: Kendaraan Baru / Fresh -> 100% health
          lastKm = widget.currentKilometer;
          lastDate = now;
        } else if (_selectedOption == InitialConditionOption.existingHeuristic) {
          // Kondisi B (Heuristic Default): calculate based on current odometer
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
          // Manual input per component
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
    final vehicleTitle = '${widget.brand} ${widget.model}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Subtitle
                  const Text(
                    'Kondisi Servis Awal',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tentukan riwayat awal untuk mulai memantau servis $vehicleTitle.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Option: Estimasi Otomatis (Recommmended if has mileage)
                  if (widget.currentKilometer > 0) ...[
                    _buildOptionTile(
                      option: InitialConditionOption.existingHeuristic,
                      title: 'Estimasi Otomatis',
                      subtitle:
                          'Cocok jika lupa riwayat servis. Sistem memperkirakan waktu servis terdekat dari ${widget.currentKilometer.toInt()} km.',
                      accentColor: const Color(0xFF2563EB),
                      tag: 'Paling Praktis',
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Option: Baru / Fresh
                  _buildOptionTile(
                    option: InitialConditionOption.brandNew,
                    title: widget.currentKilometer == 0
                        ? 'Kendaraan Baru dari Dealer'
                        : 'Baru Saja Servis Total',
                    subtitle: widget.currentKilometer == 0
                        ? 'Semua komponen 100% prima dan mulai dipantau dari nol.'
                        : 'Semua oli dan komponen direset ke 100% prima (baru diganti).',
                    accentColor: const Color(0xFF10B981),
                    tag: widget.currentKilometer == 0 ? 'Paling Pas' : '100% Prima',
                  ),
                  const SizedBox(height: 12),

                  // Option: Catat Manual
                  _buildOptionTile(
                    option: InitialConditionOption.existingManual,
                    title: 'Atur Manual Tiap Komponen',
                    subtitle:
                        'Tentukan sendiri kilometer terakhir saat ganti oli, rem, aki, atau ban.',
                    accentColor: const Color(0xFF8B5CF6),
                    tag: 'Kustom',
                  ),

                  // If manual is selected, show clean component rows
                  if (_selectedOption == InitialConditionOption.existingManual) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Kilometer Terakhir Servis',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Masukkan angka kilometer saat komponen terakhir diganti:',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...ComponentCatalog.getCatalogForVehicleType(widget.vehicleType).map((m) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.displayName,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Interval: ${m.intervalKm > 0 ? "${m.intervalKm} km" : "${m.intervalDays} hari"}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _kmControllers[m.key],
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  suffixText: 'km',
                                  suffixStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 32),

                  // Submit Button
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
                        : const Text(
                            'Selesai & Buka Dashboard',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required InitialConditionOption option,
    required String title,
    required String subtitle,
    required Color accentColor,
    String? tag,
  }) {
    final isSelected = _selectedOption == option;

    return InkWell(
      onTap: () => setState(() => _selectedOption = option),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : accentColor.withValues(alpha: 0.3),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio Indicator
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: isSelected ? accentColor : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? accentColor : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
