import 'package:hive/hive.dart';

/// Vehicle entity and model according to Supabase 'vehicles' & 'vehicle_specs' tables
class VehicleModel extends HiveObject {
  final String id;
  final String? profileId;
  final String brand;
  final String model;
  final String? variant;
  final String vehicleType; // "motorcycle" | "car"
  final int year;
  final String? licensePlate;
  final int? engineCc;
  final int initialOdometer;
  int currentOdometer;
  String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Embedded specs (matching 'vehicle_specs' table)
  final String? fuelType;
  final String? transmission;
  final String? color;
  final String? engineNumber;
  final String? chassisNumber;

  VehicleModel({
    required this.id,
    this.profileId,
    required this.brand,
    required this.model,
    this.variant,
    required this.vehicleType,
    required this.year,
    this.licensePlate,
    this.engineCc,
    this.initialOdometer = 0,
    int? currentOdometer,
    double? currentKilometer,
    String? photoUrl,
    String? photoPath,
    this.createdAt,
    this.updatedAt,
    this.fuelType,
    this.transmission,
    this.color,
    this.engineNumber,
    this.chassisNumber,
  })  : currentOdometer = currentOdometer ?? (currentKilometer?.round() ?? 0),
        photoUrl = photoUrl ?? photoPath;

  /// Display name combining brand and model, plus variant if present
  String get displayName =>
      '$brand $model${variant != null && variant!.isNotEmpty ? ' $variant' : ''}';

  bool get isMotorcycle => vehicleType.toLowerCase() == 'motorcycle';
  bool get isCar => vehicleType.toLowerCase() == 'car';

  /// Backward-compatibility getter & setter for legacy code using currentKilometer
  double get currentKilometer => currentOdometer.toDouble();
  set currentKilometer(double val) => currentOdometer = val.round();

  /// Backward-compatibility getter for legacy code using photoPath
  String? get photoPath => photoUrl;

  VehicleModel copyWith({
    String? id,
    String? profileId,
    String? brand,
    String? model,
    String? variant,
    String? vehicleType,
    int? year,
    String? licensePlate,
    int? engineCc,
    int? initialOdometer,
    int? currentOdometer,
    double? currentKilometer,
    String? photoUrl,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fuelType,
    String? transmission,
    String? color,
    String? engineNumber,
    String? chassisNumber,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      variant: variant ?? this.variant,
      vehicleType: vehicleType ?? this.vehicleType,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      engineCc: engineCc ?? this.engineCc,
      initialOdometer: initialOdometer ?? this.initialOdometer,
      currentOdometer: currentOdometer ?? (currentKilometer?.round() ?? this.currentOdometer),
      photoUrl: photoUrl ?? photoPath ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fuelType: fuelType ?? this.fuelType,
      transmission: transmission ?? this.transmission,
      color: color ?? this.color,
      engineNumber: engineNumber ?? this.engineNumber,
      chassisNumber: chassisNumber ?? this.chassisNumber,
    );
  }

  /// Maps to Supabase 'vehicles' table schema
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (profileId != null) 'profile_id': profileId,
      'brand': brand,
      'model': model,
      if (variant != null) 'variant': variant,
      'vehicle_type': vehicleType,
      'year': year,
      if (licensePlate != null) 'license_plate': licensePlate,
      if (engineCc != null) 'engine_cc': engineCc,
      'initial_odometer': initialOdometer,
      'current_odometer': currentOdometer,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Maps to Supabase 'vehicle_specs' table schema
  Map<String, dynamic> toSpecsJson() {
    return {
      'vehicle_id': id,
      if (fuelType != null) 'fuel_type': fuelType,
      if (transmission != null) 'transmission': transmission,
      if (color != null) 'color': color,
      if (engineNumber != null) 'engine_number': engineNumber,
      if (chassisNumber != null) 'chassis_number': chassisNumber,
    };
  }

  /// Factory deserializer from Supabase or generic JSON
  factory VehicleModel.fromJson(Map<String, dynamic> json, [Map<String, dynamic>? specsJson]) {
    final odometerVal = json['current_odometer'] ?? json['currentKilometer'] ?? json['initial_odometer'] ?? 0;
    final int odo = odometerVal is num ? odometerVal.toInt() : int.tryParse(odometerVal.toString()) ?? 0;

    final initialOdoVal = json['initial_odometer'] ?? 0;
    final int initialOdo = initialOdoVal is num ? initialOdoVal.toInt() : int.tryParse(initialOdoVal.toString()) ?? 0;

    final ccVal = json['engine_cc'];
    final int? cc = ccVal is num ? ccVal.toInt() : (ccVal != null ? int.tryParse(ccVal.toString()) : null);

    final yearVal = json['year'] ?? 2024;
    final int y = yearVal is num ? yearVal.toInt() : int.tryParse(yearVal.toString()) ?? 2024;

    return VehicleModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String?,
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      variant: json['variant'] as String?,
      vehicleType: json['vehicle_type'] as String? ?? json['vehicleType'] as String? ?? 'motorcycle',
      year: y,
      licensePlate: json['license_plate'] as String? ?? json['licensePlate'] as String?,
      engineCc: cc,
      initialOdometer: initialOdo,
      currentOdometer: odo,
      photoUrl: json['photo_url'] as String? ?? json['photoPath'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : (json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      fuelType: specsJson?['fuel_type'] as String? ?? json['fuel_type'] as String?,
      transmission: specsJson?['transmission'] as String? ?? json['transmission'] as String?,
      color: specsJson?['color'] as String? ?? json['color'] as String?,
      engineNumber: specsJson?['engine_number'] as String? ?? json['engine_number'] as String?,
      chassisNumber: specsJson?['chassis_number'] as String? ?? json['chassis_number'] as String?,
    );
  }
}

/// Local representation model specifically for Hive caching
class VehicleLocalModel {
  final String id;
  final String brand;
  final String model;
  final String? variant;
  final String vehicleType;
  final int year;
  final String? licensePlate;
  final int? engineCc;
  final int currentOdometer;
  final String? photoUrl;
  final DateTime createdAt;

  VehicleLocalModel({
    required this.id,
    required this.brand,
    required this.model,
    this.variant,
    required this.vehicleType,
    required this.year,
    this.licensePlate,
    this.engineCc,
    required this.currentOdometer,
    this.photoUrl,
    required this.createdAt,
  });

  VehicleModel toEntity() {
    return VehicleModel(
      id: id,
      brand: brand,
      model: model,
      variant: variant,
      vehicleType: vehicleType,
      year: year,
      licensePlate: licensePlate,
      engineCc: engineCc,
      currentOdometer: currentOdometer,
      photoUrl: photoUrl,
      createdAt: createdAt,
    );
  }

  factory VehicleLocalModel.fromEntity(VehicleModel model) {
    return VehicleLocalModel(
      id: model.id,
      brand: model.brand,
      model: model.model,
      variant: model.variant,
      vehicleType: model.vehicleType,
      year: model.year,
      licensePlate: model.licensePlate,
      engineCc: model.engineCc,
      currentOdometer: model.currentOdometer,
      photoUrl: model.photoUrl,
      createdAt: model.createdAt ?? DateTime.now(),
    );
  }
}

/// Hive TypeAdapter for VehicleModel (compatible with HiveRegistrar typeId 0)
class VehicleModelAdapter extends TypeAdapter<VehicleModel> {
  @override
  final int typeId = 0;

  @override
  VehicleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final odometerRaw = fields[5];
    final int odo = odometerRaw is num ? odometerRaw.toInt() : (double.tryParse(odometerRaw?.toString() ?? '0')?.round() ?? 0);

    return VehicleModel(
      id: fields[0] as String,
      vehicleType: fields[1] as String? ?? 'motorcycle',
      brand: fields[2] as String? ?? '',
      model: fields[3] as String? ?? '',
      year: fields[4] as int? ?? 2024,
      currentOdometer: odo,
      photoUrl: fields[6] as String?,
      createdAt: fields[7] as DateTime? ?? DateTime.now(),
      variant: fields.containsKey(8) ? fields[8] as String? : null,
      licensePlate: fields.containsKey(9) ? fields[9] as String? : null,
      engineCc: fields.containsKey(10) ? fields[10] as int? : null,
      initialOdometer: fields.containsKey(11) ? (fields[11] as int? ?? 0) : 0,
      fuelType: fields.containsKey(12) ? fields[12] as String? : null,
      transmission: fields.containsKey(13) ? fields[13] as String? : null,
      color: fields.containsKey(14) ? fields[14] as String? : null,
    );
  }

  @override
  void write(BinaryWriter writer, VehicleModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.vehicleType)
      ..writeByte(2)..write(obj.brand)
      ..writeByte(3)..write(obj.model)
      ..writeByte(4)..write(obj.year)
      ..writeByte(5)..write(obj.currentOdometer)
      ..writeByte(6)..write(obj.photoUrl)
      ..writeByte(7)..write(obj.createdAt ?? DateTime.now())
      ..writeByte(8)..write(obj.variant)
      ..writeByte(9)..write(obj.licensePlate)
      ..writeByte(10)..write(obj.engineCc)
      ..writeByte(11)..write(obj.initialOdometer)
      ..writeByte(12)..write(obj.fuelType)
      ..writeByte(13)..write(obj.transmission)
      ..writeByte(14)..write(obj.color);
  }
}
