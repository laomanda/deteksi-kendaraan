/// Component definition metadata according to PRD Section 7.3
class ComponentMetadata {
  final String key;
  final String displayName;
  final double intervalKm;
  final int intervalDays;
  final String description;
  final bool isKmApplicable;

  const ComponentMetadata({
    required this.key,
    required this.displayName,
    required this.intervalKm,
    required this.intervalDays,
    required this.description,
    this.isKmApplicable = true,
  });
}

class ComponentCatalog {
  ComponentCatalog._();

  // Motorcycle Components (PRD Section 7.3.1)
  static const List<ComponentMetadata> motorcycleComponents = [
    ComponentMetadata(
      key: 'engine_oil',
      displayName: 'Oli Mesin',
      intervalKm: 2500.0,
      intervalDays: 90, // 3 Bulan
      description: 'Pelumasan piston & transfer panas.',
    ),
    ComponentMetadata(
      key: 'gear_oil',
      displayName: 'Oli Gardan',
      intervalKm: 8000.0,
      intervalDays: 180, // 6 Bulan
      description: 'Khusus skuter matik; pelumasan rasio gigi.',
    ),
    ComponentMetadata(
      key: 'brake_pad',
      displayName: 'Kampas Rem',
      intervalKm: 10000.0,
      intervalDays: 365, // 12 Bulan
      description: 'Ketebalan material gesek; keselamatan kritis.',
    ),
    ComponentMetadata(
      key: 'tires',
      displayName: 'Ban Depan/Belakang',
      intervalKm: 18000.0,
      intervalDays: 730, // 24 Bulan
      description: 'Keausan TWI (Tread Wear Indicator).',
    ),
    ComponentMetadata(
      key: 'battery',
      displayName: 'Aki Motor',
      intervalKm: 0.0,
      intervalDays: 548, // 18 Bulan
      description: 'Tegangan sel & kapasitas starter listrik.',
      isKmApplicable: false,
    ),
    ComponentMetadata(
      key: 'spark_plug',
      displayName: 'Busi',
      intervalKm: 8000.0,
      intervalDays: 365, // 12 Bulan
      description: 'Erosi elektroda & celah percikan api.',
    ),
    ComponentMetadata(
      key: 'cvt_belt',
      displayName: 'CVT Belt & Roller',
      intervalKm: 20000.0,
      intervalDays: 730, // 24 Bulan
      description: 'Keausan lebar sabuk & deformasi roller.',
    ),
  ];

  // Car Components (PRD Section 7.3.2)
  static const List<ComponentMetadata> carComponents = [
    ComponentMetadata(
      key: 'engine_oil',
      displayName: 'Oli Mesin',
      intervalKm: 10000.0,
      intervalDays: 180, // 6 Bulan
      description: 'Sintetik penuh; kapasitas penyerapan karbon.',
    ),
    ComponentMetadata(
      key: 'tires',
      displayName: 'Ban Mobil',
      intervalKm: 40000.0,
      intervalDays: 1095, // 36 Bulan
      description: 'Keausan tapak & pengerasan kompon karet.',
    ),
    ComponentMetadata(
      key: 'brake_pad',
      displayName: 'Rem Depan/Belakang',
      intervalKm: 30000.0,
      intervalDays: 730, // 24 Bulan
      description: 'Ketebalan kampas cakram & tromol.',
    ),
    ComponentMetadata(
      key: 'battery',
      displayName: 'Aki Mobil',
      intervalKm: 0.0,
      intervalDays: 730, // 24 Bulan
      description: 'Umur operasional aki basah/kering.',
      isKmApplicable: false,
    ),
    ComponentMetadata(
      key: 'air_filter',
      displayName: 'Filter Udara',
      intervalKm: 20000.0,
      intervalDays: 365, // 12 Bulan
      description: 'Hambatan aliran udara ke ruang bakar.',
    ),
    ComponentMetadata(
      key: 'engine_coolant',
      displayName: 'Radiator Coolant',
      intervalKm: 40000.0,
      intervalDays: 730, // 24 Bulan
      description: 'Kapasitas titik didih & anti-korosi.',
    ),
  ];

  static List<ComponentMetadata> getCatalogForVehicleType(String vehicleType) {
    if (vehicleType.toLowerCase() == 'car') {
      return carComponents;
    }
    return motorcycleComponents;
  }

  static ComponentMetadata? findMetadata(String vehicleType, String componentKey) {
    final list = getCatalogForVehicleType(vehicleType);
    for (final meta in list) {
      if (meta.key == componentKey) return meta;
    }
    // Fallback search across both
    for (final meta in [...motorcycleComponents, ...carComponents]) {
      if (meta.key == componentKey) return meta;
    }
    return null;
  }
}
