import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/vehicle_model.dart';
import '../../domain/vehicle_intelligence_service.dart';
import '../../providers/vehicle_provider.dart';

/// Page to add a new vehicle or edit an existing vehicle
class AddVehiclePage extends ConsumerStatefulWidget {
  final VehicleModel? vehicleToEdit;

  const AddVehiclePage({super.key, this.vehicleToEdit});

  @override
  ConsumerState<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends ConsumerState<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _variantController;
  int? _selectedYear;
  final List<int> _availableYears = List.generate(
    DateTime.now().year - 1980 + 1,
    (index) => DateTime.now().year - index,
  );
  late final TextEditingController _engineCcController;
  late final TextEditingController _licensePlateController;
  late final TextEditingController _odometerController;
  late final TextEditingController _colorController;

  late String _selectedVehicleType;
  late String _selectedCategory;
  String? _selectedTransmission;
  String? _selectedFuelType;

  bool _isLoading = false;

  bool get _isEditing => widget.vehicleToEdit != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicleToEdit;

    _brandController = TextEditingController(text: v?.brand ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');
    _variantController = TextEditingController(text: v?.variant ?? '');
    _selectedYear = v?.year;
    _engineCcController = TextEditingController(text: v?.engineCc != null ? v!.engineCc.toString() : '');
    _licensePlateController = TextEditingController(text: v?.licensePlate ?? '');
    _odometerController = TextEditingController(text: v != null ? v.currentOdometer.toString() : '0');
    _colorController = TextEditingController(text: v?.color ?? '');

    _selectedVehicleType = v?.vehicleType.toLowerCase() == 'car' ? 'car' : 'motorcycle';
    final initialCategory = v?.vehicleCategoryId ??
        (v != null
            ? VehicleIntelligenceService.resolveCategoryId(v)
            : (_selectedVehicleType == 'car' ? 'car_automatic' : 'scooter_cvt'));
    _selectedCategory = initialCategory;
    _selectedTransmission = v?.transmission ?? 'Automatic';
    _selectedFuelType = v?.fuelType ?? 'Gasoline';
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _engineCcController.dispose();
    _licensePlateController.dispose();
    _odometerController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  bool get _isTransmissionLocked => _selectedCategory != 'car_diesel';

  List<String> get _allowedTransmissions {
    if (_selectedCategory == 'scooter_cvt' ||
        _selectedCategory == 'car_automatic' ||
        _selectedCategory == 'car_hybrid') {
      return const ['Automatic'];
    } else if (_selectedCategory == 'motorcycle_manual' ||
        _selectedCategory == 'sport_motorcycle' ||
        _selectedCategory == 'car_manual') {
      return const ['Manual'];
    } else {
      return const ['Automatic', 'Manual'];
    }
  }

  String? get _transmissionHelperText {
    if (_selectedCategory == 'scooter_cvt') {
      return 'Sesuai Tipe Motor Matic';
    } else if (_selectedCategory == 'car_automatic') {
      return 'Sesuai Tipe Mobil Matic';
    } else if (_selectedCategory == 'car_hybrid') {
      return 'Sesuai Tipe Mobil Hybrid';
    } else if (_selectedCategory == 'motorcycle_manual' || _selectedCategory == 'sport_motorcycle') {
      return 'Sesuai Tipe Motor Manual';
    } else if (_selectedCategory == 'car_manual') {
      return 'Sesuai Tipe Mobil Manual';
    }
    return null;
  }

  bool get _isFuelTypeLocked =>
      _selectedVehicleType == 'motorcycle' ||
      _selectedCategory == 'car_diesel' ||
      _selectedCategory == 'car_hybrid';

  List<String> get _allowedFuelTypes {
    if (_selectedVehicleType == 'motorcycle') {
      return const ['Gasoline'];
    } else if (_selectedCategory == 'car_diesel') {
      return const ['Diesel'];
    } else if (_selectedCategory == 'car_hybrid') {
      return const ['Hybrid'];
    } else {
      return const ['Gasoline', 'Electric'];
    }
  }

  String? get _fuelTypeHelperText {
    if (_selectedVehicleType == 'motorcycle') {
      return 'Standar Motor (Bensin)';
    } else if (_selectedCategory == 'car_diesel') {
      return 'Sesuai Mesin Diesel (Solar)';
    } else if (_selectedCategory == 'car_hybrid') {
      return 'Sesuai Sistem Hybrid';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final odo = int.tryParse(_odometerController.text.trim()) ?? 0;
      final year = _selectedYear ?? DateTime.now().year;
      final cc = int.tryParse(_engineCcController.text.trim());

      final vehicle = VehicleModel(
        id: widget.vehicleToEdit?.id ?? const Uuid().v4(),
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        variant: _variantController.text.trim().isNotEmpty ? _variantController.text.trim() : null,
        vehicleType: _selectedVehicleType,
        year: year,
        licensePlate: _licensePlateController.text.trim().isNotEmpty
            ? _licensePlateController.text.trim().toUpperCase()
            : null,
        engineCc: cc,
        initialOdometer: widget.vehicleToEdit?.initialOdometer ?? odo,
        currentOdometer: odo,
        photoUrl: widget.vehicleToEdit?.photoUrl,
        createdAt: widget.vehicleToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        fuelType: _selectedFuelType,
        transmission: _selectedTransmission,
        color: _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null,
        vehicleCategoryId: _selectedCategory,
      );

      if (_isEditing) {
        await ref.read(vehicleProvider.notifier).updateVehicle(vehicle);
      } else {
        await ref.read(vehicleProvider.notifier).addVehicle(vehicle);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Kendaraan ${vehicle.displayName} berhasil diperbarui!'
                  : 'Kendaraan ${vehicle.displayName} berhasil disimpan!',
            ),
            backgroundColor: Colors.green[700],
          ),
        );
        Navigator.pop(context, vehicle);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Kendaraan' : 'Tambah Kendaraan',
          style: AppTypography.heading2,
        ),
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
                // Section: Vehicle Type
                Text('TIPE KENDARAAN', style: AppTypography.captionBadge),
                const SizedBox(height: AppSpacing.space8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: AppSpacing.cardBorderRadius,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTypeButton(
                          title: 'Motor',
                          icon: Icons.two_wheeler_rounded,
                          type: 'motorcycle',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTypeButton(
                          title: 'Mobil',
                          icon: Icons.directions_car_rounded,
                          type: 'car',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.space16),

                // Section: Vehicle Category (Tipe Kendaraan)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedVehicleType == 'motorcycle' ? 'TIPE MOTOR' : 'TIPE MOBIL',
                          style: AppTypography.captionBadge,
                        ),
                        const Text(
                          'Untuk rekomendasi perawatan otomatis',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    _buildCategorySelector(),
                  ],
                ),

                const SizedBox(height: AppSpacing.space16),

                // Section: Essential Info
                Text('INFORMASI KENDARAAN', style: AppTypography.captionBadge),
                const SizedBox(height: AppSpacing.space8),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: AppSpacing.cardBorderRadius,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _brandController,
                        label: 'Merek Kendaraan',
                        hint: 'Contoh: Honda, Yamaha, Toyota',
                        icon: Icons.business_rounded,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Merek kendaraan wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.space12),
                      _buildTextField(
                        controller: _modelController,
                        label: 'Model Kendaraan',
                        hint: _selectedVehicleType == 'motorcycle'
                            ? 'Contoh: Vario 160, Beat, NMAX'
                            : 'Contoh: Avanza, Brio, Innova',
                        icon: _selectedVehicleType == 'motorcycle'
                            ? Icons.directions_bike_rounded
                            : Icons.directions_car_rounded,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Model kendaraan wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.space12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _selectedYear,
                              isExpanded: true,
                              menuMaxHeight: 300,
                              decoration: InputDecoration(
                                labelText: 'Tahun',
                                hintText: 'Pilih',
                                prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.textMuted),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              items: _availableYears.map((y) {
                                return DropdownMenuItem<int>(
                                  value: y,
                                  child: Text(y.toString()),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedYear = val),
                              validator: (val) => val == null ? 'Pilih tahun' : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space12),
                          Expanded(
                            child: _buildTextField(
                              controller: _odometerController,
                              label: 'Kilometer Saat Ini',
                              hint: '0',
                              helperText: 'Total km di spidometer',
                              icon: Icons.speed_rounded,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Wajib diisi';
                                final num = int.tryParse(val);
                                if (num == null || num < 0) return 'Odometer tidak valid';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.space16),

                // Section: Collapsible Optional Information
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: AppSpacing.cardBorderRadius,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(
                        'Informasi Tambahan (Opsional)',
                        style: AppTypography.heading3.copyWith(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Plat nomor, warna, transmisi, kapasitas mesin',
                        style: AppTypography.captionBadge.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _licensePlateController,
                                label: 'Nomor Plat (Opsional)',
                                hint: 'Contoh: B 1234 XYZ',
                                icon: Icons.credit_card_rounded,
                                textCapitalization: TextCapitalization.characters,
                              ),
                              const SizedBox(height: AppSpacing.space12),
                              _buildTextField(
                                controller: _variantController,
                                label: 'Varian / Tipe (Opsional)',
                                hint: 'Contoh: CBS-ISS, GR Sport, ABS',
                                icon: Icons.style_rounded,
                              ),
                              const SizedBox(height: AppSpacing.space12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _engineCcController,
                                      label: 'Kapasitas Mesin (CC)',
                                      hint: 'Contoh: 150',
                                      icon: Icons.speed_rounded,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.space12),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _colorController,
                                      label: 'Warna Kendaraan',
                                      hint: 'Contoh: Hitam',
                                      icon: Icons.palette_outlined,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.space12),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      key: ValueKey('trans_${_selectedCategory}_$_selectedTransmission'),
                                      initialValue: _selectedTransmission,
                                      disabledHint: Text(
                                        _selectedTransmission == 'Automatic' ? 'Otomatis (Matic)' : 'Manual',
                                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Transmisi',
                                        helperText: _transmissionHelperText,
                                        helperMaxLines: 1,
                                        prefixIcon: const Icon(Icons.tune_rounded, size: 20),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
                                        ),
                                        filled: _isTransmissionLocked,
                                        fillColor: _isTransmissionLocked ? AppColors.surfaceSubtle : null,
                                      ),
                                      items: _allowedTransmissions.map((t) {
                                        return DropdownMenuItem(
                                          value: t,
                                          child: Text(t == 'Automatic' ? 'Otomatis (Matic)' : 'Manual'),
                                        );
                                      }).toList(),
                                      onChanged: _isTransmissionLocked
                                          ? null
                                          : (val) => setState(() => _selectedTransmission = val),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.space12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      key: ValueKey('fuel_${_selectedCategory}_$_selectedFuelType'),
                                      initialValue: _selectedFuelType,
                                      disabledHint: Text(
                                        _selectedFuelType == 'Diesel'
                                            ? 'Diesel'
                                            : _selectedFuelType == 'Hybrid'
                                                ? 'Hybrid'
                                                : _selectedFuelType == 'Electric'
                                                    ? 'Listrik'
                                                    : 'Bensin',
                                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Bahan Bakar',
                                        helperText: _fuelTypeHelperText,
                                        helperMaxLines: 1,
                                        prefixIcon: const Icon(Icons.local_gas_station_rounded, size: 20),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
                                        ),
                                        filled: _isFuelTypeLocked,
                                        fillColor: _isFuelTypeLocked ? AppColors.surfaceSubtle : null,
                                      ),
                                      items: _allowedFuelTypes.map((f) {
                                        return DropdownMenuItem(
                                          value: f,
                                          child: Text(
                                            f == 'Gasoline'
                                                ? 'Bensin'
                                                : f == 'Diesel'
                                                    ? 'Diesel'
                                                    : f == 'Hybrid'
                                                        ? 'Hybrid'
                                                        : 'Listrik',
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: _isFuelTypeLocked
                                          ? null
                                          : (val) => setState(() => _selectedFuelType = val),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.space24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.buttonBorderRadius,
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _isEditing ? 'Simpan Perubahan' : 'Simpan Kendaraan',
                            style: AppTypography.heading3.copyWith(color: Colors.white),
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

  Widget _buildTypeButton({
    required String title,
    required IconData icon,
    required String type,
  }) {
    final isSelected = _selectedVehicleType == type;
    return GestureDetector(
      onTap: () {
        if (_selectedVehicleType != type) {
          setState(() {
            _selectedVehicleType = type;
            _selectedCategory = type == 'car' ? 'car_automatic' : 'scooter_cvt';
            _selectedTransmission = 'Automatic';
            _selectedFuelType = 'Gasoline';
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final isMotor = _selectedVehicleType == 'motorcycle';
    final categories = isMotor
        ? [
            ('scooter_cvt', 'Motor Matic', Icons.two_wheeler_rounded, 'Vario, Beat, NMAX'),
            ('motorcycle_manual', 'Bebek / Manual', Icons.sports_motorsports_rounded, 'Supra, Revo, Jupiter'),
            ('sport_motorcycle', 'Motor Sport', Icons.speed_rounded, 'CB150R, R15, CBR'),
          ]
        : [
            ('car_automatic', 'Matic (AT/CVT)', Icons.directions_car_rounded, 'Avanza AT, Brio CVT'),
            ('car_manual', 'Manual (MT)', Icons.tune_rounded, 'Avanza MT, Sigra MT'),
            ('car_diesel', 'Diesel', Icons.local_gas_station_rounded, 'Innova, Pajero, Fortuner'),
            ('car_hybrid', 'Hybrid', Icons.bolt_rounded, 'Yaris Cross, Kicks HEV'),
          ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.cardBorderRadius,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = cat.$1;
                  if (cat.$1 == 'scooter_cvt' || cat.$1 == 'car_automatic' || cat.$1 == 'car_hybrid') {
                    _selectedTransmission = 'Automatic';
                  } else if (cat.$1 == 'motorcycle_manual' ||
                      cat.$1 == 'sport_motorcycle' ||
                      cat.$1 == 'car_manual') {
                    _selectedTransmission = 'Manual';
                  } else if (cat.$1 == 'car_diesel') {
                    _selectedTransmission = _selectedTransmission ?? 'Automatic';
                  }
                  if (cat.$1 == 'car_diesel') {
                    _selectedFuelType = 'Diesel';
                  } else if (cat.$1 == 'car_hybrid') {
                    _selectedFuelType = 'Hybrid';
                  } else {
                    _selectedFuelType = 'Gasoline';
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.$3,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cat.$2,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      cat.$4,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? helperText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
