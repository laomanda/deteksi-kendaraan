import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/database/hive_registrar.dart';
import '../../../../shared/services/backup_service.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../shared/presentation/screens/supabase_connection_test_page.dart';
import '../../../shared/presentation/screens/ridecare_database_test_page.dart';
import '../../../../core/sync/sync_manager.dart';

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
                    onTap: _isExporting ? null : _exportBackup,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),

            // Section: Supabase & Cloud Sync
            Text('SUPABASE & CLOUD SYNC', style: AppTypography.captionBadge),
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
                    leading: const Icon(Icons.cloud_sync_outlined, color: AppColors.primaryBlue),
                    title: Text('Test Koneksi Supabase', style: AppTypography.bodyMedium),
                    subtitle: Text('Cek status koneksi backend', style: AppTypography.captionSubtle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SupabaseConnectionTestPage()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.storage_rounded, color: AppColors.secondaryTeal),
                    title: Text('Test CRUD Database', style: AppTypography.bodyMedium),
                    subtitle: Text('Testing Create, Read, Update, Delete', style: AppTypography.captionSubtle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RideCareDatabaseTestPage()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.sync_rounded, color: Colors.indigo),
                    title: Text('Sinkronisasi Data (Hive -> Supabase)', style: AppTypography.bodyMedium),
                    subtitle: Text('Upload data lokal ke Supabase', style: AppTypography.captionSubtle),
                    trailing: const Icon(Icons.cloud_upload_outlined),
                    onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Memulai sinkronisasi ke Supabase...')),
                      );
                      final result = await SyncManager().uploadPendingChanges();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result.message)),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),

            // Section 3: Privasi & Lisensi
            Text('PRIVASI & SUMBER DATA', style: AppTypography.captionBadge),
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
                      Text('100% Offline & Privat', style: AppTypography.heading3),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    'Semua data kendaraan dan riwayat lokasi Anda tersimpan secara lokal di perangkat.',
                    style: AppTypography.captionSubtle.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  const Divider(),
                  const SizedBox(height: AppSpacing.space12),
                  Text('Sumber Peta', style: AppTypography.captionBadge),
                  const SizedBox(height: 4),
                  Text(
                    '© OpenStreetMap contributors',
                    style: AppTypography.captionSubtle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),

            // Section 4: Factory Reset
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
