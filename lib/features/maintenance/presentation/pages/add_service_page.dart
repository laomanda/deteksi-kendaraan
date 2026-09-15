import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../vehicle/data/models/vehicle_category_model.dart';
import '../../../vehicle/data/models/vehicle_model.dart';
import '../../../vehicle/providers/vehicle_provider.dart'
    hide maintenanceRepositoryProvider;
import '../../data/models/maintenance_price_model.dart';
import '../../data/models/service_record_model.dart';
import '../../data/models/vehicle_maintenance_model.dart';
import '../../providers/maintenance_intelligence_providers.dart';

/// Formatter otomatis angka ke format rupiah ribuan (misal 80000 -> 80.000)
class CurrencyInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final clean = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final number = int.tryParse(clean);
    if (number == null) return oldValue;
    final newText = _formatter.format(number);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

/// Human-Friendly & Intelligent Add Service Page (Catat Servis)
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

    if (widget.preselectedItem != null) {
      _selectedAction = widget.preselectedItem!.itemName ??
          widget.preselectedItem!.maintenanceId;
      _selectedMaintenanceId = widget.preselectedItem!.maintenanceId;
    } else {
      _selectedAction = 'Oli Mesin';
      _selectedMaintenanceId = null;
    }

    _odometerController = TextEditingController(
      text: widget.vehicle.currentOdometer > 0
          ? widget.vehicle.currentOdometer.toString()
          : '0',
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

  void _selectComponent(VehicleMaintenanceModel item) {
    setState(() {
      _selectedAction = item.itemName ?? item.maintenanceId;
      _selectedMaintenanceId = item.maintenanceId;
    });
  }

  void _applyQuickCost(int amount) {
    final formatted = NumberFormat.decimalPattern('id_ID').format(amount);
    setState(() {
      _costController.text = formatted;
    });
  }

  void _applyQuickWorkshop(String name) {
    setState(() {
      _workshopController.text = name;
    });
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
        maintenanceId: _selectedMaintenanceId ?? 'm-service',
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
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Servis $_selectedAction berhasil dicatat!'),
                ),
              ],
            ),
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

  String _formatCategory(String? catId) {
    if (catId != null) {
      final cat = VehicleCategoryModel.findById(catId);
      if (cat != null) return cat.name;
    }
    return widget.vehicle.isMotorcycle ? 'Motor Matic' : 'Mobil';
  }

  @override
  Widget build(BuildContext context) {
    final vmAsync = ref.watch(vehicleMaintenanceProvider(widget.vehicle.id));
    final repo = ref.read(maintenanceRepositoryProvider);

    // Hitung estimasi harga jika tersedia
    final MaintenancePriceModel? priceEstimate = repo.getEstimatedPrice(
      _selectedAction,
      vehicleType: widget.vehicle.vehicleType,
    );

    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final dateDisplay = DateFormat('dd MMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text(
          'Catat Servis',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: AppColors.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderSubtle, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Sleek Vehicle Summary Card
                _buildVehicleHeaderCard(),

                const SizedBox(height: AppSpacing.space16),

                // 2. Component / Action Selection Section
                _buildComponentSection(vmAsync),

                const SizedBox(height: AppSpacing.space16),

                // 3. Execution Info: Tanggal & Odometer (Side-by-Side)
                _buildExecutionSection(isToday, dateDisplay),

                const SizedBox(height: AppSpacing.space16),

                // 4. Biaya, Bengkel & Catatan
                _buildDetailsSection(priceEstimate),

                const SizedBox(height: AppSpacing.space24),

                // 5. Action Button
                _buildSubmitButton(),

                const SizedBox(height: AppSpacing.space24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleHeaderCard() {
    final isMotor = widget.vehicle.isMotorcycle;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isMotor
                  ? AppColors.primaryBlue.withValues(alpha: 0.1)
                  : AppColors.secondaryTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMotor ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
              color: isMotor ? AppColors.primaryBlue : AppColors.secondaryTeal,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.vehicle.displayName,
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        _formatCategory(widget.vehicle.vehicleCategoryId),
                        style: AppTypography.captionBadge.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (widget.vehicle.licensePlate != null &&
                        widget.vehicle.licensePlate!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '• ${widget.vehicle.licensePlate}',
                        style: AppTypography.captionSubtle.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed_rounded, size: 14, color: AppColors.primaryBlue),
                const SizedBox(width: 4),
                Text(
                  DateFormatter.formatKm(widget.vehicle.currentOdometer.toDouble()),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentSection(AsyncValue<List<VehicleMaintenanceModel>> vmAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build_circle_rounded, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Komponen yang Diservis',
                style: AppTypography.heading3.copyWith(fontSize: 14),
              ),
              const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih komponen yang telah diganti atau dilakukan perawatan',
            style: AppTypography.captionSubtle.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // Quick Recommendation Chips for Overdue / Due Soon items
          vmAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) {
              final priorityItems = items.where((it) => it.isOverdue || it.isDueSoon).toList();
              if (priorityItems.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perlu Servis Segera:',
                    style: AppTypography.captionBadge.copyWith(
                      color: AppColors.healthCritical,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: priorityItems.map((item) {
                        final isSelected = _selectedMaintenanceId == item.maintenanceId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => _selectComponent(item),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (item.isOverdue
                                        ? AppColors.healthCritical.withValues(alpha: 0.15)
                                        : AppColors.healthWarning.withValues(alpha: 0.15))
                                    : AppColors.bgLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? (item.isOverdue ? AppColors.healthCritical : AppColors.healthWarning)
                                      : AppColors.borderSubtle,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.isOverdue
                                        ? Icons.error_rounded
                                        : Icons.warning_amber_rounded,
                                    size: 14,
                                    color: item.isOverdue
                                        ? AppColors.healthCritical
                                        : AppColors.healthWarning,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    item.itemName ?? item.maintenanceId,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected
                                          ? (item.isOverdue
                                              ? AppColors.healthCritical
                                              : AppColors.healthWarning)
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),

          // Main Dropdown Selector
          vmAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => _buildFallbackDropdown(),
            data: (items) {
              if (items.isEmpty) return _buildFallbackDropdown();

              // Pastikan value valid di list
              final bool valueInItems = items.any((it) => it.maintenanceId == _selectedMaintenanceId);
              if (!valueInItems && _selectedMaintenanceId != null) {
                _selectedMaintenanceId = null;
              }
              if (_selectedMaintenanceId == null && items.isNotEmpty) {
                // Auto-pick preselected or first item
                final defaultItem = items.firstWhere(
                  (it) => it.isOverdue,
                  orElse: () => items.first,
                );
                _selectedMaintenanceId = defaultItem.maintenanceId;
                _selectedAction = defaultItem.itemName ?? defaultItem.maintenanceId;
              }

              return DropdownButtonFormField<String>(
                key: ValueKey(_selectedMaintenanceId),
                initialValue: _selectedMaintenanceId,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bgLight,
                  prefixIcon: const Icon(
                    Icons.settings_suggest_rounded,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                items: [
                  ...items.map((it) {
                    final isOverdue = it.isOverdue;
                    final isDueSoon = it.isDueSoon;
                    return DropdownMenuItem<String>(
                      value: it.maintenanceId,
                      child: Row(
                        children: [
                          Icon(
                            isOverdue
                                ? Icons.circle
                                : (isDueSoon ? Icons.circle : Icons.circle_outlined),
                            size: 10,
                            color: isOverdue
                                ? AppColors.healthCritical
                                : (isDueSoon ? AppColors.healthWarning : AppColors.healthOptimal),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              it.itemName ?? it.maintenanceId,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOverdue || isDueSoon) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isOverdue ? AppColors.healthCritical : AppColors.healthWarning)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isOverdue ? 'Lewat' : 'Segera',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isOverdue ? AppColors.healthCritical : AppColors.healthWarning,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  const DropdownMenuItem<String>(
                    value: 'general_service',
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 14, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text('Servis Berkala / Rutin Umum', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedMaintenanceId = val;
                      if (val == 'general_service') {
                        _selectedAction = 'Servis Berkala Rutin';
                      } else {
                        final found = items.where((it) => it.maintenanceId == val).firstOrNull;
                        _selectedAction = found?.itemName ?? val;
                      }
                    });
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackDropdown() {
    const fallbackActions = [
      'Ganti Oli Mesin',
      'Ganti Oli Gardan / Transmisi',
      'Servis Rem & Kampas',
      'Servis CVT / V-Belt',
      'Ganti Busi & Filter',
      'Ganti Ban',
      'Servis Rutin Berkala',
      'Lainnya',
    ];
    return DropdownButtonFormField<String>(
      key: ValueKey(_selectedAction),
      initialValue: fallbackActions.contains(_selectedAction) ? _selectedAction : fallbackActions.first,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.bgLight,
        prefixIcon: const Icon(Icons.settings_suggest_rounded, color: AppColors.primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      items: fallbackActions.map((act) {
        return DropdownMenuItem(value: act, child: Text(act));
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedAction = val;
            _selectedMaintenanceId = null;
          });
        }
      },
    );
  }

  Widget _buildExecutionSection(bool isToday, String dateDisplay) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note_rounded, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Waktu & Jarak Tempuh',
                style: AppTypography.heading3.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Sesuaikan tanggal pengerjaan dan angka odometer saat servis',
            style: AppTypography.captionSubtle.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Tanggal Servis
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanggal Servis',
                      style: AppTypography.captionBadge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.bgLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dateDisplay,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Kilometer Saat Servis
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Kilometer',
                          style: AppTypography.captionBadge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _odometerController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.bgLight,
                        suffixText: 'km',
                        suffixStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        prefixIcon: const Icon(
                          Icons.speed_rounded,
                          size: 16,
                          color: AppColors.primaryBlue,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Harus diisi';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(MaintenancePriceModel? priceEstimate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Rincian Biaya & Bengkel',
                style: AppTypography.heading3.copyWith(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Text(
                '(Opsional)',
                style: AppTypography.captionSubtle.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Biaya Servis
          Text(
            'Biaya Servis',
            style: AppTypography.captionBadge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _costController,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '0 (boleh kosong)',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.normal),
              filled: true,
              fillColor: AppColors.bgLight,
              prefixText: 'Rp ',
              prefixStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.payments_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
            ),
          ),

          // Hint estimasi biaya dari katalog
          if (priceEstimate != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.primaryBlue),
                const SizedBox(width: 4),
                Text(
                  'Perkiraan standar: ${priceEstimate.formattedTotalRange}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
          // Quick amount chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [50000, 100000, 150000, 250000].map((amt) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(
                      'Rp ${amt ~/ 1000} rb',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.bgLight,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    onPressed: () => _applyQuickCost(amt),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // 2. Nama Bengkel
          Text(
            'Nama Bengkel / Lokasi',
            style: AppTypography.captionBadge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _workshopController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Contoh: Bengkel Resmi AHASS / Berdikari Motor',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              filled: true,
              fillColor: AppColors.bgLight,
              prefixIcon: const Icon(
                Icons.storefront_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Quick workshop chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                widget.vehicle.isMotorcycle ? 'Bengkel Resmi (AHASS / Yamaha)' : 'Bengkel Resmi',
                'Bengkel Umum',
                'Servis Sendiri (DIY)',
              ].map((name) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(name, style: const TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.bgLight,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    onPressed: () => _applyQuickWorkshop(name),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // 3. Catatan Tambahan
          Text(
            'Catatan Tambahan',
            style: AppTypography.captionBadge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Tuliskan merk oli, keluhan, garansi, atau catatan penting...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              filled: true,
              fillColor: AppColors.bgLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveService,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.primaryBlue.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Simpan Catatan Servis',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
