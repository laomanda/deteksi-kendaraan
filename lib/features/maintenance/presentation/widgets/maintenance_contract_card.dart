import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/dashboard_maintenance_item.dart';
import 'vehicle_part_icon_badge.dart';

/// Reusable Maintenance Card adhering strictly to UI Data Contract (Requirement 9):
/// Displays:
/// - Component
/// - Interval
/// - Next Service KM
/// - Remaining KM
/// - Health %
/// - Status ('GOOD' | 'WARNING' | 'OVERDUE')
class MaintenanceContractCard extends StatelessWidget {
  final DashboardMaintenanceItem item;
  final VoidCallback? onTap;

  const MaintenanceContractCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final Color statusBg;
    final Color statusBorder;
    final String statusBadge;

    if (item.isOverdue) {
      statusColor = AppColors.dangerRed;
      statusBg = const Color(0xFFFEF2F2);
      statusBorder = const Color(0xFFFECACA);
      statusBadge = 'OVERDUE';
    } else if (item.isWarning) {
      statusColor = AppColors.warningAmber;
      statusBg = const Color(0xFFFFFBEB);
      statusBorder = const Color(0xFFFDE68A);
      statusBadge = 'WARNING';
    } else {
      statusColor = AppColors.safeGreen;
      statusBg = const Color(0xFFF0FDF4);
      statusBorder = const Color(0xFFBBF7D0);
      statusBadge = 'GOOD';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isOverdue ? const Color(0xFFFECACA) : AppColors.borderSubtle,
          width: item.isOverdue ? 1.4 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06102A43),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Component Icon Badge, Component Name, & Status Tag
                Row(
                  children: [
                    VehiclePartIconBadge(
                      componentName: item.componentName,
                      category: item.componentName,
                      status: item.status,
                      healthPercentage: item.healthPercentage.toDouble(),
                      size: 44,
                      iconSize: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.componentName,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.primaryNavy,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.description.isNotEmpty
                                ? item.description
                                : 'Interval: ${DateFormatter.formatKm(item.intervalKm.toDouble())}',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.secondarySteel,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusBorder),
                      ),
                      child: Text(
                        statusBadge,
                        style: GoogleFonts.plusJakartaSans(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1EFE9)),
                const SizedBox(height: 12),

                // Metrics Grid: Next Service KM, Remaining KM, Health %
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricCol(
                      label: 'Interval',
                      value: '${item.intervalKm} KM',
                    ),
                    _buildMetricCol(
                      label: 'Next Service',
                      value: '${item.nextServiceKm} KM',
                    ),
                    _buildMetricCol(
                      label: 'Remaining',
                      value: item.remainingKm > 0 ? '${item.remainingKm} KM' : '0 KM',
                      valueColor: item.isOverdue ? AppColors.dangerRed : null,
                    ),
                    _buildMetricCol(
                      label: 'Health',
                      value: '${item.healthPercentage}%',
                      valueColor: statusColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.secondarySteel,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: valueColor ?? AppColors.primaryNavy,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
