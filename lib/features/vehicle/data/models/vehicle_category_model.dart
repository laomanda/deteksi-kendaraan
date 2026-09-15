/// Model representasi data dari tabel Supabase 'vehicle_categories'
class VehicleCategoryModel {
  final String id;
  final String name;
  final String vehicleType; // 'motorcycle' | 'car'
  final String description;

  const VehicleCategoryModel({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.description,
  });

  String get displayName => name;
  bool get isMotorcycle => vehicleType.toLowerCase() == 'motorcycle';
  bool get isCar => vehicleType.toLowerCase() == 'car';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'vehicle_type': vehicleType,
      'description': description,
    };
  }

  factory VehicleCategoryModel.fromJson(Map<String, dynamic> json) {
    return VehicleCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      vehicleType: json['vehicle_type'] as String? ?? json['vehicleType'] as String? ?? 'motorcycle',
      description: json['description'] as String? ?? '',
    );
  }

  /// Master Dataset Kategori Standar (Offline-first default)
  static const List<VehicleCategoryModel> defaultCategories = [
    // Sepeda Motor
    VehicleCategoryModel(
      id: 'scooter_cvt',
      name: 'Motor Matic (CVT)',
      vehicleType: 'motorcycle',
      description: 'Sepeda motor transmisi otomatis dengan sabuk v-belt dan roller CVT',
    ),
    VehicleCategoryModel(
      id: 'motorcycle_manual',
      name: 'Motor Manual',
      vehicleType: 'motorcycle',
      description: 'Sepeda motor bebek atau komuter dengan rantai dan kopling manual/sentrifugal',
    ),
    VehicleCategoryModel(
      id: 'sport_motorcycle',
      name: 'Motor Sport',
      vehicleType: 'motorcycle',
      description: 'Sepeda motor sport dengan kopling manual, rantai O-ring, dan pendingin radiator',
    ),
    // Mobil
    VehicleCategoryModel(
      id: 'car_automatic',
      name: 'Mobil Otomatis (AT / CVT)',
      vehicleType: 'car',
      description: 'Mobil penumpang transmisi otomatis konvensional AT atau CVT',
    ),
    VehicleCategoryModel(
      id: 'car_manual',
      name: 'Mobil Manual',
      vehicleType: 'car',
      description: 'Mobil penumpang transmisi manual dengan kampas kopling manual',
    ),
    VehicleCategoryModel(
      id: 'car_diesel',
      name: 'Mobil Diesel',
      vehicleType: 'car',
      description: 'Mobil bermesin diesel yang membutuhkan filter bahan bakar (solar) khusus',
    ),
    VehicleCategoryModel(
      id: 'car_hybrid',
      name: 'Mobil Hybrid',
      vehicleType: 'car',
      description: 'Mobil bermesin kombinasi bensin dan motor listrik dengan inverter coolant',
    ),
  ];

  static List<VehicleCategoryModel> getCategoriesForType(String vehicleType) {
    final type = vehicleType.toLowerCase();
    return defaultCategories.where((c) => c.vehicleType.toLowerCase() == type).toList();
  }

  static VehicleCategoryModel? findById(String? id) {
    if (id == null || id.isEmpty) return null;
    return defaultCategories.where((c) => c.id == id).firstOrNull;
  }
}
