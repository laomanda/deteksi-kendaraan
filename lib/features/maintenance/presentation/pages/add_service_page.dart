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

/// Simplified Human-Friendly Add Service Page
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

  // 5 Simplified User-Friendly Service Categories
  static const List<String> _serviceActions = [
    'Ganti Oli',
    'Ganti Ban',
    'Servis Rem',
    'Servis Mesin',
    'Lainnya',
  ];

  late String _selectedAction;
  String? _selectedMaintenanceId;
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

    // Map preselected item to a friendly action if coming from item detail
    _selectedAction = _resolveActionFromPreselected(widget.preselectedItem);

    if (widget.preselectedItem != null) {
      _selectedMaintenanceId = widget.preselectedItem!.maintenanceId;
    }

    // Auto-fill odometer with vehicle's current odometer
    _odometerController = TextEditingController(
      text: widget.vehicle.currentOdometer > 0
          ? widget.vehicle.currentOdometer.toString()
          : '0',
    );
    _costController = TextEditingController();
    _workshopController = TextEditingController();
    _notesController = TextEditingController();
  }

  String _resolveActionFromPreselected(VehicleMaintenanceModel? item) {
    if (item == null) return 'Ganti Oli';
    final name = (item.itemName ?? item.maintenanceId).toLowerCase();
    if (name.contains('oli') || name.contains('oil')) return 'Ganti Oli';
    if (name.contains('ban') || name.contains('tire')) return 'Ganti Ban';
    if (name.contains('rem') || name.contains('brake')) return 'Servis Rem';
    if (name.contains('mesin') ||
        name.contains('busi') ||
        name.contains('filter') ||
        name.contains('spark') ||
        name.contains('cvt') ||
        name.contains('rantai')) {
      return 'Servis Mesin';
    }
    return 'Lainnya';
  }

  void _mapActionToMaintenanceItem(List<VehicleMaintenanceModel> items) {
    if (items.isEmpty) return;

    // If preselected matches current action, keep it
    if (widget.preselectedItem != null &&
        _selectedAction == _resolveActionFromPreselected(widget.preselectedItem)) {
      _selectedMaintenanceId = widget.preselectedItem!.maintenanceId;
      return;
    }

    VehicleMaintenanceModel? matched;
    switch (_selectedAction) {
      case 'Ganti Oli':
        matched = items.where((it) {
          final n = (it.itemName ?? it.maintenanceId).toLowerCase();
          return n.contains('oli') || n.contains('oil');
        }).firstOrNull;
        break;
      case 'Ganti Ban':
        matched = items.where((it) {
          final n = (it.itemName ?? it.maintenanceId).toLowerCase();
          return n.contains('ban') || n.contains('tire');
        }).firstOrNull;
        break;
      case 'Servis Rem':
        matched = items.where((it) {
          final n = (it.itemName ?? it.maintenanceId).toLowerCase();
          return n.contains('rem') || n.contains('brake');
        }).firstOrNull;
        break;
      case 'Servis Mesin':
        matched = items.where((it) {
          final n = (it.itemName ?? it.maintenanceId).toLowerCase();
          return n.contains('mesin') ||
              n.contains('busi') ||
              n.contains('filter') ||
              n.contains('cvt');
        }).firstOrNull;
        break;
      case 'Lainnya':
      default:
        matched = items.first;
        break;
    }

    final target = matched ?? items.first;
    _selectedMaintenanceId = target.maintenanceId;
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

    setState(() => _isSaving = true);

    try {
      final odo = int.tryParse(_odometerController.text.trim()) ??
          widget.vehicle.currentOdometer;
      final rawCost =
          _costController.text.replaceAll('.', '').replaceAll(',', '').trim();
      final cost = double.tryParse(rawCost) ?? 0.0;
      final workshop = _workshopController.text.trim();
      final notes = _notesController.text.trim();

      const uuid = Uuid();
      final record = ServiceRecordModel(
        id: uuid.v4(),
        vehicleId: widget.vehicle.id,
        maintenanceId: _selectedMaintenanceId ?? 'm-oil',
        serviceDate: _selectedDate,
        odometer: odo,
        cost: cost,
        workshop: workshop.isNotEmpty ? workshop : null,
        notes: notes.isNotEmpty ? notes : null,
        maintenanceName: _selectedAction,
      );

      // 1. Simpan riwayat servis via Provider
      await ref
          .read(serviceRecordsProvider(widget.vehicle.id).notifier)
          .addRecord(record);

      // 2. Perbarui odometer jika servis lebih tinggi dari odometer sekarang
      if (odo > widget.vehicle.currentOdometer) {
        final vehicleRepo = ref.read(vehicleRepositoryProvider);
        await vehicleRepo.updateOdometer(widget.vehicle.id, odo.toDouble());
        ref.read(vehicleListProvider.notifier).refresh();
      }

      // 3. Refresh status maintenance
      await ref
          .read(vehicleMaintenanceProvider(widget.vehicle.id).notifier)
          .refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.successGreen,
            content: Text('Servis $_selectedAction berhasil dicatat!'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Gagal mencatat servis: $e'),
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

    // Map selected action to real catalog items when available
    vmAsync.whenData((items) {
      if (_selectedMaintenanceId == null) {
        _mapActionToMaintenanceItem(items);
      }
    });

    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final dateDisplay = isToday
        ? 'Hari ini (${DateFormat('d MMM yyyy').format(_selectedDate)})'
        : DateFormat('d MMMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Catat Servis'),
        elevation: 0,
        backgroundColor: AppColors.surfaceWhite,
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
                  padding: const EdgeInsets.all(AppSpacing.space12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: AppSpacing.cardBorderRadius,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.vehicle.isMotorcycle
                              ? Icons.two_wheeler_rounded
                              : Icons.directions_car_rounded,
                          color: AppColors.primaryBlue,
                          size: 20,
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
                              'Total Jarak: ${NumberFormat.decimalPattern('id_ID').format(widget.vehicle.currentOdometer)} KM',
                              style: AppTypography.captionSubtle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.space16),

                // 1. APA YANG DILAKUKAN? (WAJIB)
                Text(
                  'Apa yang dilakukan? *',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedAction,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceWhite,
                    prefixIcon: const Icon(
                      Icons.build_circle_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.cardBorderRadius,
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  items: _serviceActions.map((action) {
                    return DropdownMenuItem<String>(
                      value: action,
                      child: Text(action, style: AppTypography.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedAction = val;
                      });
                      vmAsync.whenData((items) {
                        _mapActionToMaintenanceItem(items);
                      });
                    }
                  },
                ),

                const SizedBox(height: AppSpacing.space16),

                // 2. TANGGAL (Otomatis hari ini)
                Text(
                  'Tanggal Servis',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: AppSpacing.cardBorderRadius,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: AppSpacing.cardBorderRadius,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.space12),
                        Text(dateDisplay, style: AppTypography.bodyMedium),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.space16),

                // 3. KILOMETER KENDARAAN (Otomatis terisi dari kendaraan)
                Text(
                  'Kilometer Kendaraan Saat Ini (KM) *',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                TextFormField(
                  controller: _odometerController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceWhite,
                    suffixText: 'KM',
                    prefixIcon: const Icon(
                      Icons.speed_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.cardBorderRadius,
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Kilometer harus diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.space16),

                // 4. BIAYA (OPSIONAL)
                Text(
                  'Biaya Servis (Opsional)',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                TextFormField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Contoh: 80.000 (boleh kosong)',
                    filled: true,
                    fillColor: AppColors.surfaceWhite,
                    prefixText: 'Rp ',
                    prefixIcon: const Icon(
                      Icons.payments_outlined,
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.cardBorderRadius,
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.space16),

                // 5. BENGKEL (OPSIONAL)
                Text(
                  'Nama Bengkel (Opsional)',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                TextFormField(
                  controller: _workshopController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Bengkel Resmi AHASS / Berdikari',
                    filled: true,
                    fillColor: AppColors.surfaceWhite,
                    prefixIcon: const Icon(
                      Icons.storefront_outlined,
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.cardBorderRadius,
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.space16),

                // 6. CATATAN (OPSIONAL)
                Text(
                  'Catatan (Opsional)',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Tambahkan catatan jika ada...',
                    filled: true,
                    fillColor: AppColors.surfaceWhite,
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.cardBorderRadius,
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.space24),

                // Tombol Simpan Servis
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.buttonBorderRadius,
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Simpan Servis',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
