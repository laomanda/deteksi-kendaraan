import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/image_helper.dart';
import 'initial_condition_setup_screen.dart';

/// First Vehicle Setup Screen (PRD Section 7.1 & DSS Section 10.1)
/// Simple, clean, and elegant vehicle registration form with interactive guidance
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
  int? _selectedYear;
  final List<int> _availableYears = List.generate(
    DateTime.now().year - 1980 + 1,
    (index) => DateTime.now().year - index,
  );
  final _kmController = TextEditingController();
  String? _selectedPhotoPath;

  @override
  void initState() {
    super.initState();
    _kmController.addListener(_onKmChanged);
  }

  void _onKmChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _kmController.removeListener(_onKmChanged);
    _brandController.dispose();
    _modelController.dispose();
    _kmController.dispose();
    super.dispose();
  }

  String _formatKmFeedback(String text) {
    final n = int.tryParse(text);
    if (n == null) return '';
    if (n == 0) return 'Kendaraan baru (0 km)';
    final formatted = NumberFormat.decimalPattern('id').format(n);
    return 'Terbaca: $formatted km';
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
              'Angka ini adalah TOTAL JARAK TEMPUH (odometer keseluruhan) yang tertera pada layar speedometer motor Anda saat ini.',
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
                  Text('• Jika motor baru dari dealer, isi dengan angka 0.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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

  void _proceed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedYear == null) return;

    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();
    final year = _selectedYear!;
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
                    // Title & Description
                    const Text(
                      'Data Kendaraan',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Masukkan data kendaraan untuk mulai memantau servis.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Vehicle Type Segmented Control
                    Container(
                      height: 44,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          _buildSegmentItem('motorcycle', 'Sepeda Motor', Icons.two_wheeler_rounded),
                          _buildSegmentItem('car', 'Mobil', Icons.directions_car_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Simple Photo Avatar
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: const Color(0xFFF8FAFC),
                              backgroundImage: ImageHelper.getVehicleImageProvider(_selectedPhotoPath),
                              child: _selectedPhotoPath == null
                                  ? Icon(
                                      _selectedType == 'motorcycle'
                                          ? Icons.two_wheeler_outlined
                                          : Icons.directions_car_outlined,
                                      size: 36,
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
                              child: const Icon(Icons.camera_alt, size: 13, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Merek Kendaraan
                    _buildLabel('Merek Kendaraan'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _brandController,
                      decoration: _cleanInputDecoration(
                        hintText: 'Misal: Honda, Yamaha, Toyota',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length < 2) {
                          return 'Merek kendaraan minimal 2 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Model / Seri
                    _buildLabel('Model / Seri'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _modelController,
                      decoration: _cleanInputDecoration(
                        hintText: _selectedType == 'motorcycle'
                            ? 'Misal: Vario 160, Beat, NMAX'
                            : 'Misal: Avanza, Brio, Innova',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length < 2) {
                          return 'Model kendaraan minimal 2 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Row: Tahun Perakitan & Kilometer di Spidometer
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tahun Dropdown
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Tahun'),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<int>(
                                initialValue: _selectedYear,
                                hint: const Text(
                                  'Pilih',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                                ),
                                isExpanded: true,
                                menuMaxHeight: 300,
                                decoration: _cleanInputDecoration(hintText: 'Pilih'),
                                items: _availableYears.map((y) {
                                  return DropdownMenuItem<int>(
                                    value: y,
                                    child: Text(
                                      y.toString(),
                                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedYear = val),
                                validator: (val) => val == null ? 'Pilih tahun' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Kilometer Spidometer
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(
                                'Kilometer di Spidometer',
                                trailing: InkWell(
                                  onTap: () => _showOdometerInfoDialog(context),
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primaryBlue),
                                        SizedBox(width: 3),
                                        Text(
                                          'Info',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _kmController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(7),
                                ],
                                decoration: _cleanInputDecoration(
                                  hintText: 'Contoh: 14250',
                                  suffixText: 'km',
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Wajib diisi (isi 0 jika baru)';
                                  }
                                  final km = double.tryParse(val.trim());
                                  if (km == null || km < 0) {
                                    return 'Hanya boleh angka positif';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 5),
                              if (_kmController.text.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.healthOptimal),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _formatKmFeedback(_kmController.text),
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.healthOptimal,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total jarak tempuh',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                    InkWell(
                                      onTap: () => setState(() => _kmController.text = '0'),
                                      borderRadius: BorderRadius.circular(4),
                                      child: const Text(
                                        '+ Baru (0 km)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
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
                      onPressed: _proceed,
                      child: const Text(
                        'Lanjutkan',
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

  Widget _buildSegmentItem(String type, String title, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.06),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  InputDecoration _cleanInputDecoration({
    required String hintText,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      suffixText: suffixText,
      suffixStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.healthCritical),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.healthCritical, width: 1.5),
      ),
    );
  }
}
