import 'package:hive/hive.dart';

/// ServiceLog entity model according to PRD Section 13.2
class ServiceLogModel extends HiveObject {
  final String id;
  final String vehicleId;
  final String componentType;
  final double serviceKm;
  final DateTime serviceDate;
  final double cost;
  final String notes;

  ServiceLogModel({
    required this.id,
    required this.vehicleId,
    required this.componentType,
    required this.serviceKm,
    required this.serviceDate,
    required this.cost,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'componentType': componentType,
        'serviceKm': serviceKm,
        'serviceDate': serviceDate.toIso8601String(),
        'cost': cost,
        'notes': notes,
      };

  factory ServiceLogModel.fromJson(Map<String, dynamic> json) =>
      ServiceLogModel(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String,
        componentType: json['componentType'] as String,
        serviceKm: (json['serviceKm'] as num).toDouble(),
        serviceDate: DateTime.parse(json['serviceDate'] as String),
        cost: (json['cost'] as num).toDouble(),
        notes: json['notes'] as String? ?? '',
      );
}

class ServiceLogModelAdapter extends TypeAdapter<ServiceLogModel> {
  @override
  final int typeId = 2;

  @override
  ServiceLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceLogModel(
      id: fields[0] as String,
      vehicleId: fields[1] as String,
      componentType: fields[2] as String,
      serviceKm: (fields[3] as num).toDouble(),
      serviceDate: fields[4] as DateTime,
      cost: (fields[5] as num).toDouble(),
      notes: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ServiceLogModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.componentType)
      ..writeByte(3)
      ..write(obj.serviceKm)
      ..writeByte(4)
      ..write(obj.serviceDate)
      ..writeByte(5)
      ..write(obj.cost)
      ..writeByte(6)
      ..write(obj.notes);
  }
}
