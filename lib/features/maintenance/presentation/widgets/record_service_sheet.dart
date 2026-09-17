import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/component_catalog.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../garage/data/models/vehicle_model.dart';
import '../../domain/health_calculation_service.dart';
import '../controllers/maintenance_status_controller.dart';

/// Modal Bottom Sheet for recording maintenance service (DSS Section 8.3 & 10.3)
class RecordServiceSheet extends ConsumerStatefulWidget {
  final ComponentHealthResult? result;
  final VehicleModel vehicle;
  final String? componentType;
  final String? componentName;
  final double? lastServiceKm;
  final double? intervalKm;

  const RecordServiceSheet({
    super.key,
    this.result,
    required this.vehicle,
    this.componentType,
    this.componentName,
    this.lastServiceKm,
    this.intervalKm,
  }) : assert(result != null || componentType != null, 'Either result or componentType must be provided');

  static Future<void> show(
    BuildContext context, {
    ComponentHealthResult? result,
    required VehicleModel vehicle,
    String? componentType,
    String? componentName,
    double? lastServiceKm,
    double? intervalKm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.modalTopRadius,
      ),
      builder: (_) => RecordServiceSheet(
        result: result,
        vehicle: vehicle,
        componentType: componentType,
        componentName: componentName,
        lastServiceKm: lastServiceKm,
        intervalKm: intervalKm,
      ),
    );
  }

  @override
  ConsumerState<RecordServiceSheet> createState() => _RecordServiceSheetState();
}

class _RecordServiceSheetState extends ConsumerState<RecordServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kmController;
  late final TextEditingController _intervalKmController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  bool _isSaving = false;

  String get _effectiveComponentType =>
      widget.componentType ??
      widget.result?.item.componentType ??
      '';

  String get _effectiveComponentName {
    if (widget.componentName != null && widget.componentName!.isNotEmpty) {
      return widget.componentName!;
    }
    final meta = ComponentCatalog.findMetadata(
      widget.vehicle.vehicleType,
      _effectiveComponentType,
    );
    return meta?.displayName ?? _effectiveComponentType;
  }

  double get _effectiveLastServiceKm =>
      widget.lastServiceKm ??
      widget.result?.item.lastServiceKm ??
      0.0;

  bool get _isOilComponent {
    final lowerName = _effectiveComponentName.toLowerCase();
    final lowerType = _effectiveComponentType.toLowerCase();
    return lowerName.contains('oli') ||
        lowerName.contains('oil') ||
        lowerType.contains('oil') ||
        lowerType.contains('oli');
  }

  double get _effectiveIntervalKm {
    if (widget.intervalKm != null && widget.intervalKm! > 0) {
      return widget.intervalKm!;
    }
    if (widget.result?.item.intervalKm != null && widget.result!.item.intervalKm > 0) {
      return widget.result!.item.intervalKm;
    }
    if (_isOilComponent) {
      return 2000.0;
    }
    return 3000.0;
  }

  @override
  void initState() {
    super.initState();
    _kmController = TextEditingController(
      text: widget.vehicle.currentKilometer.toInt().toString(),
    );
    _intervalKmController = TextEditingController(
      text: _effectiveIntervalKm.toInt().toString(),
    );
    _notesController = TextEditingController();
    _selectedDate = DateTime.now();

    _kmController.addListener(_onFieldChanged);
    _intervalKmController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _kmController.removeListener(_onFieldChanged);
    _intervalKmController.removeListener(_onFieldChanged);
    _kmController.dispose();
    _intervalKmController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final componentName = _effectiveComponentName;
    final currentServiceKm = double.tryParse(_kmController.text.trim()) ?? widget.vehicle.currentKilometer;
    final currentInterval = double.tryParse(_intervalKmController.text.trim()) ?? _effectiveIntervalKm;
    final nextTargetKm = currentServiceKm + currentInterval;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.space16,
        right: AppSpacing.space16,
        top: AppSpacing.space16,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.space24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.space16),
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header title
              Text(
                'Catat Servis: $componentName',
                style: AppTypography.heading2,
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Perbarui indikator kesehatan ke 100% dan simpan riwayat pemeliharaan.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.space16),

              // Form Field 1: Service KM
              Text('Kilometer Saat Servis', style: AppTypography.captionBadge),
              const SizedBox(height: AppSpacing.space4),
              TextFormField(
                controller: _kmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Contoh: 15000',
                  suffixText: 'km',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Kilometer wajib diisi';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Masukkan angka kilometer valid';
                  }
                  if (_effectiveLastServiceKm > 0 && parsed < _effectiveLastServiceKm) {
                    return 'Tidak boleh lebih kecil dari servis sebelumnya (${_effectiveLastServiceKm.toInt()} km)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space16),

              // Form Field 2: Custom Oil / Component Lifespan Interval
              Text(
                _isOilComponent
                    ? 'Jangkauan / Daya Tahan Oli (Interval KM)'
                    : 'Interval Jarak Servis Komponen (KM)',
                style: AppTypography.captionBadge,
              ),
              const SizedBox(height: 2),
              Text(
                _isOilComponent
                    ? 'Pilih atau tentukan jarak pemakaian oli yang baru dibeli'
                    : 'Jarak tempuh hingga jadwal penggantian berikutnya',
                style: AppTypography.captionSubtle.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),

              // Quick preset chips (especially for Engine Oil)
              if (_isOilComponent)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [1500, 2000, 2500, 3000, 4000].map((kmVal) {
                      final isSelected = int.tryParse(_intervalKmController.text.trim()) == kmVal;
                      return ChoiceChip(
                        label: Text(
                          '${DateFormatter.formatKm(kmVal.toDouble(), includeUnit: false)} KM',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.primaryNavy,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primaryNavy,
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryNavy : const Color(0xFFE2E8F0),
                          ),
                        ),
                        showCheckmark: false,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _intervalKmController.text = kmVal.toString();
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),

              TextFormField(
                controller: _intervalKmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Contoh: 1500',
                  suffixText: 'km',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Jangkauan interval wajib diisi';
                  }
                  final parsed = int.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Masukkan angka interval valid (min 100 km)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space12),

              // Live Calculation Preview Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.speed_rounded,
                        color: AppColors.primaryNavy,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Servis Berikutnya',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${DateFormatter.formatKm(nextTargetKm, includeUnit: false)} KM (${DateFormatter.formatKm(currentServiceKm, includeUnit: false)} + ${DateFormatter.formatKm(currentInterval, includeUnit: false)})',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space16),

              // Date picker field
              Text('Tanggal Pengerjaan', style: AppTypography.captionBadge),
              const SizedBox(height: AppSpacing.space4),
              InkWell(
                onTap: _pickDate,
                borderRadius: AppSpacing.buttonBorderRadius,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: AppSpacing.buttonBorderRadius,
                    border: Border.all(color: AppColors.borderSubtle, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormatter.formatDate(_selectedDate),
                        style: AppTypography.bodyMedium,
                      ),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space12),

              Text('Catatan Servis / Toko (Opsional)', style: AppTypography.captionBadge),
              const SizedBox(height: AppSpacing.space4),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Misal: Oli Shell Advance AX7 1.500 km di Bengkel',
                ),
              ),
              const SizedBox(height: AppSpacing.space24),

              // Action button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.buttonBorderRadius,
                  ),
                ),
                onPressed: _isSaving ? null : _saveService,
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
                        'Simpan Riwayat Servis',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryNavy,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveService() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final km = double.parse(_kmController.text.trim());
      final interval = int.tryParse(_intervalKmController.text.trim());
      final notes = _notesController.text.trim();

      await ref.read(maintenanceStatusProvider.notifier).recordService(
            componentType: _effectiveComponentType,
            serviceKm: km,
            serviceDate: _selectedDate,
            cost: 0.0,
            notes: notes,
            vehicleId: widget.vehicle.id,
            customIntervalKm: interval,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Servis berhasil dicatat! Status indikator diperbarui.',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.healthOptimal,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
