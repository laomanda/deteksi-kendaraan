import 'package:hive/hive.dart';

/// GpsPoint entity model according to PRD Section 13.2
class GpsPointModel extends HiveObject {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed; // in m/s
  final DateTime timestamp;

  GpsPointModel({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.timestamp,
  });

  /// Speed in km/h
  double get speedKmh => speed * 3.6;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'speed': speed,
        'timestamp': timestamp.toIso8601String(),
      };

  factory GpsPointModel.fromJson(Map<String, dynamic> json) => GpsPointModel(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        altitude: (json['altitude'] as num).toDouble(),
        speed: (json['speed'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class GpsPointModelAdapter extends TypeAdapter<GpsPointModel> {
  @override
  final int typeId = 4;

  @override
  GpsPointModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GpsPointModel(
      latitude: (fields[0] as num).toDouble(),
      longitude: (fields[1] as num).toDouble(),
      altitude: (fields[2] as num).toDouble(),
      speed: (fields[3] as num).toDouble(),
      timestamp: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GpsPointModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.altitude)
      ..writeByte(3)
      ..write(obj.speed)
      ..writeByte(4)
      ..write(obj.timestamp);
  }
}
