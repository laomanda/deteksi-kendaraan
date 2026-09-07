import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../vehicle/data/models/vehicle_model.dart';
import '../../../vehicle/providers/vehicle_provider.dart';
import '../../data/models/service_record_model.dart';
import '../../data/models/vehicle_maintenance_model.dart';
import '../../providers/maintenance_intelligence_providers.dart';

/// Halaman Form Tambah Catatan Servis (Add Service Page)
class AddServicePage extends ConsumerStatefulWidget {
  final VehicleModel vehicle;
  final VehicleMaintenanceModel? preselectedItem;

  const AddServicePage({
    super.key,
    required this.vehicle,
    this.preselectedItem,
  });

  @override
  ConsumerState<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends ConsumerState<AddServicePage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedMaintenanceId;
  String? _selectedMaintenanceName;
  late DateTime _selectedDate;
  late TextEditingController _odometerController;
  late TextEditingController _costController;
  late TextEditingController _workshopController;
  late TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    if (widget.preselectedItem != null) {
      _selectedMaintenanceId = widget.preselectedItem!.maintenanceId;
      _selectedMaintenanceName = widget.preselectedItem!.itemName ?? widget.preselectedItem!.maintenanceId;
    }

    _odometerController = TextEditingController(
      text: widget.vehicle.currentOdometer > 0 ? widget.vehicle.currentOdometer.toString() : '',
    );
    _costController = TextEditingController();
    _workshopController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _costController.dispose();
    _workshopController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2010),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMaintenanceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih komponen / jenis servis')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final odo = int.parse(_odometerController.text.trim());
      final rawCost = _costController.text.replaceAll('.', '').replaceAll(',', '').trim();
      final cost = double.tryParse(rawCost) ?? 0.0;
      final workshop = _workshopController.text.trim();
      final notes = _notesController.text.trim();

      const uuid = Uuid();
      final record = ServiceRecordModel(
        id: uuid.v4(),
        vehicleId: widget.vehicle.id,
        maintenanceId: _selectedMaintenanceId,
        serviceDate: _selectedDate,
        odometer: odo,
        cost: cost,
        workshop: workshop.isNotEmpty ? workshop : null,
        notes: notes.isNotEmpty ? notes : null,
        maintenanceName: _selectedMaintenanceName,
      );

      // 1. Simpan record via Provider / Repository
      await ref.read(serviceRecordsProvider(widget.vehicle.id).notifier).addRecord(record);

      // 2. Jika odometer servis lebih tinggi dari current odometer kendaraan, perbarui odometer kendaraan
      if (odo > widget.vehicle.currentOdometer) {
        final vehicleRepo = ref.read(vehicleRepositoryProvider);
        await vehicleRepo.updateOdometer(widget.vehicle.id, odo.toDouble());
        ref.read(vehicleListProvider.notifier).refresh();
      }

      // 3. Refresh vehicle maintenance state agar health kembali 100%
      await ref.read(vehicleMaintenanceProvider(widget.vehicle.id).notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.successGreen,
            content: Text('Servis $_selectedMaintenanceName berhasil disimpan!'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Gagal menyimpan servis: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vmAsync = ref.watch(vehicleMaintenanceProvider(widget.vehicle.id));

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Tambah Catatan Servis'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner Kendaraan
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: AppSpacing.cardBorderRadius,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.vehicle.isMotorcycle
                              ? Icons.two_wheeler_rounded
                              : Icons.directions_car_rounded,
                          color: AppColors.primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.vehicle.displayName,
                              style: AppTypography.heading3,
                            ),
                            Text(
                              'Odometer Saat Ini: ${NumberFormat.decimalPattern('id_ID').format(widget.vehicle.currentOdometer)} KM',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),

                // 1. Pilih Komponen / Maintenance Item
                Text('Pilih Komponen Maintenance *', style: AppTypography.bodyMedium),
                const SizedBox(height: AppSpacing.space8),
                vmAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Gagal memuat komponen: $e'),
                  data: (items) {
                    // Set default jika belum ada yang terpilih
                    if (_selectedMaintenanceId == null && items.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _selectedMaintenanceId = items.first.maintenanceId;
                            _selectedMaintenanceName = items.first.itemName ?? items.first.maintenanceId;
                          });
                        }
                      });
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedMaintenanceId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceWhite,
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.cardBorderRadius,
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        prefixIcon: const Icon(Icons.build_circle_outlined, color: AppColors.primaryBlue),
                      ),
                      items: items.map((item) {
                        return DropdownMenuItem<String>(
                          value: item.maintenanceId,
                          child: Text(item.itemName ?? item.maintenanceId),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final matched = items.where((it) => it.maintenanceId == val).firstOrNull;
                          setState(() {
                            _selectedMaintenanceId = val;
                            _selectedMaintenanceName = matched?.itemName ?? val;
                          });
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.space16),

                // 2. Tanggal Servis
                Text('Tanggal Servis *', style: AppTypography.bodyMedium),
                const SizedBox(height: AppSpacing.space8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: AppSpacing.cardBorderRadius,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: AppSpacing.cardBorderRadius,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: AppColors.primaryBlue, size: 20),
                        const SizedBox(width: AppSpacing.space12),
                        Text(
                          DateFormat('dd MMMM yyyy').format(_selectedDate),
                          style: AppTypography.bodyMedium,
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),

                // 3. Odometer Saat Servis
                Text('Odometer Saat Servis (KM) *', style: AppTypography.bodyMedium),
                const SizedBox(height: AppSpacing.space8),
                TextFormField(
                  controller: _odometerController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Contoh: 12500',
                    filled: true,
                    fillColor: AppColors.surfaceWhite,
                    suffixText: 'KM',
                    prefixIcon: const Icon(Icons.speed_rounded, color: AppColors.primaryBlue),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.cardBorderRadius,
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Odometer harus diisi';
                    }
                    if (int.tryParse(val.trim()) == null) {
                      return 'Masukkan angka odometer yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.space16),

                // 4. Biaya Aktual (Cost)
                Text('Biaya Aktual (Rp) *', style: AppTypography.bodyMedium),
                const SizedBox(height: AppSpacing.space8),
                TextFormField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Contoh: 80000',
                    filled: true,
                    fillColor: AppColors.surfaceWhite,
                    prefixText: 'Rp ',
                    prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.primaryBlue),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.cardBorderRadius,
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Biaya servis harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.space16),

                // 5. Nama Bengkel / Workshop
                Text('Bengkel / Lokasi Servis', style: AppTypography.bodyMedium),
                const SizedBox(height: AppSpacing.space8),
                TextFormField(
                  controller: _workshopController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: AHASS / Bengkel Resmi / Mandiri',
                    filled: true,
                    fillColor: AppColors.surfaceWhite,
                    prefixIcon: const Icon(Icons.storefront_rounded, color: AppColors.primaryBlue),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.cardBorderRadius,
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),

                // 6. Catatan (Notes)
                Text('Catatan Tambahan', style: AppTypography.bodyMedium),
                const SizedBox(height: AppSpacing.space8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Ganti oli merk MPX2 0.8L + pembersihan filter',
                    filled: true,
                    fillColor: AppColors.surfaceWhite,
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.cardBorderRadius,
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.buttonBorderRadius,
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Save Service',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
