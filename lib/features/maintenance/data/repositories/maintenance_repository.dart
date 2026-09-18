import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/hive_registrar.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../vehicle/data/models/vehicle_category_model.dart';
import '../../../vehicle/data/models/vehicle_model.dart';
import '../../../vehicle/domain/vehicle_intelligence_service.dart';
import '../../domain/dashboard_maintenance_item.dart';
import '../../domain/maintenance_calculator.dart';
import '../../domain/vehicle_maintenance_service.dart';
import '../models/maintenance_catalog_model.dart';
import '../models/maintenance_item_model.dart';
import '../models/maintenance_price_model.dart';
import '../models/maintenance_template_model.dart';
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
        final parsed = cached
            .map((e) => VehicleMaintenanceModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        final vehicle = HiveRegistrar.vehiclesBox.get(vehicleId);
        if (vehicle != null) {
          return VehicleMaintenanceService.sanitizeAndValidate(
            vehicle: vehicle,
            rawItems: parsed,
          );
        }
        return parsed;
      } catch (e) {
        debugPrint('Error parsing vehicle maintenance cache: $e');
      }
    }
    return null;
  }

  // -------------------------------------------------------------
  // 1B. VEHICLE INTELLIGENCE LAYER (Categories & Templates)
  // -------------------------------------------------------------

  /// Mengambil daftar kategori kendaraan (offline first dengan background Supabase sync)
  Future<List<VehicleCategoryModel>> getVehicleCategories({String? vehicleType}) async {
    const cacheKey = 'vehicle_categories_cache';
    final cached = _settingsBox.get(cacheKey);
    List<VehicleCategoryModel> localList = [];

    if (cached != null && cached is List) {
      try {
        localList = cached
            .map((e) => VehicleCategoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (e) {
        debugPrint('Error parsing cached vehicle categories: $e');
      }
    }

    if (localList.isEmpty) {
      localList = VehicleCategoryModel.defaultCategories;
    }

    if (vehicleType != null) {
      localList = localList.where((c) => c.vehicleType == vehicleType).toList();
    }

    if (SupabaseConfig.isInitialized) {
      _syncCategoriesFromSupabase(cacheKey);
    }

    return localList;
  }

  Future<void> _syncCategoriesFromSupabase(String cacheKey) async {
    try {
      final remoteData = await _supabaseService.getData('vehicle_categories');
      if (remoteData.isNotEmpty) {
        await _settingsBox.put(cacheKey, remoteData);
      }
    } catch (e) {
      debugPrint('Background sync vehicle_categories skipped: $e');
    }
  }

  /// Mengambil template maintenance berdasarkan categoryId
  Future<List<MaintenanceTemplateModel>> getMaintenanceTemplates(String? categoryId) async {
    final cacheKey = 'templates_cache_${categoryId ?? 'all'}';
    final cached = _settingsBox.get(cacheKey);
    List<MaintenanceTemplateModel> localList = [];

    if (cached != null && cached is List) {
      try {
        localList = cached
            .map((e) => MaintenanceTemplateModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (e) {
        debugPrint('Error parsing cached templates: $e');
      }
    }

    if (localList.isEmpty) {
      localList = MaintenanceTemplateModel.getTemplatesForCategory(categoryId ?? '');
    }

    if (SupabaseConfig.isInitialized) {
      _syncTemplatesFromSupabase(categoryId, cacheKey);
    }

    return localList;
  }

  Future<void> _syncTemplatesFromSupabase(String? categoryId, String cacheKey) async {
    try {
      final match = categoryId != null ? {'category_id': categoryId} : null;
      final remoteData = await _supabaseService.getData('maintenance_templates', match: match);
      if (remoteData.isNotEmpty) {
        await _settingsBox.put(cacheKey, remoteData);
      }
    } catch (e) {
      debugPrint('Background sync maintenance_templates skipped: $e');
    }
  }

  /// Mengambil data maintenance aktif untuk suatu kendaraan.
  /// Memproses melalui pipeline: User Vehicle -> vehicle_catalog -> maintenance_profile_id -> maintenance_rules -> components
  Future<List<VehicleMaintenanceModel>> getVehicleMaintenance(
    String vehicleId, {
    String vehicleType = 'motorcycle',
    String? vehicleCategoryId,
    int currentOdometer = 0,
    bool forceRemote = false,
  }) async {
    final storageKey = 'vehicle_maintenance_$vehicleId';
    final cached = _settingsBox.get(storageKey);

    List<VehicleMaintenanceModel> items = [];

    // 1. Offline-First: Baca dari Hive local cache terlebih dahulu
    if (cached != null && cached is List) {
      try {
        items = cached
            .map((e) => VehicleMaintenanceModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (e) {
        debugPrint('Error parsing vehicle maintenance cache: $e');
      }
    }

    // Ambil atau construct model vehicle
    final vehicle = HiveRegistrar.vehiclesBox.get(vehicleId) ??
        VehicleModel(
          id: vehicleId,
          vehicleType: vehicleType,
          brand: 'Vehicle',
          model: 'Model',
          year: DateTime.now().year,
          vehicleCategoryId: vehicleCategoryId,
          currentOdometer: currentOdometer,
        );

    // 2. Jika online dan Supabase terhubung, jalankan Join Query:
    // vehicle_maintenance JOIN vehicles JOIN maintenance_rules JOIN components
    if (SupabaseConfig.isInitialized) {
      try {
        final query = AppSupabaseClient.instance.client
            .from('vehicle_maintenance')
            .select('''
              id,
              vehicle_id,
              maintenance_id,
              last_service_date,
              last_service_odometer,
              health_percentage,
              status,
              vehicles (id, brand, model, year, vehicle_type, current_odometer, vehicle_category_id),
              maintenance_rules (
                id,
                profile_id,
                component_id,
                interval_km,
                priority,
                components (id, name, category, description)
              )
            ''')
            .eq('vehicle_id', vehicleId);

        final response = await query.timeout(const Duration(seconds: 5));
        if (response.isNotEmpty) {
          final remoteItems = response
              .map((row) => VehicleMaintenanceModel.fromJson(Map<String, dynamic>.from(row as Map)))
              .toList();
          if (remoteItems.isNotEmpty) {
            items = remoteItems;
          }
        }
      } catch (e, st) {
        final appEx = AppSupabaseClient.instance.handleException(e, st);
        debugPrint('Supabase vehicle_maintenance fetch notice (offline/fallback): $appEx');
      }
    }

    // 3. Pipeline: Sanitize & Validate against vehicle maintenance profile rules
    final sanitizedItems = VehicleMaintenanceService.sanitizeAndValidate(
      vehicle: vehicle,
      rawItems: items,
    );

    // 4. Hitung status realtime menggunakan MaintenanceCalculator
    final validatedList = sanitizedItems.map((it) {
      final calc = MaintenanceCalculator.calculate(
        currentOdometer: vehicle.currentOdometer,
        intervalKm: it.effectiveIntervalKm,
        lastServiceOdometer: it.lastServiceOdometer,
        hasMaintenanceHistory: it.hasServiceHistory,
      );
      return it.copyWith(
        healthPercentage: calc.healthPercentage,
        status: calc.status,
      );
    }).toList();

    // 5. Simpan / perbarui ke Hive lokal
    await _settingsBox.put(
      storageKey,
      validatedList.map((it) => it.toLocalJson()).toList(),
    );

    // 6. Sinkronisasi insert ke Supabase jika remote kosong
    if (SupabaseConfig.isInitialized && items.isEmpty && validatedList.isNotEmpty) {
      for (final it in validatedList) {
        try {
          await _supabaseService.insertData('vehicle_maintenance', it.toJson());
        } catch (e) {
          debugPrint('Background sync vehicle_maintenance insert notice: $e');
        }
      }
    }

    return validatedList;
  }

  /// Mengambil data maintenance dalam bentuk UI Data Contract (DashboardMaintenanceItem)
  /// Menggunakan query join dan MaintenanceCalculator untuk status realtime
  Future<List<DashboardMaintenanceItem>> getDashboardMaintenance(String vehicleId) async {
    final vehicle = HiveRegistrar.vehiclesBox.get(vehicleId);
    final vmList = await getVehicleMaintenance(
      vehicleId,
      vehicleType: vehicle?.vehicleType ?? 'motorcycle',
      vehicleCategoryId: vehicle?.vehicleCategoryId,
      currentOdometer: vehicle?.currentOdometer ?? 0,
    );

    final currentOdo = vehicle?.currentOdometer ?? 0;

    return vmList.map((vm) {
      final int interval = vm.effectiveIntervalKm;
      final calc = MaintenanceCalculator.calculate(
        currentOdometer: currentOdo,
        intervalKm: interval,
        lastServiceOdometer: vm.lastServiceOdometer,
        hasMaintenanceHistory: vm.hasServiceHistory,
      );

      final name = vm.name.isNotEmpty ? vm.name : vm.maintenanceId;
      final desc = vm.maintenanceRule?.description ??
          'Jadwal servis setiap $interval KM';

      return DashboardMaintenanceItem(
        componentName: name,
        description: desc,
        intervalKm: interval,
        currentOdometer: currentOdo,
        nextServiceKm: calc.nextServiceKm,
        remainingKm: calc.remainingKm,
        healthPercentage: calc.healthPercentage,
        status: calc.status,
        priority: vm.maintenanceRule?.priority ?? 'medium',
        maintenanceId: vm.maintenanceId,
      );
    }).toList();
  }

  /// Mengambil detail maintenance untuk suatu kendaraan (Requirement 3)
  Future<DashboardMaintenanceItem?> getMaintenanceDetail(
    String vehicleId, [
    String? maintenanceId,
  ]) async {
    final list = await getDashboardMaintenance(vehicleId);
    if (list.isEmpty) return null;

    if (maintenanceId != null && maintenanceId.isNotEmpty) {
      return list.where((it) => it.maintenanceId == maintenanceId).firstOrNull ??
          list.first;
    }

    // Default return item paling kritis / urgent (remaining km terkecil)
    final sorted = [...list]..sort((a, b) => a.remainingKm.compareTo(b.remainingKm));
    return sorted.first;
  }

  /// Menginisialisasi item maintenance kendaraan baru berdasarkan kondisi awal yang dipilih:
  /// 1. Prediksi Otomatis (health 100%, baseline = current_odometer)
  /// 2. Input Riwayat Servis (kalkulasi normal berdasarkan last_service_odometer)
  /// 3. Semua Komponen Kondisi Baik (health 100%, baseline = current_odometer)
  Future<List<VehicleMaintenanceModel>> initializeVehicleMaintenance({
    required VehicleModel vehicle,
    VehicleInitialCondition? initialCondition,
    int? lastServiceOdometer,
    DateTime? lastServiceDate,
  }) async {
    final condition = initialCondition ??
        vehicle.initialConditionOption;

    final storageKey = 'vehicle_maintenance_${vehicle.id}';
    final items = VehicleIntelligenceService.generateMaintenanceItems(
      vehicle: vehicle,
      initialCondition: condition,
      lastServiceOdometer: lastServiceOdometer,
      lastServiceDate: lastServiceDate,
    );

    // 1. Simpan ke Hive cache lokal
    await _settingsBox.put(
      storageKey,
      items.map((it) => it.toLocalJson()).toList(),
    );

    // 2. Jika user memasukkan riwayat servis awal, buat ServiceRecord awal di histori
    if (condition == VehicleInitialCondition.serviceHistory &&
        lastServiceOdometer != null &&
        lastServiceOdometer > 0) {
      final initialRecord = ServiceRecordModel(
        id: const Uuid().v4(),
        vehicleId: vehicle.id,
        serviceDate: lastServiceDate ?? DateTime.now(),
        odometer: lastServiceOdometer,
        maintenanceName: 'Servis Terakhir (Baseline Awal)',
        cost: 0.0,
        notes: 'Riwayat servis awal dimasukkan saat registrasi kendaraan.',
        workshop: 'Bengkel Sebelumnya',
      );
      final recKey = 'service_records_${vehicle.id}';
      final cachedRecs = _settingsBox.get(recKey);
      List<Map<String, dynamic>> recordsList = [];
      if (cachedRecs != null && cachedRecs is List) {
        recordsList = cachedRecs.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      recordsList.insert(0, initialRecord.toLocalJson());
      await _settingsBox.put(recKey, recordsList);

      if (SupabaseConfig.isInitialized) {
        try {
          await _supabaseService.insertData('service_records', initialRecord.toJson());
        } catch (e) {
          debugPrint('Supabase initial service record sync notice: $e');
        }
      }
    }

    // 3. Sinkronisasi ke Supabase jika terhubung (batch insert dengan timeout)
    if (SupabaseConfig.isInitialized) {
      try {
        await _supabaseService
            .deleteData(
              'vehicle_maintenance',
              matchColumn: 'vehicle_id',
              matchValue: vehicle.id,
            )
            .timeout(const Duration(seconds: 4));

        if (items.isNotEmpty) {
          await _supabaseService
              .insertData('vehicle_maintenance', items.map((it) => it.toJson()).toList())
              .timeout(const Duration(seconds: 4));
        }
      } catch (e) {
        debugPrint('Initialize vehicle_maintenance Supabase sync notice: $e');
      }
    }

    return items;
  }

  /// Meregenerasi item maintenance berdasarkan kategori kendaraan yang baru dipilih
  Future<List<VehicleMaintenanceModel>> regenerateVehicleMaintenance(VehicleModel vehicle) async {
    final storageKey = 'vehicle_maintenance_${vehicle.id}';
    final newItems = VehicleIntelligenceService.generateMaintenanceItems(
      vehicle: vehicle,
      initialCondition: vehicle.initialConditionOption,
    );

    // Update ke Hive
    await _settingsBox.put(
      storageKey,
      newItems.map((it) => it.toLocalJson()).toList(),
    );

    // Update ke Supabase
    if (SupabaseConfig.isInitialized) {
      try {
        await _supabaseService.deleteData('vehicle_maintenance', matchColumn: 'vehicle_id', matchValue: vehicle.id);
        for (final it in newItems) {
          await _supabaseService.insertData('vehicle_maintenance', it.toJson());
        }
      } catch (e) {
        debugPrint('Regenerate vehicle_maintenance remote sync warning: $e');
      }
    }

    return newItems;
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
  Future<ServiceRecordModel> addServiceRecord(
    ServiceRecordModel record, {
    int? customIntervalKm,
  }) async {
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
      (it) {
        if (it.id == record.maintenanceId ||
            it.maintenanceId == record.maintenanceId ||
            (it.itemName != null && it.itemName == record.maintenanceName)) {
          return true;
        }
        final recId = (record.maintenanceId ?? '').toLowerCase().replaceAll('_', '-');
        final itCat = (it.itemCategory ?? '').toLowerCase().replaceAll('_', '-');
        final itMaintId = it.maintenanceId.toLowerCase().replaceAll('_', '-');
        if (itCat.isNotEmpty && (recId.contains(itCat) || itCat.contains(recId))) {
          return true;
        }
        if (itMaintId.isNotEmpty && (recId.contains(itMaintId) || itMaintId.contains(recId))) {
          return true;
        }

        final recNorm = (record.maintenanceId ?? record.maintenanceName ?? '')
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '');
        final itCatNorm = (it.itemCategory ?? '')
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '');
        final itNameNorm = (it.itemName ?? '')
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '');
        final itMaintNorm = it.maintenanceId
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '');

        if (recNorm.isNotEmpty) {
          if (itCatNorm.isNotEmpty &&
              (recNorm == itCatNorm || recNorm.contains(itCatNorm) || itCatNorm.contains(recNorm))) {
            return true;
          }
          if (itNameNorm.isNotEmpty &&
              (recNorm == itNameNorm || recNorm.contains(itNameNorm) || itNameNorm.contains(recNorm))) {
            return true;
          }
          if (itMaintNorm.isNotEmpty &&
              (recNorm == itMaintNorm || recNorm.contains(itMaintNorm) || itMaintNorm.contains(recNorm))) {
            return true;
          }
        }
        return false;
      },
    );

    if (targetItemIndex >= 0) {
      final target = vmList[targetItemIndex];
      final newInterval = (customIntervalKm != null && customIntervalKm > 0)
          ? customIntervalKm
          : target.intervalKm;

      final updatedItem = target.copyWith(
        lastServiceOdometer: record.odometer,
        lastServiceDate: record.serviceDate,
        intervalKm: newInterval,
        healthPercentage: 100,
        status: 'GOOD',
        updatedAt: DateTime.now(),
        hasServiceHistory: true,
      );
      await updateVehicleMaintenance(updatedItem);
    }

    // Perbarui juga legacy _box jika ada
    try {
      final legacyItems = _box.values.where((item) => item.vehicleId == record.vehicleId).toList();
      for (final legacyItem in legacyItems) {
        final legacyNorm = legacyItem.componentType.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        final recNorm = (record.maintenanceId ?? record.maintenanceName ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (legacyNorm.isNotEmpty &&
            (legacyNorm == recNorm || legacyNorm.contains(recNorm) || recNorm.contains(legacyNorm))) {
          final updated = legacyItem.copyWith(
            lastServiceKm: record.odometer.toDouble(),
            lastServiceDate: record.serviceDate,
            intervalKm: (customIntervalKm != null && customIntervalKm > 0)
                ? customIntervalKm.toDouble()
                : legacyItem.intervalKm,
          );
          await _box.put(updated.id, updated);
        }
      }
    } catch (e) {
      debugPrint('Legacy maintenance box update skipped: $e');
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
    int? customIntervalKm,
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

    await addServiceRecord(newRecord, customIntervalKm: customIntervalKm);

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
