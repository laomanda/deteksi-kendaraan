import 'package:hive/hive.dart';
import 'gps_point_model.dart';

/// RideSession entity model according to PRD Section 13.2
class RideSessionModel extends HiveObject {
  final String id;
  final String vehicleId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalDistanceKm;
  final int durationSeconds;
  final double averageSpeedKmh;
  final List<GpsPointModel> points;

  RideSessionModel({
    required this.id,
    required this.vehicleId,
    required this.startTime,
    required this.endTime,
    required this.totalDistanceKm,
    required this.durationSeconds,
    required this.averageSpeedKmh,
    required this.points,
  });

  /// Computes max speed recorded during session in km/h
  double get maxSpeedKmh {
    if (points.isEmpty) return averageSpeedKmh;
    double maxSpeed = 0.0;
    for (final pt in points) {
      if (pt.speedKmh > maxSpeed) {
        maxSpeed = pt.speedKmh;
      }
    }
    return maxSpeed > 0 ? maxSpeed : averageSpeedKmh;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'totalDistanceKm': totalDistanceKm,
        'durationSeconds': durationSeconds,
        'averageSpeedKmh': averageSpeedKmh,
        'points': points.map((p) => p.toJson()).toList(),
      };

  factory RideSessionModel.fromJson(Map<String, dynamic> json) =>
      RideSessionModel(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
        durationSeconds: json['durationSeconds'] as int,
        averageSpeedKmh: (json['averageSpeedKmh'] as num).toDouble(),
        points: (json['points'] as List<dynamic>?)
                ?.map((p) => GpsPointModel.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class RideSessionModelAdapter extends TypeAdapter<RideSessionModel> {
  @override
  final int typeId = 3;

  @override
  RideSessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RideSessionModel(
      id: fields[0] as String,
      vehicleId: fields[1] as String,
      startTime: fields[2] as DateTime,
      endTime: fields[3] as DateTime,
      totalDistanceKm: (fields[4] as num).toDouble(),
      durationSeconds: fields[5] as int,
      averageSpeedKmh: (fields[6] as num).toDouble(),
      points: (fields[7] as List).cast<GpsPointModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, RideSessionModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.totalDistanceKm)
      ..writeByte(5)
      ..write(obj.durationSeconds)
      ..writeByte(6)
      ..write(obj.averageSpeedKmh)
      ..writeByte(7)
      ..write(obj.points);
  }
}
