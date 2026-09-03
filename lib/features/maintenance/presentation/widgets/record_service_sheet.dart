import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final ComponentHealthResult result;
  final VehicleModel vehicle;

  const RecordServiceSheet({
    super.key,
    required this.result,
    required this.vehicle,
  });

  static Future<void> show(
    BuildContext context, {
    required ComponentHealthResult result,
    required VehicleModel vehicle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.modalTopRadius,
      ),
      builder: (_) => RecordServiceSheet(result: result, vehicle: vehicle),
    );
  }

  @override
  ConsumerState<RecordServiceSheet> createState() => _RecordServiceSheetState();
}

class _RecordServiceSheetState extends ConsumerState<RecordServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kmController;
  late final TextEditingController _costController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _kmController = TextEditingController(
      text: widget.vehicle.currentKilometer.toInt().toString(),
    );
    _costController = TextEditingController();
    _notesController = TextEditingController();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _kmController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = ComponentCatalog.findMetadata(
      widget.vehicle.vehicleType,
      widget.result.item.componentType,
    );
    final componentName = meta?.displayName ?? widget.result.item.componentType;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.space16,
        right: AppSpacing.space16,
        top: AppSpacing.space16,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.space24,
      ),
      child: Form(
        key: _formKey,
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

            // Form Field: Service KM
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
                if (parsed < widget.result.item.lastServiceKm) {
                  return 'Tidak boleh lebih kecil dari servis sebelumnya (${widget.result.item.lastServiceKm.toInt()} km)';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.space12),

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

            // Cost & Notes
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Biaya (Opsional)', style: AppTypography.captionBadge),
                      const SizedBox(height: AppSpacing.space4),
                      TextFormField(
                        controller: _costController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0',
                          prefixText: 'Rp ',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space12),

            Text('Catatan Servis / Toko (Opsional)', style: AppTypography.captionBadge),
            const SizedBox(height: AppSpacing.space4),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Misal: Oli Shell Advance AX7 di Bengkel Resmi',
              ),
            ),
            const SizedBox(height: AppSpacing.space24),

            // Action button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
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
              primary: AppColors.primaryBlue,
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
      final cost = double.tryParse(_costController.text.trim()) ?? 0.0;
      final notes = _notesController.text.trim();

      await ref.read(maintenanceStatusProvider.notifier).recordService(
            componentType: widget.result.item.componentType,
            serviceKm: km,
            serviceDate: _selectedDate,
            cost: cost,
            notes: notes,
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
