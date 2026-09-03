import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import 'initial_condition_setup_screen.dart';

/// First Vehicle Setup Screen (PRD Section 7.1 & DSS Section 10.1)
class FirstVehicleSetupScreen extends StatefulWidget {
  const FirstVehicleSetupScreen({super.key});

  @override
  State<FirstVehicleSetupScreen> createState() => _FirstVehicleSetupScreenState();
}

class _FirstVehicleSetupScreenState extends State<FirstVehicleSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'motorcycle'; // 'motorcycle' | 'car'
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController(text: DateTime.now().year.toString());
  final _kmController = TextEditingController();
  String? _selectedPhotoPath;

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
      // Copy to private app directory (PRD 7.1)
      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${appDir.path}/vehicles');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final savedImage = await File(picked.path).copy(
        '${targetDir.path}/vehicle_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      setState(() => _selectedPhotoPath = savedImage.path);
    }
  }

  void _proceed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();
    final year = int.parse(_yearController.text.trim());
    final currentKm = double.parse(_kmController.text.trim());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InitialConditionSetupScreen(
          vehicleType: _selectedType,
          brand: brand,
          model: model,
          year: year,
          currentKilometer: currentKm,
          photoPath: _selectedPhotoPath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: AppBar(
        title: Text('Data Kendaraan', style: AppTypography.heading2),
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
                Text(
                  'Daftarkan Kendaraan Anda',
                  style: AppTypography.heading1,
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  'Informasi ini digunakan untuk mengkalkulasi jadwal pemeliharaan komponen secara otomatis.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.space24),

                // Vehicle Type Toggle
                Text('Tipe Kendaraan', style: AppTypography.captionBadge),
                const SizedBox(height: AppSpacing.space8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeSelector(
                        type: 'motorcycle',
                        title: 'Sepeda Motor',
                        icon: Icons.two_wheeler_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: _buildTypeSelector(
                        type: 'car',
                        title: 'Mobil',
                        icon: Icons.directions_car_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space16),

                // Photo picker box
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: AppSpacing.cardBorderRadius,
                        border: Border.all(color: AppColors.borderSubtle, width: 1),
                        image: _selectedPhotoPath != null
                            ? DecorationImage(
                                image: FileImage(File(_selectedPhotoPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedPhotoPath == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 28,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Foto (Opsional)',
                                  style: AppTypography.captionSubtle,
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),

                // Brand field
                Text('Merek Kendaraan', style: AppTypography.captionBadge),
                const SizedBox(height: AppSpacing.space4),
                TextFormField(
                  controller: _brandController,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Honda, Yamaha, Toyota',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 2) {
                      return 'Merek kendaraan minimal 2 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.space16),

                // Model field
                Text('Model / Seri', style: AppTypography.captionBadge),
                const SizedBox(height: AppSpacing.space4),
                TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Vario 160, NMAX, Avanza',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 2) {
                      return 'Model kendaraan minimal 2 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.space16),

                // Year & Odometer in row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tahun Perakitan', style: AppTypography.captionBadge),
                          const SizedBox(height: AppSpacing.space4),
                          TextFormField(
                            controller: _yearController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '2023',
                            ),
                            validator: (val) {
                              final currentYear = DateTime.now().year;
                              final y = int.tryParse(val ?? '');
                              if (y == null || y < 1980 || y > currentYear + 1) {
                                return 'Tahun tidak valid';
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
                          Text('Odometer Saat Ini', style: AppTypography.captionBadge),
                          const SizedBox(height: AppSpacing.space4),
                          TextFormField(
                            controller: _kmController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: 14250',
                              suffixText: 'km',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Kilometer wajib diisi';
                              }
                              final km = double.tryParse(val.trim());
                              if (km == null || km < 0) {
                                return 'Harus angka positif';
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

                // Proceed button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonBorderRadius,
                    ),
                  ),
                  onPressed: _proceed,
                  child: Text(
                    'Lanjut ke Kondisi Komponen',
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
      ),
    );
  }

  Widget _buildTypeSelector({
    required String type,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
              size: 22,
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
