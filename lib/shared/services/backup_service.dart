import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/database/hive_registrar.dart';
import '../../features/maintenance/data/models/maintenance_item_model.dart';
import '../../features/maintenance/data/models/service_log_model.dart';
import '../../features/ride_tracking/data/models/ride_session_model.dart';
import '../../features/vehicle/data/models/vehicle_model.dart';

/// DTO representasi hasil impor berkas cadangan
class ImportResult {
  final bool success;
  final String message;
  final int vehiclesCount;
  final int ridesCount;
  final int servicesCount;
  final int maintenanceCount;

  const ImportResult({
    required this.success,
    required this.message,
    this.vehiclesCount = 0,
    this.ridesCount = 0,
    this.servicesCount = 0,
    this.maintenanceCount = 0,
  });
}

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

    // Export vehicle maintenance and service records cache from settingsBox
    final vehicleMaintenanceMap = <String, dynamic>{};
    for (final key in HiveRegistrar.settingsBox.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith('vehicle_maintenance_') ||
          keyStr.startsWith('service_records_')) {
        vehicleMaintenanceMap[keyStr] = HiveRegistrar.settingsBox.get(key);
      }
    }

    final exportData = {
      'app': 'RideCare',
      'version': '1.0.0-PROD',
      'exportedAt': DateTime.now().toIso8601String(),
      'vehicles': vehicles,
      'maintenance': maintenance,
      'service_history': serviceHistory,
      'rides': rides,
      if (vehicleMaintenanceMap.isNotEmpty) 'vehicle_maintenance': vehicleMaintenanceMap,
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

  /// Opens native file picker dialog to select a JSON backup file and restores data into Hive
  static Future<ImportResult?> pickAndImportDatabase() async {
    const typeGroup = XTypeGroup(
      label: 'JSON Files (*.json)',
      extensions: <String>['json'],
    );

    final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file == null) {
      return null;
    }

    final jsonString = await file.readAsString();
    return await importDatabase(jsonString);
  }

  /// Restores database data from JSON string
  static Future<ImportResult> importDatabase(String jsonString) async {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const ImportResult(
          success: false,
          message: 'Format berkas tidak valid. Berkas JSON harus berupa data RideCare.',
        );
      }

      int vCount = 0;
      int mCount = 0;
      int sCount = 0;
      int rCount = 0;

      // 1. Vehicles
      if (decoded['vehicles'] is List) {
        for (final item in decoded['vehicles']) {
          try {
            final v = VehicleModel.fromJson(Map<String, dynamic>.from(item as Map));
            await HiveRegistrar.vehiclesBox.put(v.id, v);
            vCount++;
          } catch (e) {
            debugPrint('Error importing vehicle: $e');
          }
        }
      }

      // 2. Maintenance Items
      if (decoded['maintenance'] is List) {
        for (final item in decoded['maintenance']) {
          try {
            final m = MaintenanceItemModel.fromJson(Map<String, dynamic>.from(item as Map));
            await HiveRegistrar.maintenanceBox.put(m.id, m);
            mCount++;
          } catch (e) {
            debugPrint('Error importing maintenance item: $e');
          }
        }
      }

      // 3. Service History
      if (decoded['service_history'] is List) {
        for (final item in decoded['service_history']) {
          try {
            final s = ServiceLogModel.fromJson(Map<String, dynamic>.from(item as Map));
            await HiveRegistrar.serviceHistoryBox.put(s.id, s);
            sCount++;
          } catch (e) {
            debugPrint('Error importing service log: $e');
          }
        }
      }

      // 4. Rides
      if (decoded['rides'] is List) {
        for (final item in decoded['rides']) {
          try {
            final r = RideSessionModel.fromJson(Map<String, dynamic>.from(item as Map));
            await HiveRegistrar.ridesBox.put(r.id, r);
            rCount++;
          } catch (e) {
            debugPrint('Error importing ride: $e');
          }
        }
      }

      // 5. Vehicle Maintenance Cache in settingsBox
      if (decoded['vehicle_maintenance'] is Map) {
        final map = decoded['vehicle_maintenance'] as Map;
        for (final entry in map.entries) {
          await HiveRegistrar.settingsBox.put(entry.key, entry.value);
        }
      }

      // 6. Set active vehicle if none selected
      final allVehicles = HiveRegistrar.vehiclesBox.values.toList();
      if (allVehicles.isNotEmpty) {
        final currentActive = HiveRegistrar.settingsBox.get('active_vehicle_id');
        if (currentActive == null || !allVehicles.any((v) => v.id == currentActive)) {
          await HiveRegistrar.settingsBox.put('active_vehicle_id', allVehicles.first.id);
        }
      }

      if (vCount == 0 && mCount == 0 && sCount == 0 && rCount == 0) {
        return const ImportResult(
          success: false,
          message: 'Berkas cadangan tidak memuat data kendaraan atau servis yang dapat dipulihkan.',
        );
      }

      return ImportResult(
        success: true,
        message: 'Berhasil memulihkan $vCount kendaraan, $sCount riwayat servis, dan $rCount perjalanan.',
        vehiclesCount: vCount,
        servicesCount: sCount,
        ridesCount: rCount,
        maintenanceCount: mCount,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Gagal mengimpor berkas cadangan: $e',
      );
    }
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
