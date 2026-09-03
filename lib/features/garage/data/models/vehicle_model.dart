import 'package:hive/hive.dart';

/// Vehicle entity model according to PRD Section 13.2
class VehicleModel extends HiveObject {
  final String id;
  final String vehicleType; // "motorcycle" | "car"
  final String brand;
  final String model;
  final int year;
  double currentKilometer;
  String? photoPath;
  final DateTime createdAt;

  VehicleModel({
    required this.id,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.year,
    required this.currentKilometer,
    this.photoPath,
    required this.createdAt,
  });

  String get displayName => '$brand $model';

  bool get isMotorcycle => vehicleType.toLowerCase() == 'motorcycle';
  bool get isCar => vehicleType.toLowerCase() == 'car';

  VehicleModel copyWith({
    String? id,
    String? vehicleType,
    String? brand,
    String? model,
    int? year,
    double? currentKilometer,
    String? photoPath,
    DateTime? createdAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      vehicleType: vehicleType ?? this.vehicleType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      currentKilometer: currentKilometer ?? this.currentKilometer,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleType': vehicleType,
        'brand': brand,
        'model': model,
        'year': year,
        'currentKilometer': currentKilometer,
        'photoPath': photoPath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
        id: json['id'] as String,
        vehicleType: json['vehicleType'] as String,
        brand: json['brand'] as String,
        model: json['model'] as String,
        year: json['year'] as int,
        currentKilometer: (json['currentKilometer'] as num).toDouble(),
        photoPath: json['photoPath'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class VehicleModelAdapter extends TypeAdapter<VehicleModel> {
  @override
  final int typeId = 0;

  @override
  VehicleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VehicleModel(
      id: fields[0] as String,
      vehicleType: fields[1] as String,
      brand: fields[2] as String,
      model: fields[3] as String,
      year: fields[4] as int,
      currentKilometer: (fields[5] as num).toDouble(),
      photoPath: fields[6] as String?,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, VehicleModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleType)
      ..writeByte(2)
      ..write(obj.brand)
      ..writeByte(3)
      ..write(obj.model)
      ..writeByte(4)
      ..write(obj.year)
      ..writeByte(5)
      ..write(obj.currentKilometer)
      ..writeByte(6)
      ..write(obj.photoPath)
      ..writeByte(7)
      ..write(obj.createdAt);
  }
}
