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
    ComponentMetadata(
      key: 'drive_chain',
      displayName: 'Rantai Roda & Gir',
      intervalKm: 15000.0,
      intervalDays: 365, // 12 Bulan
      description: 'Ketegangan dan pelumasan rantai roda serta gir depan/belakang.',
    ),
    ComponentMetadata(
      key: 'clutch_plate',
      displayName: 'Kampas Kopling',
      intervalKm: 25000.0,
      intervalDays: 730, // 24 Bulan
      description: 'Pemeriksaan ketebalan kampas kopling dan gejala selip.',
    ),
    ComponentMetadata(
      key: 'sprocket',
      displayName: 'Gir Depan & Belakang',
      intervalKm: 20000.0,
      intervalDays: 548, // 18 Bulan
      description: 'Pemeriksaan ketajaman mata gir depan dan belakang.',
    ),
    ComponentMetadata(
      key: 'air_filter',
      displayName: 'Filter Udara',
      intervalKm: 12000.0,
      intervalDays: 365, // 12 Bulan
      description: 'Pembersihan/penggantian saringan intake udara ruang bakar.',
    ),
    ComponentMetadata(
      key: 'radiator_coolant',
      displayName: 'Radiator Coolant',
      intervalKm: 12000.0,
      intervalDays: 365, // 12 Bulan
      description: 'Cairan pendingin radiator mesin.',
    ),
  ];

  // Car Components (PRD Section 7.3.2 & Vehicle Intelligence Layer)
  static const List<ComponentMetadata> carComponents = [
    ComponentMetadata(
      key: 'engine_oil',
      displayName: 'Oli Mesin',
      intervalKm: 10000.0,
      intervalDays: 180, // 6 Bulan
      description: 'Sintetik penuh; kapasitas penyerapan karbon.',
    ),
    ComponentMetadata(
      key: 'oil_filter',
      displayName: 'Filter Oli Mesin',
      intervalKm: 10000.0,
      intervalDays: 180, // 6 Bulan
      description: 'Penggantian saringan oli mesin bersama ganti oli.',
    ),
    ComponentMetadata(
      key: 'at_fluid',
      displayName: 'Oli Transmisi Matic (ATF/CVTF)',
      intervalKm: 40000.0,
      intervalDays: 730, // 24 Bulan
      description: 'Penggantian/pengurasan fluida transmisi otomatis atau CVT.',
    ),
    ComponentMetadata(
      key: 'mt_fluid',
      displayName: 'Oli Transmisi Manual (MTF)',
      intervalKm: 40000.0,
      intervalDays: 730, // 24 Bulan
      description: 'Penggantian pelumas gearbox transmisi manual.',
    ),
    ComponentMetadata(
      key: 'clutch_plate',
      displayName: 'Kampas Kopling Manual',
      intervalKm: 50000.0,
      intervalDays: 1095, // 36 Bulan
      description: 'Pemeriksaan pedal kopling, release bearing, dan kampas kopling.',
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
      key: 'cabin_filter',
      displayName: 'Filter Kabin AC',
      intervalKm: 15000.0,
      intervalDays: 365, // 12 Bulan
      description: 'Saringan udara AC ruang kabin mobil.',
    ),
    ComponentMetadata(
      key: 'fuel_filter',
      displayName: 'Filter Bahan Bakar (Solar)',
      intervalKm: 20000.0,
      intervalDays: 365, // 12 Bulan
      description: 'Penyaringan endapan air dan kotoran bahan bakar.',
    ),
    ComponentMetadata(
      key: 'engine_coolant',
      displayName: 'Radiator Coolant',
      intervalKm: 40000.0,
      intervalDays: 730, // 24 Bulan
      description: 'Kapasitas titik didih & anti-korosi.',
    ),
    ComponentMetadata(
      key: 'wiper_blades',
      displayName: 'Karet Wiper',
      intervalKm: 0.0,
      intervalDays: 365, // 12 Bulan
      description: 'Pemeriksaan kelenturan bilah karet wiper depan/belakang.',
      isKmApplicable: false,
    ),
  ];

  /// Mengambil daftar komponen berdasarkan kategori spesifik (Vehicle Intelligence Layer)
  /// Interval rekomendasi dapat berbeda berdasarkan merek kendaraan, kondisi penggunaan, dan kebiasaan berkendara.
  static List<ComponentMetadata> getCatalogForCategory(String? categoryId, {String vehicleType = 'motorcycle'}) {
    if (categoryId == null || categoryId.isEmpty) {
      return getCatalogForVehicleType(vehicleType);
    }

    switch (categoryId) {
      case 'scooter_cvt':
        // Motor Matic CVT: Wajib ada Oli Mesin, Oli Gardan, CVT Belt, Rem, Ban, Busi, Aki, Filter Udara
        // DILARANG: Rantai (drive_chain), Kampas Kopling Manual (clutch_plate), Gir (sprocket), Coolant (radiator_coolant)
        return motorcycleComponents.where((c) =>
            c.key != 'drive_chain' &&
            c.key != 'clutch_plate' &&
            c.key != 'sprocket' &&
            c.key != 'radiator_coolant').toList();

      case 'motorcycle_manual':
        // Motor Manual: Wajib ada Oli Mesin, Rantai, Gir (Sprocket), Kampas Kopling, Rem, Ban, Busi, Aki, Filter Udara
        // DILARANG: CVT Belt (cvt_belt), Oli Gardan (gear_oil), Radiator Coolant
        return motorcycleComponents.where((c) =>
            c.key != 'cvt_belt' &&
            c.key != 'gear_oil' &&
            c.key != 'radiator_coolant').toList();

      case 'sport_motorcycle':
        // Motor Sport: Wajib ada Oli Mesin, Rantai, Gir (Sprocket), Kampas Kopling, Coolant, Rem, Ban, Busi, Aki, Filter Udara
        // DILARANG: CVT Belt (cvt_belt), Oli Gardan (gear_oil)
        return motorcycleComponents.where((c) =>
            c.key != 'cvt_belt' && c.key != 'gear_oil').toList();

      case 'car_automatic':
        // Mobil Matic: DILARANG Kopling Manual (clutch_plate), MT Fluid (mt_fluid), Filter Solar (fuel_filter)
        return carComponents.where((c) =>
            c.key != 'clutch_plate' && c.key != 'mt_fluid' && c.key != 'fuel_filter').toList();

      case 'car_manual':
        // Mobil Manual: DILARANG Oli Transmisi Matic (at_fluid), Filter Solar (fuel_filter)
        return carComponents.where((c) =>
            c.key != 'at_fluid' && c.key != 'fuel_filter').toList();

      case 'car_diesel':
        // Mobil Diesel: Wajib ada Filter Solar (fuel_filter). DILARANG Kopling Manual (clutch_plate), AT Fluid (at_fluid)
        return carComponents.where((c) =>
            c.key != 'clutch_plate' && c.key != 'at_fluid').toList();

      case 'car_hybrid':
        return carComponents.where((c) =>
            c.key != 'clutch_plate' && c.key != 'mt_fluid' && c.key != 'fuel_filter').toList();

      default:
        return getCatalogForVehicleType(vehicleType);
    }
  }

  static List<ComponentMetadata> getCatalogForVehicleType(String vehicleType) {
    if (vehicleType.toLowerCase() == 'car') {
      return carComponents;
    }
    return motorcycleComponents;
  }

  static ComponentMetadata? findMetadata(String vehicleType, String componentKey) {
    final list = getCatalogForVehicleType(vehicleType);
    final keyLower = componentKey.toLowerCase().trim();
    final norm = keyLower.replaceAll(RegExp(r'[^a-z0-9]'), '');

    for (final meta in list) {
      final metaNorm = meta.key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final dispNorm = meta.displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (meta.key == componentKey ||
          meta.key.toLowerCase() == keyLower ||
          metaNorm == norm ||
          meta.displayName.toLowerCase() == keyLower ||
          dispNorm == norm) {
        return meta;
      }
    }
    // Fallback search across all
    for (final meta in [...motorcycleComponents, ...carComponents]) {
      final metaNorm = meta.key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final dispNorm = meta.displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (meta.key == componentKey ||
          meta.key.toLowerCase() == keyLower ||
          metaNorm == norm ||
          meta.displayName.toLowerCase() == keyLower ||
          dispNorm == norm) {
        return meta;
      }
    }
    return null;
  }
}
