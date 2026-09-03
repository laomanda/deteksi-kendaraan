import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/database/hive_registrar.dart';

/// Service managing JSON export and import for offline backup (PRD Section 6, 20.2 & DSS Section 9.5)
class BackupService {
  BackupService._();

  /// Exports all Hive database data into a formatted JSON file and invokes the native share sheet
  static Future<void> exportDatabase() async {
    final vehicles = HiveRegistrar.vehiclesBox.values.map((v) => v.toJson()).toList();
    final maintenance =
        HiveRegistrar.maintenanceBox.values.map((m) => m.toJson()).toList();
    final serviceHistory =
        HiveRegistrar.serviceHistoryBox.values.map((s) => s.toJson()).toList();
    final rides = HiveRegistrar.ridesBox.values.map((r) => r.toJson()).toList();

    final exportData = {
      'app': 'RideCare',
      'version': '1.0.0-PROD',
      'exportedAt': DateTime.now().toIso8601String(),
      'vehicles': vehicles,
      'maintenance': maintenance,
      'service_history': serviceHistory,
      'rides': rides,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    if (kIsWeb) {
      await Share.shareXFiles(
        [
          XFile.fromData(
            utf8.encode(jsonString),
            mimeType: 'application/json',
            name: 'ridecare_backup_$timestamp.json',
          ),
        ],
        subject: 'RideCare Local Backup ($timestamp)',
        text: 'Berkas cadangan data lokal RideCare Anda.',
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ridecare_backup_$timestamp.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'RideCare Local Backup ($timestamp)',
      text: 'Berkas cadangan data lokal RideCare Anda.',
    );
  }

  /// Clears all local database data (Factory Reset)
  static Future<void> factoryReset() async {
    await HiveRegistrar.vehiclesBox.clear();
    await HiveRegistrar.maintenanceBox.clear();
    await HiveRegistrar.serviceHistoryBox.clear();
    await HiveRegistrar.ridesBox.clear();
    await HiveRegistrar.settingsBox.clear();
  }
}
