import 'package:intl/intl.dart';

/// Model representasi data dari tabel Supabase 'maintenance_prices'
class MaintenancePriceModel {
  final String id;
  final String? maintenanceId;
  final String vehicleType; // 'motorcycle' | 'car'
  final String? brand;
  final double minPrice;
  final double maxPrice;
  final double? laborMin;
  final double? laborMax;
  final String currency;
  final String source;
  final String updatedDate;
  final DateTime? createdAt;

  const MaintenancePriceModel({
    required this.id,
    this.maintenanceId,
    required this.vehicleType,
    this.brand,
    required this.minPrice,
    required this.maxPrice,
    this.laborMin,
    this.laborMax,
    this.currency = 'IDR',
    this.source = 'RideCare Internal Estimate',
    this.updatedDate = '2026-06-01',
    this.createdAt,
  });

  /// Total Minimum = Part Min + Labor Min
  double get minTotal => minPrice + (laborMin ?? 0.0);

  /// Total Maximum = Part Max + Labor Max
  double get maxTotal => maxPrice + (laborMax ?? 0.0);

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  String get formattedTotalRange =>
      '${_currencyFormat.format(minTotal)} - ${_currencyFormat.format(maxTotal)}';

  String get formattedPartRange =>
      '${_currencyFormat.format(minPrice)} - ${_currencyFormat.format(maxPrice)}';

  String get formattedLaborRange =>
      '${_currencyFormat.format(laborMin ?? 0)} - ${_currencyFormat.format(laborMax ?? 0)}';

  static const String priceDisclaimer =
      'Estimasi harga berdasarkan database internal RideCare. Data setidak-tidaknya diperoleh paling baru pada Juni 2026. Harga saat ini dapat berbeda tergantung kendaraan, merek komponen, lokasi, dan bengkel.';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (maintenanceId != null) 'maintenance_id': maintenanceId,
      'vehicle_type': vehicleType,
      if (brand != null) 'brand': brand,
      'min_price': minPrice,
      'max_price': maxPrice,
      if (laborMin != null) 'labor_min': laborMin,
      if (laborMax != null) 'labor_max': laborMax,
      'currency': currency,
      'source': source,
      'updated_date': updatedDate,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  factory MaintenancePriceModel.fromJson(Map<String, dynamic> json) {
    return MaintenancePriceModel(
      id: json['id'] as String,
      maintenanceId: json['maintenance_id'] as String?,
      vehicleType: json['vehicle_type'] as String? ?? 'motorcycle',
      brand: json['brand'] as String?,
      minPrice: (json['min_price'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (json['max_price'] as num?)?.toDouble() ?? 0.0,
      laborMin: (json['labor_min'] as num?)?.toDouble(),
      laborMax: (json['labor_max'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'IDR',
      source: json['source'] as String? ?? 'RideCare Internal Estimate',
      updatedDate: json['updated_date'] as String? ?? '2026-06-01',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Master Dataset Estimasi Harga Komponen Default
  static const List<MaintenancePriceModel> defaultPrices = [
    // MOTORCYCLE PRICES
    MaintenancePriceModel(
      id: 'price-mc-01-engine-oil',
      maintenanceId: 'mc-01-engine-oil',
      vehicleType: 'motorcycle',
      minPrice: 50000,
      maxPrice: 120000,
      laborMin: 10000,
      laborMax: 30000,
    ),
    MaintenancePriceModel(
      id: 'price-mc-02-gear-oil',
      maintenanceId: 'mc-02-gear-oil',
      vehicleType: 'motorcycle',
      minPrice: 15000,
      maxPrice: 35000,
      laborMin: 5000,
      laborMax: 15000,
    ),
    MaintenancePriceModel(
      id: 'price-mc-03-brake-front',
      maintenanceId: 'mc-03-brake-front',
      vehicleType: 'motorcycle',
      minPrice: 50000,
      maxPrice: 200000,
      laborMin: 20000,
      laborMax: 50000,
    ),
    MaintenancePriceModel(
      id: 'price-mc-04-brake-rear',
      maintenanceId: 'mc-04-brake-rear',
      vehicleType: 'motorcycle',
      minPrice: 45000,
      maxPrice: 180000,
      laborMin: 20000,
      laborMax: 50000,
    ),
    MaintenancePriceModel(
      id: 'price-mc-05-front-tire',
      maintenanceId: 'mc-05-front-tire',
      vehicleType: 'motorcycle',
      minPrice: 150000,
      maxPrice: 500000,
      laborMin: 15000,
      laborMax: 30000,
    ),
    MaintenancePriceModel(
      id: 'price-mc-06-rear-tire',
      maintenanceId: 'mc-06-rear-tire',
      vehicleType: 'motorcycle',
      minPrice: 180000,
      maxPrice: 600000,
      laborMin: 15000,
      laborMax: 30000,
    ),
    MaintenancePriceModel(
      id: 'price-mc-07-battery',
      maintenanceId: 'mc-07-battery',
      vehicleType: 'motorcycle',
      minPrice: 200000,
      maxPrice: 450000,
      laborMin: 10000,
      laborMax: 25000,
    ),
    MaintenancePriceModel(
      id: 'price-mc-08-spark-plug',
      maintenanceId: 'mc-08-spark-plug',
      vehicleType: 'motorcycle',
      minPrice: 25000,
      maxPrice: 120000,
      laborMin: 10000,
      laborMax: 25000,
    ),
    MaintenancePriceModel(
      id: 'price-mc-09-air-filter',
      maintenanceId: 'mc-09-air-filter',
      vehicleType: 'motorcycle',
      minPrice: 45000,
      maxPrice: 95000,
      laborMin: 10000,
      laborMax: 20000,
    ),
    MaintenancePriceModel(
      id: 'price-mc-10-cvt-service',
      maintenanceId: 'mc-10-cvt-service',
      vehicleType: 'motorcycle',
      minPrice: 50000,
      maxPrice: 150000,
      laborMin: 50000,
      laborMax: 150000,
    ),
    MaintenancePriceModel(
      id: 'price-mc-11-cvt-belt',
      maintenanceId: 'mc-11-cvt-belt',
      vehicleType: 'motorcycle',
      minPrice: 120000,
      maxPrice: 250000,
      laborMin: 35000,
      laborMax: 70000,
    ),
    MaintenancePriceModel(
      id: 'price-mc-12-coolant',
      maintenanceId: 'mc-12-coolant',
      vehicleType: 'motorcycle',
      minPrice: 30000,
      maxPrice: 80000,
      laborMin: 15000,
      laborMax: 35000,
    ),
    MaintenancePriceModel(
      id: 'price-mc-13-brake-fluid',
      maintenanceId: 'mc-13-brake-fluid',
      vehicleType: 'motorcycle',
      minPrice: 25000,
      maxPrice: 60000,
      laborMin: 20000,
      laborMax: 40000,
    ),
    MaintenancePriceModel(
      id: 'price-mc-14-drive-chain',
      maintenanceId: 'mc-14-drive-chain',
      vehicleType: 'motorcycle',
      minPrice: 150000,
      maxPrice: 380000,
      laborMin: 25000,
      laborMax: 50000,
    ),

    // CAR PRICES
    MaintenancePriceModel(
      id: 'price-car-01-engine-oil',
      maintenanceId: 'car-01-engine-oil',
      vehicleType: 'car',
      minPrice: 250000,
      maxPrice: 600000,
      laborMin: 50000,
      laborMax: 150000,
    ),
    MaintenancePriceModel(
      id: 'price-car-02-oil-filter',
      maintenanceId: 'car-02-oil-filter',
      vehicleType: 'car',
      minPrice: 40000,
      maxPrice: 120000,
      laborMin: 25000,
      laborMax: 50000,
    ),
    MaintenancePriceModel(
      id: 'price-car-03-air-filter',
      maintenanceId: 'car-03-air-filter',
      vehicleType: 'car',
      minPrice: 80000,
      maxPrice: 220000,
      laborMin: 20000,
      laborMax: 40000,
    ),
    MaintenancePriceModel(
      id: 'price-car-04-cabin-filter',
      maintenanceId: 'car-04-cabin-filter',
      vehicleType: 'car',
      minPrice: 70000,
      maxPrice: 180000,
      laborMin: 20000,
      laborMax: 40000,
    ),
    MaintenancePriceModel(
      id: 'price-car-05-brake-front',
      maintenanceId: 'car-05-brake-front',
      vehicleType: 'car',
      minPrice: 250000,
      maxPrice: 750000,
      laborMin: 75000,
      laborMax: 175000,
    ),
    MaintenancePriceModel(
      id: 'price-car-06-brake-rear',
      maintenanceId: 'car-06-brake-rear',
      vehicleType: 'car',
      minPrice: 220000,
      maxPrice: 650000,
      laborMin: 75000,
      laborMax: 175000,
    ),
    MaintenancePriceModel(
      id: 'price-car-07-front-tire',
      maintenanceId: 'car-07-front-tire',
      vehicleType: 'car',
      minPrice: 550000,
      maxPrice: 1800000,
      laborMin: 40000,
      laborMax: 80000,
    ),
    MaintenancePriceModel(
      id: 'price-car-08-rear-tire',
      maintenanceId: 'car-08-rear-tire',
      vehicleType: 'car',
      minPrice: 550000,
      maxPrice: 1800000,
      laborMin: 40000,
      laborMax: 80000,
    ),
    MaintenancePriceModel(
      id: 'price-car-09-battery',
      maintenanceId: 'car-09-battery',
      vehicleType: 'car',
      minPrice: 700000,
      maxPrice: 1900000,
      laborMin: 30000,
      laborMax: 60000,
    ),
    MaintenancePriceModel(
      id: 'price-car-10-spark-plug',
      maintenanceId: 'car-10-spark-plug',
      vehicleType: 'car',
      minPrice: 120000,
      maxPrice: 480000,
      laborMin: 50000,
      laborMax: 120000,
    ),
    MaintenancePriceModel(
      id: 'price-car-11-coolant',
      maintenanceId: 'car-11-coolant',
      vehicleType: 'car',
      minPrice: 75000,
      maxPrice: 180000,
      laborMin: 40000,
      laborMax: 90000,
    ),
    MaintenancePriceModel(
      id: 'price-car-12-brake-fluid',
      maintenanceId: 'car-12-brake-fluid',
      vehicleType: 'car',
      minPrice: 60000,
      maxPrice: 150000,
      laborMin: 50000,
      laborMax: 100000,
    ),
    MaintenancePriceModel(
      id: 'price-car-13-transmission-fluid',
      maintenanceId: 'car-13-transmission-fluid',
      vehicleType: 'car',
      minPrice: 300000,
      maxPrice: 850000,
      laborMin: 75000,
      laborMax: 180000,
    ),
    MaintenancePriceModel(
      id: 'price-car-14-wiper',
      maintenanceId: 'car-14-wiper',
      vehicleType: 'car',
      minPrice: 60000,
      maxPrice: 250000,
      laborMin: 15000,
      laborMax: 35000,
    ),
  ];

  static MaintenancePriceModel? getPriceForMaintenance(
    String maintenanceIdOrName, {
    String vehicleType = 'motorcycle',
  }) {
    final needle = maintenanceIdOrName.toLowerCase();
    for (final p in defaultPrices) {
      if (p.vehicleType.toLowerCase() == vehicleType.toLowerCase()) {
        if (p.maintenanceId?.toLowerCase() == needle ||
            needle.contains(p.maintenanceId?.toLowerCase() ?? '---') ||
            (p.maintenanceId != null && needle.contains(p.maintenanceId!.toLowerCase().replaceAll('-', ' ')))) {
          return p;
        }
      }
    }
    // Fallback: match by maintenanceId keyword
    for (final p in defaultPrices) {
      if (p.vehicleType.toLowerCase() == vehicleType.toLowerCase()) {
        final keyPart = p.maintenanceId?.split('-').last ?? '';
        if (keyPart.isNotEmpty && needle.contains(keyPart)) {
          return p;
        }
      }
    }
    return null;
  }
}
