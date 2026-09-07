/// Model representasi data dari tabel Supabase 'maintenance_catalog'
class MaintenanceCatalogModel {
  final String id;
  final String name;
  final String category;
  final String vehicleType; // 'motorcycle' | 'car'
  final int defaultIntervalKm;
  final int defaultIntervalMonth;
  final String description;
  final DateTime? createdAt;

  const MaintenanceCatalogModel({
    required this.id,
    required this.name,
    required this.category,
    required this.vehicleType,
    required this.defaultIntervalKm,
    required this.defaultIntervalMonth,
    required this.description,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'vehicle_type': vehicleType,
      'default_interval_km': defaultIntervalKm,
      'default_interval_month': defaultIntervalMonth,
      'description': description,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  factory MaintenanceCatalogModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceCatalogModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      vehicleType: json['vehicle_type'] as String? ?? 'motorcycle',
      defaultIntervalKm: (json['default_interval_km'] as num?)?.toInt() ?? 3000,
      defaultIntervalMonth: (json['default_interval_month'] as num?)?.toInt() ?? 3,
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Master Dataset Katalog Standar untuk Motor
  static const List<MaintenanceCatalogModel> defaultMotorcycleCatalog = [
    MaintenanceCatalogModel(
      id: 'mc-01-engine-oil',
      name: 'Engine Oil',
      category: 'fluids',
      vehicleType: 'motorcycle',
      defaultIntervalKm: 3000,
      defaultIntervalMonth: 3,
      description: 'Penggantian oli mesin secara berkala untuk pelumasan maksimal',
    ),
    MaintenanceCatalogModel(
      id: 'mc-02-gear-oil',
      name: 'Final Drive / Gear Oil',
      category: 'fluids',
      vehicleType: 'motorcycle',
      defaultIntervalKm: 8000,
      defaultIntervalMonth: 6,
      description: 'Penggantian oli gardan/transmisi motor matic',
    ),
    MaintenanceCatalogModel(
      id: 'mc-03-brake-front',
      name: 'Brake Pad Front',
      category: 'brake',
      vehicleType: 'motorcycle',
      defaultIntervalKm: 10000,
      defaultIntervalMonth: 12,
      description: 'Pemeriksaan dan penggantian kampas rem depan',
    ),
    MaintenanceCatalogModel(
      id: 'mc-04-brake-rear',
      name: 'Brake Pad Rear',
      category: 'brake',
      vehicleType: 'motorcycle',
      defaultIntervalKm: 10000,
      defaultIntervalMonth: 12,
      description: 'Pemeriksaan dan penggantian kampas rem belakang',
    ),
    MaintenanceCatalogModel(
      id: 'mc-05-front-tire',
      name: 'Front Tire',
      category: 'chassis',
      vehicleType: 'motorcycle',
      defaultIntervalKm: 15000,
      defaultIntervalMonth: 18,
      description: 'Pemeriksaan keausan alur ban depan',
    ),
    MaintenanceCatalogModel(
      id: 'mc-06-rear-tire',
      name: 'Rear Tire',
      category: 'chassis',
      vehicleType: 'motorcycle',
      defaultIntervalKm: 12000,
      defaultIntervalMonth: 15,
      description: 'Pemeriksaan keausan alur ban belakang',
    ),
    MaintenanceCatalogModel(
      id: 'mc-07-battery',
      name: 'Battery',
      category: 'electrical',
      vehicleType: 'motorcycle',
      defaultIntervalKm: 20000,
      defaultIntervalMonth: 24,
      description: 'Pengecekan tegangan dan performa aki',
    ),
    MaintenanceCatalogModel(
      id: 'mc-08-spark-plug',
      name: 'Spark Plug',
      category: 'engine',
      vehicleType: 'motorcycle',
      defaultIntervalKm: 8000,
      defaultIntervalMonth: 8,
      description: 'Pembersihan dan penggantian busi',
    ),
    MaintenanceCatalogModel(
      id: 'mc-09-air-filter',
      name: 'Air Filter',
      category: 'engine',
      vehicleType: 'motorcycle',
      defaultIntervalKm: 10000,
      defaultIntervalMonth: 12,
      description: 'Penggantian filter udara untuk menjaga asupan pembakaran',
    ),
    MaintenanceCatalogModel(
      id: 'mc-10-cvt-service',
      name: 'CVT Service',
      category: 'transmission',
      vehicleType: 'motorcycle',
      defaultIntervalKm: 8000,
      defaultIntervalMonth: 6,
      description: 'Pembersihan dan pelumasan roller & pulley CVT',
    ),
    MaintenanceCatalogModel(
      id: 'mc-11-cvt-belt',
      name: 'CVT Belt',
      category: 'transmission',
      vehicleType: 'motorcycle',
      defaultIntervalKm: 24000,
      defaultIntervalMonth: 24,
      description: 'Pemeriksaan retak dan penggantian v-belt CVT',
    ),
    MaintenanceCatalogModel(
      id: 'mc-12-coolant',
      name: 'Coolant',
      category: 'engine',
      vehicleType: 'motorcycle',
      defaultIntervalKm: 12000,
      defaultIntervalMonth: 12,
      description: 'Pengecekan dan penggantian air radiator',
    ),
    MaintenanceCatalogModel(
      id: 'mc-13-brake-fluid',
      name: 'Brake Fluid',
      category: 'brake',
      vehicleType: 'motorcycle',
      defaultIntervalKm: 20000,
      defaultIntervalMonth: 24,
      description: 'Pengurasan dan penggantian minyak rem',
    ),
    MaintenanceCatalogModel(
      id: 'mc-14-drive-chain',
      name: 'Drive Chain',
      category: 'transmission',
      vehicleType: 'motorcycle',
      defaultIntervalKm: 15000,
      defaultIntervalMonth: 12,
      description: 'Penyetelan tegangan dan pelumasan rantai roda',
    ),
  ];

  /// Master Dataset Katalog Standar untuk Mobil
  static const List<MaintenanceCatalogModel> defaultCarCatalog = [
    MaintenanceCatalogModel(
      id: 'car-01-engine-oil',
      name: 'Engine Oil',
      category: 'fluids',
      vehicleType: 'car',
      defaultIntervalKm: 10000,
      defaultIntervalMonth: 6,
      description: 'Penggantian oli mesin mobil dan flushing',
    ),
    MaintenanceCatalogModel(
      id: 'car-02-oil-filter',
      name: 'Oil Filter',
      category: 'engine',
      vehicleType: 'car',
      defaultIntervalKm: 10000,
      defaultIntervalMonth: 6,
      description: 'Penggantian saringan oli mesin bersamaan dengan ganti oli',
    ),
    MaintenanceCatalogModel(
      id: 'car-03-air-filter',
      name: 'Air Filter',
      category: 'engine',
      vehicleType: 'car',
      defaultIntervalKm: 20000,
      defaultIntervalMonth: 12,
      description: 'Penggantian filter udara mesin mobil',
    ),
    MaintenanceCatalogModel(
      id: 'car-04-cabin-filter',
      name: 'Cabin Filter',
      category: 'ac',
      vehicleType: 'car',
      defaultIntervalKm: 15000,
      defaultIntervalMonth: 12,
      description: 'Penggantian filter AC kabin mobil untuk sirkulasi udara bersih',
    ),
    MaintenanceCatalogModel(
      id: 'car-05-brake-front',
      name: 'Brake Pad Front',
      category: 'brake',
      vehicleType: 'car',
      defaultIntervalKm: 30000,
      defaultIntervalMonth: 24,
      description: 'Pemeriksaan ketebalan kampas rem depan mobil',
    ),
    MaintenanceCatalogModel(
      id: 'car-06-brake-rear',
      name: 'Brake Pad Rear',
      category: 'brake',
      vehicleType: 'car',
      defaultIntervalKm: 40000,
      defaultIntervalMonth: 24,
      description: 'Pemeriksaan ketebalan kampas rem belakang mobil',
    ),
    MaintenanceCatalogModel(
      id: 'car-07-front-tire',
      name: 'Front Tire',
      category: 'chassis',
      vehicleType: 'car',
      defaultIntervalKm: 40000,
      defaultIntervalMonth: 36,
      description: 'Rotasi dan penggantian ban depan mobil',
    ),
    MaintenanceCatalogModel(
      id: 'car-08-rear-tire',
      name: 'Rear Tire',
      category: 'chassis',
      vehicleType: 'car',
      defaultIntervalKm: 40000,
      defaultIntervalMonth: 36,
      description: 'Rotasi dan penggantian ban belakang mobil',
    ),
    MaintenanceCatalogModel(
      id: 'car-09-battery',
      name: 'Battery',
      category: 'electrical',
      vehicleType: 'car',
      defaultIntervalKm: 40000,
      defaultIntervalMonth: 24,
      description: 'Pemeriksaan kapasitas aki mobil',
    ),
    MaintenanceCatalogModel(
      id: 'car-10-spark-plug',
      name: 'Spark Plug',
      category: 'engine',
      vehicleType: 'car',
      defaultIntervalKm: 40000,
      defaultIntervalMonth: 24,
      description: 'Penggantian set busi mesin mobil',
    ),
    MaintenanceCatalogModel(
      id: 'car-11-coolant',
      name: 'Coolant',
      category: 'engine',
      vehicleType: 'car',
      defaultIntervalKm: 40000,
      defaultIntervalMonth: 24,
      description: 'Kuras dan ganti cairan pendingin radiator mobil',
    ),
    MaintenanceCatalogModel(
      id: 'car-12-brake-fluid',
      name: 'Brake Fluid',
      category: 'brake',
      vehicleType: 'car',
      defaultIntervalKm: 40000,
      defaultIntervalMonth: 24,
      description: 'Kuras dan ganti minyak rem sistem hidrolik',
    ),
    MaintenanceCatalogModel(
      id: 'car-13-transmission-fluid',
      name: 'Transmission Fluid',
      category: 'transmission',
      vehicleType: 'car',
      defaultIntervalKm: 40000,
      defaultIntervalMonth: 24,
      description: 'Kuras oli transmisi matic/manual mobil',
    ),
    MaintenanceCatalogModel(
      id: 'car-14-wiper',
      name: 'Wiper',
      category: 'exterior',
      vehicleType: 'car',
      defaultIntervalKm: 20000,
      defaultIntervalMonth: 12,
      description: 'Penggantian bilah karet wiper kaca depan',
    ),
  ];

  static List<MaintenanceCatalogModel> getDefaultCatalogForType(String type) {
    if (type.toLowerCase() == 'car') {
      return defaultCarCatalog;
    }
    return defaultMotorcycleCatalog;
  }
}
