import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../garage/data/models/vehicle_model.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../navigation/main_navigation_screen.dart';
import '../../../shared/providers/repository_providers.dart';

/// Initial Condition Setup Screen (PRD Section 7.2 & DSS Section 10.1)
/// Simple, clear, and elegant initial maintenance condition selector
class InitialConditionSetupScreen extends ConsumerStatefulWidget {
  final String vehicleType;
  final String brand;
  final String model;
  final int year;
  final double currentKilometer;
  final String? photoPath;
  final String? variant;
  final String? licensePlate;
  final int? engineCc;
  final String? color;
  final String? transmission;
  final String? fuelType;
  final String? vehicleCategoryId;

  const InitialConditionSetupScreen({
    super.key,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.year,
    required this.currentKilometer,
    this.photoPath,
    this.variant,
    this.licensePlate,
    this.engineCc,
    this.color,
    this.transmission,
    this.fuelType,
    this.vehicleCategoryId,
  });

  @override
  ConsumerState<InitialConditionSetupScreen> createState() =>
      _InitialConditionSetupScreenState();
}

class _InitialConditionSetupScreenState
    extends ConsumerState<InitialConditionSetupScreen> {
  late VehicleInitialCondition _selectedOption;
  late final TextEditingController _lastServiceKmController;
  DateTime? _lastServiceDate;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedOption = VehicleInitialCondition.autoPrediction;
    _lastServiceKmController = TextEditingController();
  }

  @override
  void dispose() {
    _lastServiceKmController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (_selectedOption == VehicleInitialCondition.serviceHistory &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      const uuid = Uuid();
      final vehicleId = uuid.v4();

      final vehicle = VehicleModel(
        id: vehicleId,
        vehicleType: widget.vehicleType,
        brand: widget.brand,
        model: widget.model,
        variant: widget.variant,
        year: widget.year,
        licensePlate: widget.licensePlate,
        engineCc: widget.engineCc,
        color: widget.color,
        transmission: widget.transmission,
        fuelType: widget.fuelType,
        vehicleCategoryId: widget.vehicleCategoryId,
        initialOdometer: widget.currentKilometer.round(),
        currentOdometer: widget.currentKilometer.round(),
        currentKilometer: widget.currentKilometer,
        photoPath: widget.photoPath,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        initialCondition: _selectedOption.name,
      );

      final vehicleRepo = ref.read(vehicleRepositoryProvider);
      final maintenanceRepo = ref.read(maintenanceRepositoryProvider);

      await vehicleRepo.saveVehicle(vehicle);

      final lastKm = int.tryParse(_lastServiceKmController.text.trim());
      await maintenanceRepo.initializeVehicleMaintenance(
        vehicle: vehicle,
        initialCondition: _selectedOption,
        lastServiceOdometer: lastKm,
        lastServiceDate: _lastServiceDate,
      );

      await ref.read(activeVehicleProvider.notifier).setActiveVehicle(vehicleId);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error in _completeSetup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleTitle = '${widget.brand} ${widget.model}';
    final currentKmInt = widget.currentKilometer.toInt();

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
              child: Form(
                key: _formKey,
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
                      'Tentukan riwayat awal untuk mulai memantau servis $vehicleTitle tanpa membuat status langsung terlambat.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Option 1: Prediksi Otomatis
                    _buildOptionTile(
                      option: VehicleInitialCondition.autoPrediction,
                      title: 'Prediksi Otomatis',
                      subtitle:
                          'Kendaraan dianggap sehat. Tracking dimulai dari KM saat ini ($currentKmInt km) dengan kondisi prima 100%.',
                      accentColor: const Color(0xFF2563EB),
                      tag: 'Rekomendasi',
                    ),
                    const SizedBox(height: 12),

                    // Option 2: Input Riwayat Servis
                    _buildOptionTile(
                      option: VehicleInitialCondition.serviceHistory,
                      title: 'Input Riwayat Servis',
                      subtitle:
                          'Masukkan angka kilometer saat servis terakhir untuk kalkulasi jadwal yang sesuai histori riil.',
                      accentColor: const Color(0xFF8B5CF6),
                      tag: 'Histori Riil',
                    ),
                    if (_selectedOption == VehicleInitialCondition.serviceHistory) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DETAIL SERVIS TERAKHIR',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8B5CF6),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _lastServiceKmController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                labelText: 'Kilometer Servis Terakhir',
                                hintText: 'Contoh: ${currentKmInt > 3000 ? currentKmInt - 2000 : 0}',
                                suffixText: 'KM',
                                prefixIcon: const Icon(Icons.speed_rounded, size: 20, color: Color(0xFF8B5CF6)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (val) {
                                if (_selectedOption == VehicleInitialCondition.serviceHistory) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Masukkan kilometer servis terakhir';
                                  }
                                  final numVal = int.tryParse(val.trim());
                                  if (numVal == null || numVal < 0) {
                                    return 'Kilometer servis tidak valid';
                                  }
                                  if (numVal > currentKmInt) {
                                    return 'KM servis tidak boleh melebihi KM saat ini ($currentKmInt KM)';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _lastServiceDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _lastServiceDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF8B5CF6)),
                                    const SizedBox(width: 8),
                                    Text(
                                      _lastServiceDate != null
                                          ? 'Tanggal: ${_lastServiceDate!.day}/${_lastServiceDate!.month}/${_lastServiceDate!.year}'
                                          : 'Pilih Tanggal Servis (Opsional)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _lastServiceDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Option 3: Semua Komponen Kondisi Baik
                    _buildOptionTile(
                      option: VehicleInitialCondition.allGood,
                      title: 'Semua Komponen Kondisi Baik',
                      subtitle:
                          'Semua komponen dalam kondisi prima (100%). Baseline servis dicatat di $currentKmInt km.',
                      accentColor: const Color(0xFF10B981),
                      tag: '100% Prima',
                    ),

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
      ),
    );
  }

  Widget _buildOptionTile({
    required VehicleInitialCondition option,
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
