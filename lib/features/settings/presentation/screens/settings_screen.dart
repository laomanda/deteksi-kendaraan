import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/database/hive_registrar.dart';
import '../../../../shared/services/backup_service.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../maintenance/presentation/controllers/maintenance_status_controller.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';

/// Layar 5: Settings Screen (DSS Section 9.5 & PRD Section 6)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationEnabled = true;
  bool _highAccuracyGps = true;
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    final box = HiveRegistrar.settingsBox;
    _notificationEnabled = box.get('notif_enabled', defaultValue: true) as bool;
    _highAccuracyGps = box.get('high_accuracy_gps', defaultValue: true) as bool;
  }

  void _toggleNotif(bool val) {
    setState(() => _notificationEnabled = val);
    HiveRegistrar.settingsBox.put('notif_enabled', val);
  }

  void _toggleGps(bool val) {
    setState(() => _highAccuracyGps = val);
    HiveRegistrar.settingsBox.put('high_accuracy_gps', val);
  }

  Future<void> _exportBackupFile() async {
    setState(() => _isExporting = true);
    try {
      final success = await BackupService.exportDatabase();
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berkas cadangan berhasil diekspor/diunduh.'),
            backgroundColor: AppColors.healthOptimal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Fallback: Salin ke clipboard jika dialog file atau share diblokir browser/OS
      final jsonString = BackupService.generateExportJson();
      await Clipboard.setData(ClipboardData(text: jsonString));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan berkas ($e). Data JSON telah disalin ke papan klip!'),
            backgroundColor: AppColors.healthModerate,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _copyExportJsonToClipboard() async {
    final jsonString = BackupService.generateExportJson();
    await Clipboard.setData(ClipboardData(text: jsonString));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data cadangan JSON berhasil disalin ke papan klip!'),
        backgroundColor: AppColors.healthOptimal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pilih Metode Ekspor', style: AppTypography.heading2),
              const SizedBox(height: 8),
              Text(
                'Unduh berkas cadangan ke perangkat atau salin teks JSON ke clipboard.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.download_rounded, color: AppColors.primaryBlue),
                ),
                title: Text('Unduh Berkas JSON (.json)', style: AppTypography.bodyMedium),
                subtitle: Text('Simpan berkas cadangan ke penyimpanan perangkat', style: AppTypography.captionSubtle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportBackupFile();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.copy_rounded, color: AppColors.primaryBlue),
                ),
                title: Text('Salin Teks JSON (Clipboard)', style: AppTypography.bodyMedium),
                subtitle: Text('Salin data ke papan klip untuk dibagikan atau disimpan', style: AppTypography.captionSubtle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  _copyExportJsonToClipboard();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processImportResult(ImportResult result) async {
    if (result.success) {
      ref.read(activeVehicleProvider.notifier).refresh();
      ref.invalidate(maintenanceStatusProvider);
      ref.invalidate(dashboardSummaryProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.healthOptimal,
          behavior: SnackBarBehavior.floating,
        ),
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
  }

  Future<void> _importFromFile() async {
    setState(() => _isImporting = true);
    try {
      final result = await BackupService.pickAndImportDatabase();
      if (!mounted || result == null) return;
      await _processImportResult(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengimpor data: $e'),
            backgroundColor: AppColors.healthCritical,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showPasteJsonDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardBorderRadius),
        title: Text('Tempel Data JSON', style: AppTypography.heading2),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Salin dan tempel teks berkas cadangan JSON Anda di bawah ini:',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.space12),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: '{\n  "app": "RideCare",\n  "vehicles": [...]\n}',
                  hintStyle: AppTypography.captionSubtle,
                  filled: true,
                  fillColor: AppColors.surfaceSubtle,
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.buttonBorderRadius,
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonBorderRadius,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonBorderRadius,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    Navigator.pop(ctx);
                    setState(() => _isImporting = true);
                    try {
                      final result = await BackupService.importDatabase(text);
                      if (mounted) await _processImportResult(result);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal mengimpor data: $e'),
                            backgroundColor: AppColors.healthCritical,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isImporting = false);
                    }
                  },
                  child: const Text('Impor Data'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pilih Metode Impor', style: AppTypography.heading2),
              const SizedBox(height: 8),
              Text(
                'Pilih berkas dari perangkat Anda atau tempel langsung data JSON.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_open_rounded, color: AppColors.primaryBlue),
                ),
                title: Text('Pilih Berkas JSON (.json)', style: AppTypography.bodyMedium),
                subtitle: Text('Buka dialog berkas dan pilih file cadangan', style: AppTypography.captionSubtle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  _importFromFile();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.paste_rounded, color: AppColors.primaryBlue),
                ),
                title: Text('Tempel Teks JSON', style: AppTypography.bodyMedium),
                subtitle: Text('Salin-tempel teks cadangan dari clipboard', style: AppTypography.captionSubtle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPasteJsonDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmFactoryReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardBorderRadius),
        title: Text('Reset Data Pabrik?', style: AppTypography.heading2),
        content: Text(
          'Seluruh data kendaraan, riwayat servis, dan jalur perjalanan akan dihapus permanen.',
          style: AppTypography.bodySmall,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonBorderRadius,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.healthCritical,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonBorderRadius,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await BackupService.factoryReset();
                    ref.read(activeVehicleProvider.notifier).refresh();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Pengaturan', style: AppTypography.heading2),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space16),
          children: [
            // Section 1: Notifikasi & Akurasi
            Text('PREFERENSI', style: AppTypography.captionBadge),
            const SizedBox(height: AppSpacing.space8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: AppSpacing.cardBorderRadius,
                border: AppSpacing.cardBorder,
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Pengingat Servis', style: AppTypography.bodyMedium),
                    subtitle: Text(
                      'Peringatan berkala saat sisa usia komponen < 15%',
                      style: AppTypography.captionSubtle,
                    ),
                    value: _notificationEnabled,
                    activeTrackColor: AppColors.primaryBlue,
                    onChanged: _toggleNotif,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text('Akurasi GPS', style: AppTypography.bodyMedium),
                    subtitle: Text('Tinggi (Navigasi presisi)', style: AppTypography.captionSubtle),
                    value: _highAccuracyGps,
                    activeTrackColor: AppColors.primaryBlue,
                    onChanged: _toggleGps,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),

            // Section 2: Backup & Ekspor
            Text('CADANGAN DATA', style: AppTypography.captionBadge),
            const SizedBox(height: AppSpacing.space8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: AppSpacing.cardBorderRadius,
                border: AppSpacing.cardBorder,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.download_rounded, color: AppColors.primaryBlue),
                    title: Text('Ekspor Cadangan (JSON)', style: AppTypography.bodyMedium),
                    subtitle: Text('Simpan atau bagikan data lokal aplikasi', style: AppTypography.captionSubtle),
                    trailing: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: (_isExporting || _isImporting) ? null : _showExportOptions,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.file_upload_outlined, color: AppColors.primaryBlue),
                    title: Text('Impor Cadangan (JSON)', style: AppTypography.bodyMedium),
                    subtitle: Text('Pulihkan data dari berkas cadangan JSON', style: AppTypography.captionSubtle),
                    trailing: _isImporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: (_isExporting || _isImporting) ? null : _showImportOptions,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),

            // Section: Factory Reset
            Text('HAPUS DATA', style: AppTypography.captionBadge.copyWith(color: AppColors.healthCritical)),
            const SizedBox(height: AppSpacing.space8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: AppSpacing.cardBorderRadius,
                border: Border.all(color: AppColors.healthCritical.withValues(alpha: 0.3), width: 1),
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_forever_outlined, color: AppColors.healthCritical),
                title: Text(
                  'Reset Data Aplikasi',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.healthCritical),
                ),
                subtitle: Text(
                  'Hapus semua kendaraan, servis, dan riwayat perjalanan',
                  style: AppTypography.captionSubtle,
                ),
                onTap: _confirmFactoryReset,
              ),
            ),
            const SizedBox(height: AppSpacing.space32),

            // Version info footer
            Center(
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/icons/app_logo.svg',
                    width: 42,
                    height: 42,
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  Text('RideCare v1.0.0', style: AppTypography.captionBadge),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
          ],
        ),
      ),
    );
  }
}
