import 'package:hive/hive.dart';

/// MaintenanceItem entity model according to PRD Section 13.2
class MaintenanceItemModel extends HiveObject {
  final String id;
  final String vehicleId;
  final String componentType;
  final double intervalKm;
  final int intervalDays;
  double lastServiceKm;
  DateTime lastServiceDate;

  MaintenanceItemModel({
    required this.id,
    required this.vehicleId,
    required this.componentType,
    required this.intervalKm,
    required this.intervalDays,
    required this.lastServiceKm,
    required this.lastServiceDate,
  });

  MaintenanceItemModel copyWith({
    String? id,
    String? vehicleId,
    String? componentType,
    double? intervalKm,
    int? intervalDays,
    double? lastServiceKm,
    DateTime? lastServiceDate,
  }) {
    return MaintenanceItemModel(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      componentType: componentType ?? this.componentType,
      intervalKm: intervalKm ?? this.intervalKm,
      intervalDays: intervalDays ?? this.intervalDays,
      lastServiceKm: lastServiceKm ?? this.lastServiceKm,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'componentType': componentType,
        'intervalKm': intervalKm,
        'intervalDays': intervalDays,
        'lastServiceKm': lastServiceKm,
        'lastServiceDate': lastServiceDate.toIso8601String(),
      };

  factory MaintenanceItemModel.fromJson(Map<String, dynamic> json) =>
      MaintenanceItemModel(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String,
        componentType: json['componentType'] as String,
        intervalKm: (json['intervalKm'] as num).toDouble(),
        intervalDays: json['intervalDays'] as int,
        lastServiceKm: (json['lastServiceKm'] as num).toDouble(),
        lastServiceDate: DateTime.parse(json['lastServiceDate'] as String),
      );
}

class MaintenanceItemModelAdapter extends TypeAdapter<MaintenanceItemModel> {
  @override
  final int typeId = 1;

  @override
  MaintenanceItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaintenanceItemModel(
      id: fields[0] as String,
      vehicleId: fields[1] as String,
      componentType: fields[2] as String,
      intervalKm: (fields[3] as num).toDouble(),
      intervalDays: fields[4] as int,
      lastServiceKm: (fields[5] as num).toDouble(),
      lastServiceDate: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MaintenanceItemModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.componentType)
      ..writeByte(3)
      ..write(obj.intervalKm)
      ..writeByte(4)
      ..write(obj.intervalDays)
      ..writeByte(5)
      ..write(obj.lastServiceKm)
      ..writeByte(6)
      ..write(obj.lastServiceDate);
  }
}
