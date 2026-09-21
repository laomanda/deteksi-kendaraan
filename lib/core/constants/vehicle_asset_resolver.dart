import '../../features/vehicle/data/models/vehicle_model.dart';

/// Centralized Vehicle Asset Resolver for RideCare
/// Strictly conforms to Vehicle Category Architecture (vehicle_category_id):
/// - scooter_cvt -> assets/icons/vehicle/scooter_cvt.svg
/// - motorcycle_manual -> assets/icons/vehicle/motorcycle_manual.svg
/// - sport_motorcycle -> assets/icons/vehicle/sport_motorcycle.svg
/// - car_manual / car_automatic / car_hybrid -> assets/icons/vehicle/car.svg
///
/// Ensures deterministic fallback so no vehicle card ever displays an empty or broken icon.
class VehicleAssetResolver {
  VehicleAssetResolver._();

  static const String scooterCvt = 'assets/icons/vehicle/scooter_cvt.svg';
  static const String motorcycleManual = 'assets/icons/vehicle/motorcycle_manual.svg';
  static const String sportMotorcycle = 'assets/icons/vehicle/sport_motorcycle.svg';
  static const String car = 'assets/icons/vehicle/car.svg';

  /// Resolves the standardized SVG asset path for any [VehicleModel]
  static String getSilhouetteAsset(VehicleModel vehicle) {
    return resolve(
      categoryId: vehicle.vehicleCategoryId,
      vehicleType: vehicle.vehicleType,
      modelName: '${vehicle.brand} ${vehicle.model} ${vehicle.variant ?? ''}',
    );
  }

  /// Resolves the standardized SVG asset path based on category ID with robust fallbacks
  static String resolve({
    String? categoryId,
    String? vehicleType,
    String? modelName,
  }) {
    final cat = (categoryId ?? '').toLowerCase().trim();

    // 1. Strict category ID resolution
    if (cat == 'scooter_cvt') return scooterCvt;
    if (cat == 'motorcycle_manual') return motorcycleManual;
    if (cat == 'sport_motorcycle') return sportMotorcycle;
    if (cat == 'car_manual' ||
        cat == 'car_automatic' ||
        cat == 'car_hybrid' ||
        cat == 'car') {
      return car;
    }

    // 2. Semantic category matching
    if (cat.contains('scooter') || cat.contains('cvt')) return scooterCvt;
    if (cat.contains('sport')) return sportMotorcycle;
    if (cat.contains('manual') && (cat.contains('motor') || cat.contains('bike'))) {
      return motorcycleManual;
    }
    if (cat.contains('car') || cat.contains('mobil')) return car;

    // 3. Model name heuristics for legacy data without vehicleCategoryId
    final model = (modelName ?? '').toLowerCase();
    if (model.contains('cbr') ||
        model.contains('ninja') ||
        model.contains('r15') ||
        model.contains('r25') ||
        model.contains('gsx')) {
      return sportMotorcycle;
    }
    if (model.contains('cb150') ||
        model.contains('vixion') ||
        model.contains('verza') ||
        model.contains('megapro') ||
        model.contains('klx') ||
        model.contains('crf') ||
        model.contains('wr155')) {
      return motorcycleManual;
    }
    if (model.contains('avanza') ||
        model.contains('xenia') ||
        model.contains('brio') ||
        model.contains('innova') ||
        model.contains('yaris') ||
        model.contains('hrv') ||
        model.contains('crv') ||
        model.contains('pajero') ||
        model.contains('fortuner')) {
      return car;
    }

    // 4. Fallback based on high-level vehicleType
    final type = (vehicleType ?? '').toLowerCase();
    if (type.contains('car') || type.contains('mobil')) {
      return car;
    }

    // 5. Default fallback (scooter_cvt is the primary baseline for RideCare)
    return scooterCvt;
  }
}
