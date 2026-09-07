/// Model representasi data dari tabel Supabase 'vehicle_maintenance'
class VehicleMaintenanceModel {
  final String id;
  final String vehicleId;
  final String maintenanceId;
  DateTime? lastServiceDate;
  int lastServiceOdometer;
  int healthPercentage; // 0 to 100
  String status; // 'GOOD' | 'DUE_SOON' | 'OVERDUE'
  final DateTime? createdAt;
  DateTime? updatedAt;

  // Cached metadata for offline fast UI display
  final String? itemName;
  final String? itemCategory;
  final int? intervalKm;
  final int? intervalMonth;

  VehicleMaintenanceModel({
    required this.id,
    required this.vehicleId,
    required this.maintenanceId,
    this.lastServiceDate,
    this.lastServiceOdometer = 0,
    this.healthPercentage = 100,
    this.status = 'GOOD',
    this.createdAt,
    this.updatedAt,
    this.itemName,
    this.itemCategory,
    this.intervalKm,
    this.intervalMonth,
  });

  bool get isGood => status.toUpperCase() == 'GOOD';
  bool get isDueSoon =>
      status.toUpperCase() == 'DUE_SOON' || status.toUpperCase() == 'DUE SOON';
  bool get isOverdue => status.toUpperCase() == 'OVERDUE';

  VehicleMaintenanceModel copyWith({
    String? id,
    String? vehicleId,
    String? maintenanceId,
    DateTime? lastServiceDate,
    int? lastServiceOdometer,
    int? healthPercentage,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? itemName,
    String? itemCategory,
    int? intervalKm,
    int? intervalMonth,
  }) {
    return VehicleMaintenanceModel(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      maintenanceId: maintenanceId ?? this.maintenanceId,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      lastServiceOdometer: lastServiceOdometer ?? this.lastServiceOdometer,
      healthPercentage: healthPercentage ?? this.healthPercentage,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemName: itemName ?? this.itemName,
      itemCategory: itemCategory ?? this.itemCategory,
      intervalKm: intervalKm ?? this.intervalKm,
      intervalMonth: intervalMonth ?? this.intervalMonth,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'maintenance_id': maintenanceId,
      if (lastServiceDate != null)
        'last_service_date': lastServiceDate!.toIso8601String().split('T')[0],
      'last_service_odometer': lastServiceOdometer,
      'health_percentage': healthPercentage,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// JSON for local Hive caching (with metadata)
  Map<String, dynamic> toLocalJson() {
    final map = toJson();
    if (itemName != null) map['item_name'] = itemName;
    if (itemCategory != null) map['item_category'] = itemCategory;
    if (intervalKm != null) map['interval_km'] = intervalKm;
    if (intervalMonth != null) map['interval_month'] = intervalMonth;
    return map;
  }

  factory VehicleMaintenanceModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['last_service_date'] != null) {
      parsedDate = DateTime.tryParse(json['last_service_date'].toString());
    }

    final hp = json['health_percentage'];
    final int healthVal = hp is num ? hp.round() : int.tryParse(hp.toString()) ?? 100;

    final odo = json['last_service_odometer'];
    final int odoVal = odo is num ? odo.round() : int.tryParse(odo.toString()) ?? 0;

    return VehicleMaintenanceModel(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      maintenanceId: json['maintenance_id'] as String,
      lastServiceDate: parsedDate,
      lastServiceOdometer: odoVal,
      healthPercentage: healthVal,
      status: json['status'] as String? ?? 'GOOD',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      itemName: json['item_name'] as String?,
      itemCategory: json['item_category'] as String?,
      intervalKm: (json['interval_km'] as num?)?.toInt(),
      intervalMonth: (json['interval_month'] as num?)?.toInt(),
    );
  }
}
