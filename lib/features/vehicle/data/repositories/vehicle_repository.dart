import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/database/hive_registrar.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/vehicle_model.dart';

/// Repository for handling vehicle CRUD with offline-first Hive and remote Supabase
class VehicleRepository {
  final SupabaseService _supabaseService;
  Box<VehicleModel> get _box => HiveRegistrar.vehiclesBox;
  Box<dynamic> get _settingsBox => HiveRegistrar.settingsBox;

  static const String _activeVehicleKey = 'active_vehicle_id';

  VehicleRepository([SupabaseService? supabaseService])
      : _supabaseService = supabaseService ?? SupabaseService();

  List<VehicleModel> getAllVehicles() {
    return _box.values.toList();
  }

  /// Offline-first getVehicles:
  /// Reads from local Hive box first, then attempts background sync from Supabase.
  Future<List<VehicleModel>> getVehicles({bool forceRemote = false}) async {
    final localList = getAllVehicles();

    if (!SupabaseConfig.isInitialized) {
      return localList;
    }

    try {
      final remoteRows = await _supabaseService.getData(
        'vehicles',
        orderBy: 'created_at',
        ascending: false,
      );

      // Attempt fetching specs if present
      List<Map<String, dynamic>> specsRows = [];
      try {
        specsRows = await _supabaseService.getData('vehicle_specs');
      } catch (e) {
        debugPrint('vehicle_specs fetch skipped: $e');
      }

      final specsMap = {
        for (final s in specsRows) (s['vehicle_id']?.toString() ?? ''): s,
      };

      final remoteVehicles = remoteRows.map((row) {
        final vehicleId = row['id']?.toString() ?? '';
        final specs = specsMap[vehicleId];
        return VehicleModel.fromJson(row, specs);
      }).toList();

      // Upsert into local Hive box
      for (final v in remoteVehicles) {
        await _box.put(v.id, v);
      }

      // Auto-select active vehicle if none exists
      if (getActiveVehicleId() == null && remoteVehicles.isNotEmpty) {
        await setActiveVehicleId(remoteVehicles.first.id);
      }

      return getAllVehicles();
    } on PostgrestException catch (e) {
      debugPrint('Supabase getVehicles error: ${e.message}');
      return localList;
    } catch (e) {
      debugPrint('VehicleRepository.getVehicles fallback to local: $e');
      return localList;
    }
  }

  VehicleModel? getVehicleById(String id) {
    return _box.get(id);
  }

  /// Create vehicle: saves to local Hive first, then syncs to Supabase
  Future<VehicleModel> createVehicle(VehicleModel vehicle) async {
    try {
      // 1. Save to local Hive database (offline-first guarantee)
      await _box.put(vehicle.id, vehicle);

      // Set active vehicle if none is active
      if (getActiveVehicleId() == null) {
        await setActiveVehicleId(vehicle.id);
      }

      // 2. Sync to Supabase
      if (SupabaseConfig.isInitialized) {
        try {
          await _supabaseService.insertData('vehicles', vehicle.toJson());

          // Insert specs if any are provided
          if (vehicle.fuelType != null || vehicle.transmission != null || vehicle.color != null) {
            try {
              await _supabaseService.insertData('vehicle_specs', vehicle.toSpecsJson());
            } catch (e) {
              debugPrint('Warning: vehicle_specs insert failed: $e');
            }
          }
        } on PostgrestException catch (e) {
          throw 'Gagal sinkronisasi ke Supabase: ${e.message}';
        }
      }

      return vehicle;
    } catch (e) {
      if (e is String) rethrow;
      throw 'Terjadi kesalahan saat menambah kendaraan: $e';
    }
  }

  /// Alias for backward compatibility with legacy screen callers
  Future<void> saveVehicle(VehicleModel vehicle) async {
    await createVehicle(vehicle);
  }

  /// Update vehicle: updates in local Hive first, then syncs to Supabase
  Future<VehicleModel> updateVehicle(VehicleModel vehicle) async {
    try {
      // 1. Update in local Hive database
      await _box.put(vehicle.id, vehicle);

      // 2. Sync update to Supabase
      if (SupabaseConfig.isInitialized) {
        try {
          await _supabaseService.updateData(
            'vehicles',
            vehicle.toJson(),
            matchColumn: 'id',
            matchValue: vehicle.id,
          );

          // Update specs if any
          if (vehicle.fuelType != null || vehicle.transmission != null || vehicle.color != null) {
            try {
              final existingSpecs = await _supabaseService.getData(
                'vehicle_specs',
                match: {'vehicle_id': vehicle.id},
              );
              if (existingSpecs.isNotEmpty) {
                await _supabaseService.updateData(
                  'vehicle_specs',
                  vehicle.toSpecsJson(),
                  matchColumn: 'vehicle_id',
                  matchValue: vehicle.id,
                );
              } else {
                await _supabaseService.insertData('vehicle_specs', vehicle.toSpecsJson());
              }
            } catch (e) {
              debugPrint('Warning: vehicle_specs update skipped: $e');
            }
          }
        } on PostgrestException catch (e) {
          throw 'Gagal memperbarui di Supabase: ${e.message}';
        }
      }

      return vehicle;
    } catch (e) {
      if (e is String) rethrow;
      throw 'Terjadi kesalahan saat memperbarui kendaraan: $e';
    }
  }

  /// Delete vehicle: deletes from local Hive and Supabase
  Future<void> deleteVehicle(String id) async {
    try {
      // 1. Delete from local Hive database
      await _box.delete(id);

      // Handle active vehicle reassignment if active vehicle was deleted
      if (getActiveVehicleId() == id) {
        final remaining = getAllVehicles();
        if (remaining.isNotEmpty) {
          await setActiveVehicleId(remaining.first.id);
        } else {
          await _settingsBox.delete(_activeVehicleKey);
        }
      }

      // 2. Delete from Supabase
      if (SupabaseConfig.isInitialized) {
        try {
          try {
            await _supabaseService.deleteData(
              'vehicle_specs',
              matchColumn: 'vehicle_id',
              matchValue: id,
            );
          } catch (_) {}

          await _supabaseService.deleteData(
            'vehicles',
            matchColumn: 'id',
            matchValue: id,
          );
        } on PostgrestException catch (e) {
          throw 'Gagal menghapus di Supabase: ${e.message}';
        }
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Terjadi kesalahan saat menghapus kendaraan: $e';
    }
  }

  Future<void> updateOdometer(String vehicleId, double newKm) async {
    final vehicle = _box.get(vehicleId);
    if (vehicle != null) {
      if (newKm >= vehicle.currentOdometer) {
        vehicle.currentOdometer = newKm.round();
        await vehicle.save();
        if (SupabaseConfig.isInitialized) {
          try {
            await _supabaseService.updateData(
              'vehicles',
              {'current_odometer': vehicle.currentOdometer},
              matchColumn: 'id',
              matchValue: vehicleId,
            );
          } catch (e) {
            debugPrint('Background sync odometer failed: $e');
          }
        }
      }
    }
  }

  String? getActiveVehicleId() {
    final id = _settingsBox.get(_activeVehicleKey) as String?;
    if (id != null && _box.containsKey(id)) {
      return id;
    }
    if (_box.isNotEmpty) {
      final firstId = _box.values.first.id;
      _settingsBox.put(_activeVehicleKey, firstId);
      return firstId;
    }
    return null;
  }

  Future<void> setActiveVehicleId(String id) async {
    await _settingsBox.put(_activeVehicleKey, id);
  }

  VehicleModel? getActiveVehicle() {
    final activeId = getActiveVehicleId();
    if (activeId == null) return null;
    return getVehicleById(activeId);
  }
}
