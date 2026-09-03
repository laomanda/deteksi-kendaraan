import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/component_catalog.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../shared/providers/repository_providers.dart';

/// Screen displaying the historical ledger of completed services (PRD Section 6 & DSS Section 9.3)
class ServiceHistoryScreen extends ConsumerWidget {
  const ServiceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    final repo = ref.watch(maintenanceRepositoryProvider);

    if (activeVehicle == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Riwayat Servis', style: AppTypography.heading2)),
        body: const Center(child: Text('Kendaraan belum dipilih')),
      );
    }

    final logs = repo.getServiceHistoryForVehicle(activeVehicle.id);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Riwayat Servis', style: AppTypography.heading2),
        elevation: 0,
      ),
      body: SafeArea(
        child: logs.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: AppSpacing.space12),
                      Text(
                        'Belum Ada Catatan Servis',
                        style: AppTypography.heading2,
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        'Catatan penggantian oli atau suku cadang akan tersimpan secara teratur di sini.',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.space16),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.space12),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final meta = ComponentCatalog.findMetadata(
                    activeVehicle.vehicleType,
                    log.componentType,
                  );
                  final name = meta?.displayName ?? log.componentType;

                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.space16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: AppSpacing.cardBorderRadius,
                      border: AppSpacing.cardBorder,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(name, style: AppTypography.heading3),
                            Text(
                              DateFormatter.formatDate(log.serviceDate),
                              style: AppTypography.captionSubtle,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space8),
                        Row(
                          children: [
                            Text(
                              'Odometer: ${DateFormatter.formatKm(log.serviceKm)}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (log.cost > 0) ...[
                              const SizedBox(width: AppSpacing.space16),
                              Text(
                                'Biaya: ${DateFormatter.formatCurrency(log.cost)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.secondaryTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (log.notes.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.space8),
                          Text(
                            log.notes,
                            style: AppTypography.captionSubtle.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
