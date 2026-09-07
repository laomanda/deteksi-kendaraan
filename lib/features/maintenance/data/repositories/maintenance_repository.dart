import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/hive_registrar.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/maintenance_catalog_model.dart';
import '../models/maintenance_item_model.dart';
import '../models/maintenance_price_model.dart';
import '../models/service_log_model.dart';
import '../models/service_record_model.dart';
import '../models/vehicle_maintenance_model.dart';

class MaintenanceRepository {
  Box<MaintenanceItemModel> get _box => HiveRegistrar.maintenanceBox;
  Box<ServiceLogModel> get _historyBox => HiveRegistrar.serviceHistoryBox;
  Box<dynamic> get _settingsBox => HiveRegistrar.settingsBox;
  final SupabaseService _supabaseService = SupabaseService();

  // -------------------------------------------------------------
  // 1. MAINTENANCE CATALOG (Supabase 'maintenance_catalog')
  // -------------------------------------------------------------

  /// Mengambil katalog maintenance berdasarkan tipe kendaraan (motorcycle / car).
  /// Offline-first: membaca dari default lokal/cache Hive, lalu background sync ke Supabase jika online.
  Future<List<MaintenanceCatalogModel>> getCatalog({
    String vehicleType = 'motorcycle',
  }) async {
    final type = vehicleType.toLowerCase();
    final cacheKey = 'catalog_cache_$type';

    // 1. Coba baca dari Hive cache
    final cached = _settingsBox.get(cacheKey);
    List<MaintenanceCatalogModel> localList = [];

    if (cached != null && cached is List) {
      try {
        localList = cached
            .map((e) => MaintenanceCatalogModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (e) {
        debugPrint('Error parsing cached catalog: $e');
      }
    }

    if (localList.isEmpty) {
      localList = MaintenanceCatalogModel.getDefaultCatalogForType(type);
    }

    // 2. Background sync dari Supabase jika terhubung
    if (SupabaseConfig.isInitialized) {
      _syncCatalogFromSupabase(type, cacheKey);
    }

    return localList;
  }

  Future<void> _syncCatalogFromSupabase(String vehicleType, String cacheKey) async {
    try {
      final remoteData = await _supabaseService.getData(
        'maintenance_catalog',
        match: {'vehicle_type': vehicleType},
      );

      if (remoteData.isNotEmpty) {
        final parsed = remoteData
            .map((e) => MaintenanceCatalogModel.fromJson(e))
            .toList();
        await _settingsBox.put(cacheKey, remoteData);
        debugPrint('Catalog synced from Supabase: ${parsed.length} items');
      } else {
        // Jika di Supabase masih kosong, lakukan seeding master data default
        final defaults = MaintenanceCatalogModel.getDefaultCatalogForType(vehicleType);
        for (final item in defaults) {
          try {
            await _supabaseService.insertData('maintenance_catalog', item.toJson());
          } catch (e) {
            // Abaikan jika sudah ada atau RLS read-only
          }
        }
      }
    } catch (e) {
      debugPrint('Background sync catalog failed: $e');
    }
  }

  // -------------------------------------------------------------
  // 2. MAINTENANCE COST LIBRARY (Supabase 'maintenance_prices')
  // -------------------------------------------------------------

  /// Mengambil master library estimasi harga
  Future<List<MaintenancePriceModel>> getPrices({
    String vehicleType = 'motorcycle',
  }) async {
    final type = vehicleType.toLowerCase();
    final cacheKey = 'prices_cache_$type';

    final cached = _settingsBox.get(cacheKey);
    List<MaintenancePriceModel> localList = [];

    if (cached != null && cached is List) {
      try {
        localList = cached
            .map((e) => MaintenancePriceModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (e) {
        debugPrint('Error parsing cached prices: $e');
      }
    }

    if (localList.isEmpty) {
      localList = MaintenancePriceModel.defaultPrices
          .where((p) => p.vehicleType.toLowerCase() == type)
          .toList();
    }

    // Background sync jika online
    if (SupabaseConfig.isInitialized) {
      _syncPricesFromSupabase(type, cacheKey);
    }

    return localList;
  }

  Future<void> _syncPricesFromSupabase(String vehicleType, String cacheKey) async {
    try {
      final remoteData = await _supabaseService.getData(
        'maintenance_prices',
        match: {'vehicle_type': vehicleType},
      );
      if (remoteData.isNotEmpty) {
        await _settingsBox.put(cacheKey, remoteData);
      }
    } catch (e) {
      debugPrint('Background sync prices failed: $e');
    }
  }

  /// Mencari estimasi harga untuk komponen tertentu
  MaintenancePriceModel? getEstimatedPrice(
    String maintenanceIdOrName, {
    String vehicleType = 'motorcycle',
  }) {
    return MaintenancePriceModel.getPriceForMaintenance(
      maintenanceIdOrName,
      vehicleType: vehicleType,
    );
  }

  // -------------------------------------------------------------
  // 3. VEHICLE MAINTENANCE (Supabase 'vehicle_maintenance')
  // -------------------------------------------------------------

  /// Mengambil data maintenance tersimpan di Hive secara sinkron
  List<VehicleMaintenanceModel>? getCachedVehicleMaintenance(String vehicleId) {
    final storageKey = 'vehicle_maintenance_$vehicleId';
    final cached = _settingsBox.get(storageKey);
    if (cached != null && cached is List) {
      try {
        return cached
            .map((e) => VehicleMaintenanceModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (e) {
        debugPrint('Error parsing vehicle maintenance cache: $e');
      }
    }
    return null;
  }

  /// Mengambil data maintenance aktif untuk suatu kendaraan.
  /// Jika belum ada, otomatis di-generate berdasarkan katalog tipe kendaraan.
  Future<List<VehicleMaintenanceModel>> getVehicleMaintenance(
    String vehicleId, {
    String vehicleType = 'motorcycle',
    int currentOdometer = 0,
  }) async {
    final storageKey = 'vehicle_maintenance_$vehicleId';
    final cached = _settingsBox.get(storageKey);

    List<VehicleMaintenanceModel> items = [];

    if (cached != null && cached is List) {
      try {
        items = cached
            .map((e) => VehicleMaintenanceModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (e) {
        debugPrint('Error parsing vehicle maintenance cache: $e');
      }
    }

    // Jika belum ada data lokal untuk kendaraan ini, buat item awal berdasarkan katalog
    if (items.isEmpty) {
      final catalog = await getCatalog(vehicleType: vehicleType);
      const uuid = Uuid();
      final now = DateTime.now();

      items = catalog.map((cat) {
        return VehicleMaintenanceModel(
          id: uuid.v4(),
          vehicleId: vehicleId,
          maintenanceId: cat.id,
          lastServiceDate: now,
          lastServiceOdometer: 0,
          healthPercentage: 100,
          status: 'GOOD',
          itemName: cat.name,
          itemCategory: cat.category,
          intervalKm: cat.defaultIntervalKm,
          intervalMonth: cat.defaultIntervalMonth,
        );
      }).toList();

      // Simpan ke Hive lokal segera
      await _settingsBox.put(
        storageKey,
        items.map((it) => it.toLocalJson()).toList(),
      );

      // Sinkronisasi insert ke Supabase jika terhubung
      if (SupabaseConfig.isInitialized) {
        for (final it in items) {
          try {
            await _supabaseService.insertData('vehicle_maintenance', it.toJson());
          } catch (e) {
            debugPrint('Background insert vehicle_maintenance skipped/failed: $e');
          }
        }
      }
    }

    return items;
  }

  /// Memperbarui satu item vehicle_maintenance
  Future<void> updateVehicleMaintenance(VehicleMaintenanceModel item) async {
    final storageKey = 'vehicle_maintenance_${item.vehicleId}';
    final cached = _settingsBox.get(storageKey);
    List<VehicleMaintenanceModel> items = [];

    if (cached != null && cached is List) {
      items = cached
          .map((e) => VehicleMaintenanceModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    final index = items.indexWhere((it) => it.id == item.id || it.maintenanceId == item.maintenanceId);
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }

    // Update Hive
    await _settingsBox.put(
      storageKey,
      items.map((it) => it.toLocalJson()).toList(),
    );

    // Background sync Supabase
    if (SupabaseConfig.isInitialized) {
      try {
        await _supabaseService.updateData(
          'vehicle_maintenance',
          item.toJson(),
          matchColumn: 'id',
          matchValue: item.id,
        );
      } catch (e) {
        debugPrint('Supabase vehicle_maintenance update failed: $e');
      }
    }
  }

  // -------------------------------------------------------------
  // 4. SERVICE RECORDS (Supabase 'service_records')
  // -------------------------------------------------------------

  /// Mengambil seluruh riwayat servis suatu kendaraan
  Future<List<ServiceRecordModel>> getServiceRecords(String vehicleId) async {
    final storageKey = 'service_records_$vehicleId';
    final cached = _settingsBox.get(storageKey);
    List<ServiceRecordModel> list = [];

    if (cached != null && cached is List) {
      try {
        list = cached
            .map((e) => ServiceRecordModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (e) {
        debugPrint('Error parsing service records cache: $e');
      }
    }

    // Sort descending berdasarkan tanggal
    list.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

    // Background sync jika online
    if (SupabaseConfig.isInitialized) {
      _syncServiceRecordsFromSupabase(vehicleId, storageKey);
    }

    return list;
  }

  Future<void> _syncServiceRecordsFromSupabase(String vehicleId, String storageKey) async {
    try {
      final remote = await _supabaseService.getData(
        'service_records',
        match: {'vehicle_id': vehicleId},
      );
      if (remote.isNotEmpty) {
        await _settingsBox.put(storageKey, remote);
      }
    } catch (e) {
      debugPrint('Background sync service records failed: $e');
    }
  }

  /// Menambahkan riwayat servis baru:
  /// 1. Simpan ke Hive lokal
  /// 2. Perbarui status vehicle_maintenance menjadi 100% dan odometer terakhir
  /// 3. Perbarui current odometer kendaraan jika odometer servis lebih tinggi
  /// 4. Sync ke Supabase (service_records & vehicle_maintenance)
  Future<ServiceRecordModel> addServiceRecord(ServiceRecordModel record) async {
    // 1. Simpan record ke Hive
    final storageKey = 'service_records_${record.vehicleId}';
    final cached = _settingsBox.get(storageKey);
    List<Map<String, dynamic>> recordsList = [];

    if (cached != null && cached is List) {
      recordsList = cached.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    recordsList.insert(0, record.toLocalJson());
    await _settingsBox.put(storageKey, recordsList);

    // Simpan juga ke legacy historyBox untuk interoperabilitas
    final legacyLog = ServiceLogModel(
      id: record.id,
      vehicleId: record.vehicleId,
      componentType: record.maintenanceName ?? record.maintenanceId ?? 'Service',
      serviceKm: record.odometer.toDouble(),
      serviceDate: record.serviceDate,
      cost: record.cost,
      notes: record.notes ?? '',
    );
    await _historyBox.put(legacyLog.id, legacyLog);

    // 2. Perbarui item vehicle_maintenance terkait
    final vmList = await getVehicleMaintenance(record.vehicleId);
    final targetItemIndex = vmList.indexWhere(
      (it) => it.id == record.maintenanceId ||
              it.maintenanceId == record.maintenanceId ||
              (it.itemName != null && it.itemName == record.maintenanceName),
    );

    if (targetItemIndex >= 0) {
      final target = vmList[targetItemIndex];
      final updatedItem = target.copyWith(
        lastServiceOdometer: record.odometer,
        lastServiceDate: record.serviceDate,
        healthPercentage: 100,
        status: 'GOOD',
        updatedAt: DateTime.now(),
      );
      await updateVehicleMaintenance(updatedItem);
    }

    // 3. Sync ke Supabase (service_records)
    if (SupabaseConfig.isInitialized) {
      try {
        await _supabaseService.insertData('service_records', record.toJson());
        debugPrint('Service record synced to Supabase successfully: ${record.id}');
      } catch (e) {
        debugPrint('Supabase insert service_records skipped/pending: $e');
      }
    }

    return record;
  }

  // -------------------------------------------------------------
  // LEGACY COMPATIBILITY METHODS (PRD Section 13)
  // -------------------------------------------------------------

  List<MaintenanceItemModel> getItemsForVehicle(String vehicleId) {
    return _box.values.where((item) => item.vehicleId == vehicleId).toList();
  }

  Future<void> saveItems(List<MaintenanceItemModel> items) async {
    final map = <String, MaintenanceItemModel>{
      for (final item in items) item.id: item,
    };
    await _box.putAll(map);
  }

  Future<void> updateItem(MaintenanceItemModel item) async {
    await _box.put(item.id, item);
  }

  Future<void> deleteItemsForVehicle(String vehicleId) async {
    final keysToDelete = _box.values
        .where((item) => item.vehicleId == vehicleId)
        .map((item) => item.id)
        .toList();
    await _box.deleteAll(keysToDelete);

    final historyKeysToDelete = _historyBox.values
        .where((log) => log.vehicleId == vehicleId)
        .map((log) => log.id)
        .toList();
    await _historyBox.deleteAll(historyKeysToDelete);

    await _settingsBox.delete('vehicle_maintenance_$vehicleId');
    await _settingsBox.delete('service_records_$vehicleId');
  }

  List<ServiceLogModel> getServiceHistoryForVehicle(String vehicleId) {
    final logs = _historyBox.values
        .where((log) => log.vehicleId == vehicleId)
        .toList();
    logs.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    return logs;
  }

  Future<ServiceLogModel> recordService({
    required String vehicleId,
    required String componentType,
    required double serviceKm,
    required DateTime serviceDate,
    required double cost,
    required String notes,
  }) async {
    const uuid = Uuid();
    final newId = uuid.v4();

    // Map to new ServiceRecordModel
    final newRecord = ServiceRecordModel(
      id: newId,
      vehicleId: vehicleId,
      maintenanceId: componentType,
      serviceDate: serviceDate,
      odometer: serviceKm.round(),
      cost: cost,
      notes: notes,
      maintenanceName: componentType,
    );

    await addServiceRecord(newRecord);

    return ServiceLogModel(
      id: newId,
      vehicleId: vehicleId,
      componentType: componentType,
      serviceKm: serviceKm,
      serviceDate: serviceDate,
      cost: cost,
      notes: notes,
    );
  }

  Future<List<Map<String, dynamic>>> getMaintenanceCatalog() async {
    try {
      final supabase = SupabaseRegistrar.service;
      return await supabase.getData('maintenance_catalog');
    } catch (e) {
      return [];
    }
  }

  Future<List<ServiceLogModel>> getServiceHistory([String? vehicleId]) async {
    if (vehicleId != null) {
      return getServiceHistoryForVehicle(vehicleId);
    }
    final logs = _historyBox.values.toList();
    logs.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    return logs;
  }
}

class SupabaseRegistrar {
  static final service = SupabaseService();
}
