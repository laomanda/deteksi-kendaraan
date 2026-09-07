import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../data/models/maintenance_catalog_model.dart';
import '../data/models/maintenance_price_model.dart';
import '../data/models/service_record_model.dart';
import '../data/models/vehicle_maintenance_model.dart';
import '../data/repositories/maintenance_repository.dart';
import '../domain/health_calculation_service.dart';

/// Provider instance singleton untuk MaintenanceRepository
final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepository();
});

/// Provider katalog maintenance berdasarkan tipe kendaraan ('motorcycle' | 'car')
final maintenanceCatalogProvider =
    FutureProvider.family<List<MaintenanceCatalogModel>, String>((ref, vehicleType) async {
  final repo = ref.watch(maintenanceRepositoryProvider);
  return repo.getCatalog(vehicleType: vehicleType);
});

/// Provider master harga library berdasarkan tipe kendaraan
final maintenancePricesProvider =
    FutureProvider.family<List<MaintenancePriceModel>, String>((ref, vehicleType) async {
  final repo = ref.watch(maintenanceRepositoryProvider);
  return repo.getPrices(vehicleType: vehicleType);
});

/// StateNotifier untuk mengelola daftar VehicleMaintenance per vehicleId
class VehicleMaintenanceNotifier
    extends StateNotifier<AsyncValue<List<VehicleMaintenanceModel>>> {
  final MaintenanceRepository _repository;
  final String vehicleId;
  final String vehicleType;

  VehicleMaintenanceNotifier({
    required MaintenanceRepository repository,
    required this.vehicleId,
    this.vehicleType = 'motorcycle',
  })  : _repository = repository,
        super(repository.getCachedVehicleMaintenance(vehicleId) != null
            ? AsyncValue.data(repository.getCachedVehicleMaintenance(vehicleId)!)
            : const AsyncValue.loading()) {
    loadItems();
  }

  Future<void> loadItems() async {
    try {
      if (state.value == null) {
        state = const AsyncValue.loading();
      }
      final items = await _repository.getVehicleMaintenance(
        vehicleId,
        vehicleType: vehicleType,
      );
      if (!mounted) return;
      state = AsyncValue.data(items);
    } catch (e, st) {
      if (!mounted) return;
      if (state.value == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> updateItem(VehicleMaintenanceModel item) async {
    await _repository.updateVehicleMaintenance(item);
    await loadItems();
  }

  Future<void> refresh() async {
    await loadItems();
  }
}

final vehicleMaintenanceProvider = StateNotifierProvider.family<
    VehicleMaintenanceNotifier,
    AsyncValue<List<VehicleMaintenanceModel>>,
    String>((ref, vehicleId) {
  final repo = ref.watch(maintenanceRepositoryProvider);
  final vehiclesState = ref.watch(vehicleListProvider);

  String vehicleType = 'motorcycle';
  vehiclesState.whenData((list) {
    final v = list.where((e) => e.id == vehicleId).firstOrNull;
    if (v != null) {
      vehicleType = v.vehicleType;
    }
  });

  return VehicleMaintenanceNotifier(
    repository: repo,
    vehicleId: vehicleId,
    vehicleType: vehicleType,
  );
});

/// StateNotifier untuk mengelola riwayat servis per vehicleId
class ServiceRecordsNotifier
    extends StateNotifier<AsyncValue<List<ServiceRecordModel>>> {
  final MaintenanceRepository _repository;
  final String vehicleId;

  ServiceRecordsNotifier({
    required MaintenanceRepository repository,
    required this.vehicleId,
  })  : _repository = repository,
        super(const AsyncValue.loading()) {
    loadRecords();
  }

  Future<void> loadRecords() async {
    try {
      state = const AsyncValue.loading();
      final records = await _repository.getServiceRecords(vehicleId);
      if (!mounted) return;
      state = AsyncValue.data(records);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRecord(ServiceRecordModel record) async {
    await _repository.addServiceRecord(record);
    await loadRecords();
  }

  Future<void> refresh() async {
    await loadRecords();
  }
}

final serviceRecordsProvider = StateNotifierProvider.family<
    ServiceRecordsNotifier,
    AsyncValue<List<ServiceRecordModel>>,
    String>((ref, vehicleId) {
  final repo = ref.watch(maintenanceRepositoryProvider);
  return ServiceRecordsNotifier(repository: repo, vehicleId: vehicleId);
});

/// DTO Ringkasan Kesehatan Kendaraan untuk UI
class VehicleHealthSummary {
  final double overallScore; // 0.0 to 100.0
  final List<VehicleMaintenanceHealth> healthItems;
  final int goodCount;
  final int dueSoonCount;
  final int overdueCount;

  const VehicleHealthSummary({
    required this.overallScore,
    required this.healthItems,
    required this.goodCount,
    required this.dueSoonCount,
    required this.overdueCount,
  });

  bool get hasIssues => dueSoonCount > 0 || overdueCount > 0;
}

/// Provider terkomputasi yang menghitung skor kesehatan deterministik offline
final maintenanceHealthProvider =
    Provider.family<AsyncValue<VehicleHealthSummary>, String>((ref, vehicleId) {
  final vmAsync = ref.watch(vehicleMaintenanceProvider(vehicleId));
  final vehiclesAsync = ref.watch(vehicleListProvider);

  return vmAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (vmList) {
      // Dapatkan current odometer kendaraan
      int currentOdo = 0;
      String vType = 'motorcycle';

      vehiclesAsync.whenData((list) {
        final v = list.where((it) => it.id == vehicleId).firstOrNull;
        if (v != null) {
          currentOdo = v.currentOdometer;
          vType = v.vehicleType;
        }
      });

      final repo = ref.read(maintenanceRepositoryProvider);

      final healthList = vmList.map((vm) {
        final intervalKm = vm.intervalKm ?? 3000;
        final priceEstimate = repo.getEstimatedPrice(
          vm.itemName ?? vm.maintenanceId,
          vehicleType: vType,
        );

        return HealthCalculationService.calculateItemHealth(
          item: vm,
          currentOdometer: currentOdo,
          defaultIntervalKm: intervalKm,
          priceEstimate: priceEstimate,
        );
      }).toList();

      final overall = HealthCalculationService.calculateOverallScore(healthList);
      final good = healthList.where((h) => h.isGood).length;
      final dueSoon = healthList.where((h) => h.isDueSoon).length;
      final overdue = healthList.where((h) => h.isOverdue).length;

      return AsyncValue.data(
        VehicleHealthSummary(
          overallScore: overall,
          healthItems: healthList,
          goodCount: good,
          dueSoonCount: dueSoon,
          overdueCount: overdue,
        ),
      );
    },
  );
});
