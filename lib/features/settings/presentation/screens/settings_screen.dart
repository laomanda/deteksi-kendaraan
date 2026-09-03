import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/database/hive_registrar.dart';
import '../../../../shared/services/backup_service.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
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

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);
    try {
      await BackupService.exportDatabase();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _confirmFactoryReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardBorderRadius),
        title: Text('Reset Data Pabrik?', style: AppTypography.heading2),
        content: Text(
          'Seluruh data kendaraan, riwayat servis, dan jalur GPS yang tersimpan di perangkat akan dihapus secara permanen.',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppTypography.bodyMedium),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.healthCritical,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.buttonBorderRadius,
              ),
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
            child: const Text('Reset Semuanya', style: TextStyle(color: Colors.white)),
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
        title: Text('Pengaturan Sistem', style: AppTypography.heading2),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space16),
          children: [
            // Section 1: Notifikasi & Akurasi
            Text('PREFERENSI PERANGKAT', style: AppTypography.captionBadge),
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
                    title: Text('Pengingat Servis Lokal', style: AppTypography.bodyMedium),
                    subtitle: Text(
                      'Alarm terjadwal setiap 7 hari dan saat komponen < 15%',
                      style: AppTypography.captionSubtle,
                    ),
                    value: _notificationEnabled,
                    activeTrackColor: AppColors.primaryBlue,
                    onChanged: _toggleNotif,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text('Akurasi GPS Tinggi', style: AppTypography.bodyMedium),
                    subtitle: Text(
                      _highAccuracyGps
                          ? 'Mode Presisi Tinggi (High Accuracy GPS)'
                          : 'Mode Hemat Baterai (Balanced Power Saver)',
                      style: AppTypography.captionSubtle,
                    ),
                    value: _highAccuracyGps,
                    activeTrackColor: AppColors.primaryBlue,
                    onChanged: _toggleGps,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),

            // Section 2: Cadangan & Pemulihan
            Text('CADANGAN & PENYIMPANAN', style: AppTypography.captionBadge),
            const SizedBox(height: AppSpacing.space8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: AppSpacing.cardBorderRadius,
                border: AppSpacing.cardBorder,
              ),
              child: ListTile(
                leading: const Icon(Icons.file_download_outlined, color: AppColors.primaryBlue),
                title: Text('Ekspor Cadangan Database', style: AppTypography.bodyMedium),
                subtitle: Text(
                  'Simpan salinan berkas JSON lokal ke folder perangkat atau drive',
                  style: AppTypography.captionSubtle,
                ),
                trailing: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                onTap: _isExporting ? null : _exportBackup,
              ),
            ),
            const SizedBox(height: AppSpacing.space24),

            // Section 3: Privasi & Lisensi
            Text('PRIVASI & SUMBER TERBUKA', style: AppTypography.captionBadge),
            const SizedBox(height: AppSpacing.space8),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: AppSpacing.cardBorderRadius,
                border: AppSpacing.cardBorder,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, color: AppColors.secondaryTeal, size: 20),
                      const SizedBox(width: AppSpacing.space8),
                      Text('Zero-Data-Exfiltration Guarantee', style: AppTypography.heading3),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    'RideCare tidak memiliki backend, tidak mengumpulkan analitik, dan tidak pernah mentransmisikan lokasi Anda ke server mana pun.',
                    style: AppTypography.captionSubtle.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  const Divider(),
                  const SizedBox(height: AppSpacing.space12),
                  Text('Data Peta & Kartografi', style: AppTypography.captionBadge),
                  const SizedBox(height: 4),
                  Text(
                    '© Kontributor OpenStreetMap (ODbL). Digunakan di bawah lisensi terbuka Open Database License.',
                    style: AppTypography.captionSubtle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),

            // Section 4: Factory Reset
            Text('ZONA KRITIS', style: AppTypography.captionBadge.copyWith(color: AppColors.healthCritical)),
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
                  'Reset Data Pabrik',
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
                  Text('RideCare v1.0.0-PROD', style: AppTypography.captionBadge),
                  const SizedBox(height: 2),
                  Text(
                    'Offline-First Personal Vehicle Companion',
                    style: AppTypography.captionSubtle,
                  ),
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
