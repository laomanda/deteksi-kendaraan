import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/image_helper.dart';
import '../../../../shared/services/backup_service.dart';
import '../../../navigation/main_navigation_screen.dart';
import 'initial_condition_setup_screen.dart';

/// First Vehicle Setup Screen (PRD Section 7.1 & DSS Section 10.1)
/// Consistent with AddVehiclePage in structure, fields, and styling.
class FirstVehicleSetupScreen extends StatefulWidget {
  const FirstVehicleSetupScreen({super.key});

  @override
  State<FirstVehicleSetupScreen> createState() => _FirstVehicleSetupScreenState();
}

class _FirstVehicleSetupScreenState extends State<FirstVehicleSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isImporting = false;

  String _selectedVehicleType = 'motorcycle'; // 'motorcycle' | 'car'
  String _selectedCategory = 'scooter_cvt';
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _variantController = TextEditingController();
  int? _selectedYear;
  final List<int> _availableYears = List.generate(
    DateTime.now().year - 1980 + 1,
    (index) => DateTime.now().year - index,
  );
  final _engineCcController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _odometerController = TextEditingController(text: '0');
  final _colorController = TextEditingController();

  String? _selectedTransmission = 'Automatic';
  String? _selectedFuelType = 'Gasoline';
  String? _selectedPhotoPath;

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

  String _transmissionLabel(String? t) {
    if (t == null) return '-';
    final lower = t.toLowerCase();
    if (lower == 'automatic' || lower == 'otomatis' || lower == 'matic') {
      return _selectedVehicleType == 'car' ? 'Otomatis (Matic)' : 'Matic';
    }
    return 'Manual';
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

  void _showOdometerInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.speed_rounded, color: AppColors.primaryBlue, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Kilometer di Spidometer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Angka ini adalah TOTAL JARAK TEMPUH (odometer keseluruhan) yang tertera pada layar speedometer kendaraan Anda saat ini.',
              style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Bukan sisa atau jarak oli mesin.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  SizedBox(height: 4),
                  Text('• Menjadi acuan RideCare untuk menghitung jadwal servis otomatis.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  SizedBox(height: 4),
                  Text('• Jika kendaraan baru dari dealer, isi dengan angka 0.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              minimumSize: const Size(90, 38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      if (kIsWeb) {
        setState(() => _selectedPhotoPath = picked.path);
        return;
      }
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final targetDir = Directory('${appDir.path}/vehicles');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
        final savedImage = await File(picked.path).copy(
          '${targetDir.path}/vehicle_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        setState(() => _selectedPhotoPath = savedImage.path);
      } catch (_) {
        setState(() => _selectedPhotoPath = picked.path);
      }
    }
  }

  Future<void> _importBackup() async {
    setState(() => _isImporting = true);
    try {
      final result = await BackupService.pickAndImportDatabase();
      if (!mounted) return;

      if (result == null) {
        // User cancelled file picker
        return;
      }

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.healthOptimal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.healthCritical,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat memulihkan data: $e'),
          backgroundColor: AppColors.healthCritical,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _proceed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tahun kendaraan terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();
    final year = _selectedYear!;
    final currentKm = double.tryParse(_odometerController.text.trim()) ?? 0.0;
    final engineCc = int.tryParse(_engineCcController.text.trim());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InitialConditionSetupScreen(
          vehicleType: _selectedVehicleType,
          vehicleCategoryId: _selectedCategory,
          brand: brand,
          model: model,
          year: year,
          currentKilometer: currentKm,
          photoPath: _selectedPhotoPath,
          variant: _variantController.text.trim().isNotEmpty ? _variantController.text.trim() : null,
          licensePlate: _licensePlateController.text.trim().isNotEmpty
              ? _licensePlateController.text.trim().toUpperCase()
              : null,
          engineCc: engineCc,
          color: _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null,
          transmission: _selectedTransmission,
          fuelType: _selectedFuelType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(
          'Data Kendaraan',
          style: AppTypography.heading2,
        ),
        elevation: 0,
        backgroundColor: AppColors.surfaceWhite,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          TextButton.icon(
            onPressed: _isImporting ? null : _importBackup,
            icon: _isImporting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                  )
                : const Icon(Icons.restore_page_outlined, size: 18, color: AppColors.primaryBlue),
            label: Text(
              _isImporting ? 'Memulihkan...' : 'Impor Data',
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Restore Data Banner Card
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.space16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.restore_page_outlined,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sudah punya data cadangan?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Pulihkan profil kendaraan & riwayat servis dari berkas JSON ekspor.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isImporting ? null : _importBackup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: _isImporting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Impor',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
                // Vehicle Photo Avatar Picker
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: AppColors.surfaceWhite,
                              backgroundImage: ImageHelper.getVehicleImageProvider(_selectedPhotoPath),
                              child: _selectedPhotoPath == null
                                  ? Icon(
                                      _selectedVehicleType == 'motorcycle'
                                          ? Icons.two_wheeler_outlined
                                          : Icons.directions_car_outlined,
                                      size: 38,
                                      color: AppColors.textMuted,
                                    )
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Foto Kendaraan (Opsional)',
                        style: AppTypography.captionBadge.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),

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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _selectedYear,
                              isExpanded: true,
                              menuMaxHeight: 300,
                              decoration: InputDecoration(
                                labelText: 'Tahun',
                                hintText: 'Pilih',
                                prefixIcon: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 20,
                                  color: AppColors.textMuted,
                                ),
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
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(7),
                              ],
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primaryBlue),
                                tooltip: 'Panduan Odometer',
                                onPressed: () => _showOdometerInfoDialog(context),
                              ),
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
                                      key: ValueKey('trans_${_selectedVehicleType}_${_selectedCategory}_$_selectedTransmission'),
                                      initialValue: _selectedTransmission,
                                      disabledHint: Text(
                                        _transmissionLabel(_selectedTransmission),
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
                                          child: Text(_transmissionLabel(t)),
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
                    onPressed: _proceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.buttonBorderRadius,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Lanjutkan',
                      style: AppTypography.heading3.copyWith(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.space16),

                // Alternative: Import Backup JSON
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.borderSubtle)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'ATAU',
                        style: AppTypography.captionSubtle.copyWith(
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.borderSubtle)),
                  ],
                ),
                const SizedBox(height: AppSpacing.space16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isImporting ? null : _importBackup,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.buttonBorderRadius,
                      ),
                    ),
                    icon: _isImporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                          )
                        : const Icon(Icons.file_upload_outlined, size: 20),
                    label: Text(
                      _isImporting ? 'Memulihkan Data...' : 'Pulihkan Data dari Berkas Cadangan (JSON)',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
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
                  } else if (cat.$1 == 'motorcycle_manual' || cat.$1 == 'sport_motorcycle' || cat.$1 == 'car_manual') {
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
                        color: isSelected ? Colors.white.withValues(alpha: 0.9) : AppColors.textMuted,
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
    Widget? suffixIcon,
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
        suffixIcon: suffixIcon,
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
