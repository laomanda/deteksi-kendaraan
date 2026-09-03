import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/component_catalog.dart';
import '../../../maintenance/data/models/maintenance_item_model.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../data/models/vehicle_model.dart';
import '../controllers/active_vehicle_controller.dart';

/// Form screen to add a new vehicle or edit an existing vehicle in Garage (PRD Section 7.1)
class VehicleFormScreen extends ConsumerStatefulWidget {
  final VehicleModel? vehicleToEdit;

  const VehicleFormScreen({super.key, this.vehicleToEdit});

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedType;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _kmController;
  String? _photoPath;
  bool _isSaving = false;

  bool get _isEditing => widget.vehicleToEdit != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicleToEdit;
    _selectedType = v?.vehicleType ?? 'motorcycle';
    _brandController = TextEditingController(text: v?.brand ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');
    _yearController = TextEditingController(
      text: v?.year.toString() ?? DateTime.now().year.toString(),
    );
    _kmController = TextEditingController(
      text: v != null ? v.currentKilometer.toInt().toString() : '',
    );
    _photoPath = v?.photoPath;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _kmController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${appDir.path}/vehicles');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final saved = await File(picked.path).copy(
        '${targetDir.path}/vehicle_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      setState(() => _photoPath = saved.path);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final brand = _brandController.text.trim();
      final model = _modelController.text.trim();
      final year = int.parse(_yearController.text.trim());
      final currentKm = double.parse(_kmController.text.trim());

      final vehicleRepo = ref.read(vehicleRepositoryProvider);
      final maintenanceRepo = ref.read(maintenanceRepositoryProvider);

      if (_isEditing) {
        final existing = widget.vehicleToEdit!;
        final updated = existing.copyWith(
          vehicleType: _selectedType,
          brand: brand,
          model: model,
          year: year,
          currentKilometer: currentKm,
          photoPath: _photoPath,
        );
        await vehicleRepo.saveVehicle(updated);
        ref.read(activeVehicleProvider.notifier).refresh();
      } else {
        const uuid = Uuid();
        final newId = uuid.v4();
        final newVehicle = VehicleModel(
          id: newId,
          vehicleType: _selectedType,
          brand: brand,
          model: model,
          year: year,
          currentKilometer: currentKm,
          photoPath: _photoPath,
          createdAt: DateTime.now(),
        );

        // Populate standard components
        final catalog = ComponentCatalog.getCatalogForVehicleType(_selectedType);
        final now = DateTime.now();
        final items = catalog.map((meta) {
          return MaintenanceItemModel(
            id: uuid.v4(),
            vehicleId: newId,
            componentType: meta.key,
            intervalKm: meta.intervalKm,
            intervalDays: meta.intervalDays,
            lastServiceKm: currentKm,
            lastServiceDate: now,
          );
        }).toList();

        await vehicleRepo.saveVehicle(newVehicle);
        await maintenanceRepo.saveItems(items);
        await ref.read(activeVehicleProvider.notifier).setActiveVehicle(newId);
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Ubah Kendaraan' : 'Tambah Kendaraan',
          style: AppTypography.heading2,
        ),
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
                // Vehicle Type
                Text('Tipe Kendaraan', style: AppTypography.captionBadge),
                const SizedBox(height: AppSpacing.space8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeOption('motorcycle', 'Sepeda Motor', Icons.two_wheeler_rounded),
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: _buildTypeOption('car', 'Mobil', Icons.directions_car_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space16),

                // Photo selector
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: AppSpacing.cardBorderRadius,
                        border: Border.all(color: AppColors.borderSubtle, width: 1),
                        image: _photoPath != null
                            ? DecorationImage(
                                image: FileImage(File(_photoPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _photoPath == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 24,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 4),
                                Text('Ganti Foto', style: AppTypography.captionSubtle),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),

                // Brand
                Text('Merek', style: AppTypography.captionBadge),
                const SizedBox(height: AppSpacing.space4),
                TextFormField(
                  controller: _brandController,
                  decoration: const InputDecoration(hintText: 'Contoh: Honda, Toyota'),
                  validator: (val) =>
                      val == null || val.trim().length < 2 ? 'Minimal 2 karakter' : null,
                ),
                const SizedBox(height: AppSpacing.space16),

                // Model
                Text('Model', style: AppTypography.captionBadge),
                const SizedBox(height: AppSpacing.space4),
                TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(hintText: 'Contoh: Vario 160, Avanza'),
                  validator: (val) =>
                      val == null || val.trim().length < 2 ? 'Minimal 2 karakter' : null,
                ),
                const SizedBox(height: AppSpacing.space16),

                // Year & KM
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tahun', style: AppTypography.captionBadge),
                          const SizedBox(height: AppSpacing.space4),
                          TextFormField(
                            controller: _yearController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '2023'),
                            validator: (val) {
                              final y = int.tryParse(val ?? '');
                              if (y == null || y < 1980 || y > DateTime.now().year + 1) {
                                return 'Tahun salah';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Odometer Terkini', style: AppTypography.captionBadge),
                          const SizedBox(height: AppSpacing.space4),
                          TextFormField(
                            controller: _kmController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '14250',
                              suffixText: 'km',
                            ),
                            validator: (val) {
                              final km = double.tryParse(val ?? '');
                              if (km == null || km < 0) {
                                return 'Angka tidak valid';
                              }
                              if (_isEditing &&
                                  km < widget.vehicleToEdit!.currentKilometer) {
                                return 'Tidak boleh lebih kecil';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space32),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonBorderRadius,
                    ),
                  ),
                  onPressed: _isSaving ? null : _save,
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
                          _isEditing ? 'Simpan Perubahan' : 'Tambahkan Kendaraan',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption(String type, String title, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.08) : AppColors.surfaceSubtle,
          borderRadius: AppSpacing.buttonBorderRadius,
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.space8),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
