import 'package:uuid/uuid.dart';
import '../../maintenance/data/models/maintenance_template_model.dart';
import '../../maintenance/data/models/vehicle_maintenance_model.dart';
import '../../maintenance/domain/maintenance_calculator.dart';
import '../data/models/vehicle_category_model.dart';
import '../data/models/vehicle_model.dart';

/// Domain Service: Vehicle Intelligence Layer
/// Bertanggung jawab atas klasifikasi cerdas kendaraan, pemetaan template servis,
/// dan pembentukan instance perawatan spesifik tanpa komponen yang tidak relevan.
class VehicleIntelligenceService {
  const VehicleIntelligenceService();

  /// Menentukan ID Kategori kendaraan.
  /// Mendukung pemanggilan dengan VehicleModel ataupun parameter individual.
  static String resolveCategoryId(VehicleModel vehicle) {
    if (vehicle.vehicleCategoryId != null && vehicle.vehicleCategoryId!.isNotEmpty) {
      return vehicle.vehicleCategoryId!;
    }
    return inferCategory(
      vehicleType: vehicle.vehicleType,
      brand: vehicle.brand,
      model: vehicle.model,
      transmission: vehicle.transmission,
      fuelType: vehicle.fuelType,
    );
  }

  /// Menentukan ID Kategori dari parameter individual
  static String resolveCategoryFromParams({
    required String vehicleType,
    String? brand,
    String? modelName,
    String? transmission,
    String? fuelType,
  }) {
    return inferCategory(
      vehicleType: vehicleType,
      brand: brand,
      model: modelName,
      transmission: transmission,
      fuelType: fuelType,
    );
  }

  /// Inferensi heuristik cerdas berdasarkan merek, model, transmisi, dan bahan bakar
  static String inferCategory({
    required String vehicleType,
    String? brand,
    String? model,
    String? transmission,
    String? fuelType,
  }) {
    final type = vehicleType.toLowerCase();
    final m = (model ?? '').toLowerCase();
    final t = (transmission ?? '').toLowerCase();
    final f = (fuelType ?? '').toLowerCase();

    if (type == 'car') {
      if (f.contains('hybrid') || m.contains('hybrid') || m.contains('hev')) {
        return 'car_hybrid';
      }
      if (f.contains('diesel') ||
          f.contains('solar') ||
          m.contains('diesel') ||
          m.contains('pajero') ||
          m.contains('fortuner') ||
          m.contains('innova d') ||
          m.contains('2kd') ||
          m.contains('2gd')) {
        return 'car_diesel';
      }
      if (t.contains('manual')) {
        return 'car_manual';
      }
      return 'car_automatic'; // Default mobil adalah matic/automatic
    }

    // Sepeda Motor
    if (m.contains('cbr') ||
        m.contains('ninja') ||
        m.contains('r15') ||
        m.contains('r25') ||
        m.contains('gsx') ||
        m.contains('cb150') ||
        m.contains('vixion') ||
        m.contains('mt15') ||
        m.contains('mt25') ||
        m.contains('klx') ||
        m.contains('crf') ||
        m.contains('wr155')) {
      return 'sport_motorcycle';
    }

    if (t.contains('manual') ||
        m.contains('supra') ||
        m.contains('revo') ||
        m.contains('jupiter') ||
        m.contains('vega') ||
        m.contains('blade') ||
        m.contains('shogun') ||
        m.contains('smash')) {
      return 'motorcycle_manual';
    }

    // Default umum motor komuter di Indonesia adalah matic CVT (Vario, Beat, NMAX, Scoopy, dll)
    return 'scooter_cvt';
  }

  /// Mengambil daftar template maintenance terkurasi untuk kategori atau kendaraan
  static List<MaintenanceTemplateModel> getTemplatesForVehicle(dynamic vehicleOrCategoryId) {
    final String categoryId;
    if (vehicleOrCategoryId is VehicleModel) {
      categoryId = resolveCategoryId(vehicleOrCategoryId);
    } else if (vehicleOrCategoryId is String) {
      categoryId = vehicleOrCategoryId;
    } else {
      categoryId = 'scooter_cvt';
    }
    return MaintenanceTemplateModel.getTemplatesForCategory(categoryId);
  }

  /// Membuat instance `VehicleMaintenanceModel` spesifik dan terkurasi untuk kendaraan.
  /// Mendukung 3 kondisi awal setup:
  /// 1. Prediksi Otomatis: kendaraan sehat, baseline KM = current_odometer, health 100%.
  /// 2. Input Riwayat Servis: user memasukkan servis terakhir, kalkulasi normal.
  /// 3. Semua Komponen Kondisi Baik: semua item dibuat health 100%, baseline servis = current_odometer.
  static List<VehicleMaintenanceModel> generateMaintenanceItems({
    required VehicleModel vehicle,
    DateTime? now,
    String? overrideCategoryId,
    String? categoryId,
    VehicleInitialCondition? initialCondition,
    int? lastServiceOdometer,
    DateTime? lastServiceDate,
  }) {
    final targetCategoryId = overrideCategoryId ?? categoryId ?? resolveCategoryId(vehicle);
    final templates = MaintenanceTemplateModel.getTemplatesForCategory(targetCategoryId);
    const uuid = Uuid();
    final timestamp = now ?? DateTime.now();

    final condition = initialCondition ?? vehicle.initialConditionOption;

    return templates.map((tmpl) {
      final int odo;
      final bool hasHistory;
      final int health;
      final String status;
      final DateTime? sDate;

      switch (condition) {
        case VehicleInitialCondition.autoPrediction:
          // 1. Prediksi Otomatis:
          // - kendaraan dianggap sehat
          // - gunakan current_odometer sebagai baseline
          // - health 100%
          // - mulai tracking dari KM sekarang
          odo = 0;
          hasHistory = false;
          health = 100;
          status = 'GOOD';
          sDate = timestamp;
          break;

        case VehicleInitialCondition.allGood:
          // 3. Semua Komponen Kondisi Baik:
          // - semua maintenance item dibuat health 100%
          // - baseline servis = current_odometer
          odo = vehicle.currentOdometer;
          hasHistory = true;
          health = 100;
          status = 'GOOD';
          sDate = timestamp;
          break;

        case VehicleInitialCondition.serviceHistory:
          // 2. Input Riwayat Servis:
          // - user memasukkan servis terakhir
          // - gunakan last_service_odometer
          // - kalkulasi normal
          final inputOdo = lastServiceOdometer ?? 0;
          final calc = MaintenanceCalculator.calculate(
            currentOdometer: vehicle.currentOdometer,
            intervalKm: tmpl.intervalKm,
            lastServiceOdometer: inputOdo,
            hasMaintenanceHistory: true,
          );
          odo = inputOdo;
          hasHistory = true;
          health = calc.healthPercentage;
          status = calc.status;
          sDate = lastServiceDate ?? timestamp;
          break;
      }

      return VehicleMaintenanceModel(
        id: uuid.v4(),
        vehicleId: vehicle.id,
        maintenanceId: tmpl.id,
        lastServiceDate: sDate,
        lastServiceOdometer: odo,
        healthPercentage: health,
        status: status,
        itemName: tmpl.componentName,
        itemCategory: tmpl.componentKey,
        intervalKm: tmpl.intervalKm,
        intervalMonth: tmpl.intervalMonth,
        hasServiceHistory: hasHistory,
      );
    }).toList();
  }

  /// Mengecek apakah kendaraan merupakan kendaraan lama yang belum memiliki kategori eksplisit
  static bool isMissingCategory(VehicleModel vehicle) {
    return vehicle.vehicleCategoryId == null || vehicle.vehicleCategoryId!.trim().isEmpty;
  }

  /// Alias untuk mengecek kendaraan legacy
  static bool isLegacyVehicle(VehicleModel vehicle) => isMissingCategory(vehicle);

  /// Mengambil representasi nama kategori ramah pengguna
  static String getCategoryDisplayName(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return 'Belum Ditentukan';
    final cat = VehicleCategoryModel.findById(categoryId);
    return cat?.name ?? categoryId;
  }

  /// Verifikasi kepatuhan domain: memeriksa dan mengembalikan daftar pelanggaran komponen terlarang
  static List<String> validateNoIncompatibleComponents({
    required String categoryId,
    required List<String> itemKeys,
  }) {
    final violations = <String>[];
    switch (categoryId) {
      case 'scooter_cvt':
        // Motor matic dilarang memiliki rantai, gir manual, dan kopling manual
        for (final k in itemKeys) {
          final lk = k.toLowerCase();
          if (lk.contains('chain') || lk.contains('clutch_plate') || lk.contains('sprocket')) {
            violations.add(k);
          }
        }
        break;
      case 'motorcycle_manual':
      case 'sport_motorcycle':
        // Motor manual dilarang memiliki CVT belt, roller, dan oli gardan
        for (final k in itemKeys) {
          final lk = k.toLowerCase();
          if (lk.contains('vanbelt') ||
              lk.contains('cvt') ||
              lk.contains('final_drive_oil') ||
              lk.contains('gear_oil')) {
            violations.add(k);
          }
        }
        break;
      case 'car_automatic':
        // Mobil matic dilarang memiliki kampas kopling manual & transmisi manual
        for (final k in itemKeys) {
          final lk = k.toLowerCase();
          if (lk.contains('clutch_plate') ||
              lk.contains('manual_transmission_fluid') ||
              lk.contains('chain')) {
            violations.add(k);
          }
        }
        break;
      case 'car_manual':
        // Mobil manual dilarang memiliki fluida transmisi otomatis (ATF)
        for (final k in itemKeys) {
          final lk = k.toLowerCase();
          if (lk.contains('automatic_transmission_fluid')) {
            violations.add(k);
          }
        }
        break;
      default:
        break;
    }
    return violations;
  }
}
