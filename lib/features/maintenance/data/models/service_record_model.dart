import 'package:intl/intl.dart';

/// Model representasi data dari tabel Supabase 'service_records'
class ServiceRecordModel {
  final String id;
  final String vehicleId;
  final String? maintenanceId;
  final DateTime serviceDate;
  final int odometer;
  final double cost;
  final String? workshop;
  final String? notes;
  final String? photoUrl;
  final DateTime? createdAt;

  // Cached metadata for display
  final String? maintenanceName;

  const ServiceRecordModel({
    required this.id,
    required this.vehicleId,
    this.maintenanceId,
    required this.serviceDate,
    required this.odometer,
    required this.cost,
    this.workshop,
    this.notes,
    this.photoUrl,
    this.createdAt,
    this.maintenanceName,
  });

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  String get formattedCost => _currencyFormat.format(cost);
  String get formattedDate => DateFormat('dd MMM yyyy').format(serviceDate);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      if (maintenanceId != null) 'maintenance_id': maintenanceId,
      'service_date': serviceDate.toIso8601String().split('T')[0],
      'odometer': odometer,
      'cost': cost,
      if (workshop != null) 'workshop': workshop,
      if (notes != null) 'notes': notes,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toLocalJson() {
    final map = toJson();
    if (maintenanceName != null) map['maintenance_name'] = maintenanceName;
    return map;
  }

  factory ServiceRecordModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['service_date'] != null) {
      parsedDate = DateTime.tryParse(json['service_date'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final odo = json['odometer'] ?? json['serviceKm'] ?? 0;
    final int odoVal = odo is num ? odo.round() : int.tryParse(odo.toString()) ?? 0;

    final c = json['cost'] ?? 0;
    final double costVal = c is num ? c.toDouble() : double.tryParse(c.toString()) ?? 0.0;

    return ServiceRecordModel(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String? ?? json['vehicleId'] as String? ?? '',
      maintenanceId: json['maintenance_id'] as String? ?? json['componentType'] as String?,
      serviceDate: parsedDate,
      odometer: odoVal,
      cost: costVal,
      workshop: json['workshop'] as String?,
      notes: json['notes'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      maintenanceName: json['maintenance_name'] as String? ?? json['componentType'] as String?,
    );
  }
}
