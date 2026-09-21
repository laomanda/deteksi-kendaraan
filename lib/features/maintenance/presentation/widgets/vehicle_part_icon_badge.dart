import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import 'dynamic_fill_icon.dart';

/// Metadata helper that resolves specific spare part icons and thematic colors
class VehiclePartVisualInfo {
  final IconData icon;
  final Color accentColor;
  final String label;

  const VehiclePartVisualInfo({
    required this.icon,
    required this.accentColor,
    required this.label,
  });

  /// Resolves the genuine maintenance SVG asset path for any component name or category
  static String resolveSvgAsset(String rawName, {String? category}) {
    final name = rawName.toLowerCase();
    final cat = (category ?? '').toLowerCase();

    // 1. Engine Oil (Oli Mesin)
    if (name.contains('oli mesin') ||
        name.contains('engine oil') ||
        name.contains('pelumas')) {
      return 'assets/icons/maintenance/oil.svg';
    }

    // 2. Gear Oil / Transmisi (Oli Gardan / CVTF / ATF)
    if (name.contains('gardan') ||
        name.contains('gear oil') ||
        name.contains('transmisi') ||
        name.contains('atf') ||
        name.contains('cvtf')) {
      return 'assets/icons/maintenance/gear_oil.svg';
    }

    // 3. CVT / Belt / Roller
    if (name.contains('cvt') ||
        name.contains('roller') ||
        name.contains('slider') ||
        name.contains('belt') ||
        name.contains('v-belt')) {
      return 'assets/icons/maintenance/cvt.svg';
    }

    // 4. Brake System (Rem / Kampas Rem / Minyak Rem)
    if (name.contains('rem') ||
        name.contains('brake') ||
        name.contains('cakram') ||
        name.contains('kampas') ||
        name.contains('pad')) {
      return 'assets/icons/maintenance/brake.svg';
    }

    // 5. Spark Plug (Busi)
    if (name.contains('busi') || name.contains('spark')) {
      return 'assets/icons/maintenance/spark_plug.svg';
    }

    // 6. Air Filter (Filter Udara)
    if (name.contains('filter udara') ||
        name.contains('air filter') ||
        name.contains('saringan udara')) {
      return 'assets/icons/maintenance/filter.svg';
    }

    // 7. Battery / Accumulator (Aki / Baterai)
    if (name.contains('aki') ||
        name.contains('battery') ||
        name.contains('accu') ||
        name.contains('baterai')) {
      return 'assets/icons/maintenance/battery.svg';
    }

    // 8. Radiator Coolant (Air Radiator / Pendingin)
    if (name.contains('radiator') ||
        name.contains('coolant') ||
        name.contains('air radiator')) {
      return 'assets/icons/maintenance/coolant.svg';
    }

    // 9. Drive Chain & Sprocket (Rantai & Gir)
    if (name.contains('rantai') ||
        name.contains('chain') ||
        name.contains('sprocket') ||
        name.contains('gir')) {
      return 'assets/icons/maintenance/chain.svg';
    }

    // 10. Tires (Ban)
    if (name.contains('ban') ||
        name.contains('tire') ||
        name.contains('roda')) {
      return 'assets/icons/maintenance/tire.svg';
    }

    // Categorical fallbacks
    if (cat.contains('transmisi') || cat.contains('drivetrain')) {
      return 'assets/icons/maintenance/cvt.svg';
    }
    if (cat.contains('mesin')) {
      return 'assets/icons/maintenance/oil.svg';
    }
    if (cat.contains('kelistrikan')) {
      return 'assets/icons/maintenance/battery.svg';
    }

    return 'assets/icons/maintenance/oil.svg';
  }

  /// Resolves the specific visual identity for a given component name or ID
  static VehiclePartVisualInfo resolve(String rawName, {String? category}) {
    final name = rawName.toLowerCase();

    // 1. Engine Oil
    if (name.contains('oli mesin') ||
        name.contains('engine oil') ||
        name.contains('pelumas mesin')) {
      return const VehiclePartVisualInfo(
        icon: Icons.water_drop_rounded,
        accentColor: Color(0xFFF59E0B),
        label: 'Oli Mesin',
      );
    }

    // 2. Transmission / Gear Oil
    if (name.contains('gardan') ||
        name.contains('gear oil') ||
        name.contains('transmisi') ||
        name.contains('atf') ||
        name.contains('cvtf')) {
      return const VehiclePartVisualInfo(
        icon: Icons.settings_suggest_rounded,
        accentColor: Color(0xFF334E68),
        label: 'Gardan / Transmisi',
      );
    }

    // 3. Spark Plug
    if (name.contains('busi') || name.contains('spark plug')) {
      return const VehiclePartVisualInfo(
        icon: Icons.electric_bolt_rounded,
        accentColor: Color(0xFFEAB308),
        label: 'Busi',
      );
    }

    // 4. Roller & Slider CVT / Belt
    if (name.contains('roller') || name.contains('slider') || name.contains('cvt') || name.contains('belt')) {
      return const VehiclePartVisualInfo(
        icon: Icons.all_inclusive_rounded,
        accentColor: Color(0xFF8B5CF6),
        label: 'Transmisi CVT',
      );
    }

    // 5. Brake System
    if (name.contains('rem') || name.contains('brake')) {
      return const VehiclePartVisualInfo(
        icon: Icons.disc_full_rounded,
        accentColor: Color(0xFFDC2626),
        label: 'Sistem Rem',
      );
    }

    // 6. Air Filter
    if (name.contains('filter udara') || name.contains('air filter')) {
      return const VehiclePartVisualInfo(
        icon: Icons.air_rounded,
        accentColor: Color(0xFF10B981),
        label: 'Filter Udara',
      );
    }

    // 7. Battery
    if (name.contains('aki') || name.contains('battery') || name.contains('baterai') || name.contains('accu')) {
      return const VehiclePartVisualInfo(
        icon: Icons.battery_charging_full_rounded,
        accentColor: Color(0xFFF97316),
        label: 'Aki',
      );
    }

    // 8. Coolant
    if (name.contains('coolant') || name.contains('radiator') || name.contains('air radiator')) {
      return const VehiclePartVisualInfo(
        icon: Icons.thermostat_rounded,
        accentColor: Color(0xFF00A6A6),
        label: 'Air Radiator',
      );
    }

    // 9. Drive Chain
    if (name.contains('rantai') || name.contains('chain') || name.contains('gir') || name.contains('sprocket')) {
      return const VehiclePartVisualInfo(
        icon: Icons.link_rounded,
        accentColor: Color(0xFF00A6A6),
        label: 'Rantai & Gir',
      );
    }

    // 10. Tires
    if (name.contains('ban') || name.contains('tire')) {
      return const VehiclePartVisualInfo(
        icon: Icons.album_rounded,
        accentColor: Color(0xFF475569),
        label: 'Ban',
      );
    }

    return const VehiclePartVisualInfo(
      icon: Icons.build_circle_rounded,
      accentColor: AppColors.primaryNavy,
      label: 'Komponen',
    );
  }
}

/// Interactive Vehicle Part Icon Badge powered by the genuine maintenance SVG assets
/// Keeps visual identity 100% consistent across Dashboard, Maintenance Screen, and Detail Sheets.
class VehiclePartIconBadge extends StatelessWidget {
  final String componentName;
  final String? category;
  final String? status; // 'OVERDUE' | 'DUE SOON' | 'GOOD'
  final double size;
  final double iconSize;
  final VoidCallback? onTap;
  final bool showStatusDot;
  final double? healthPercentage;
  final bool useSvgAsset;

  const VehiclePartIconBadge({
    super.key,
    required this.componentName,
    this.category,
    this.status,
    this.size = 48,
    this.iconSize = 28,
    this.onTap,
    this.showStatusDot = false,
    this.healthPercentage,
    this.useSvgAsset = true,
  });

  double _resolvePercentage() {
    if (healthPercentage != null) {
      final hp = healthPercentage!;
      return hp > 1.0 ? (hp / 100.0).clamp(0.0, 1.0) : hp.clamp(0.0, 1.0);
    }
    if (status != null) {
      final s = status!.toUpperCase();
      if (s.contains('OVERDUE')) return 0.0;
      if (s.contains('DUE')) return 0.25;
      if (s.contains('GOOD')) return 0.95;
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final pct = _resolvePercentage();
    final type = category != null && category!.isNotEmpty ? category! : componentName;

    Widget badgeWidget;

    if (useSvgAsset) {
      final svgPath = VehiclePartVisualInfo.resolveSvgAsset(componentName, category: category);

      final Color statusColor;
      if (pct < 0.2 || (status != null && status!.toUpperCase().contains('OVERDUE'))) {
        statusColor = AppColors.dangerRed;
      } else if (pct < 0.5 || (status != null && status!.toUpperCase().contains('DUE'))) {
        statusColor = AppColors.warningAmber;
      } else {
        statusColor = AppColors.safeGreen;
      }

      badgeWidget = Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.18),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(
            color: (statusColor == AppColors.dangerRed)
                ? const Color(0xFFFECACA)
                : AppColors.borderSubtle,
            width: 1.2,
          ),
        ),
        child: Center(
          child: SvgPicture.asset(
            svgPath,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
          ),
        ),
      );
    } else {
      badgeWidget = DynamicFillIcon(
        componentType: type,
        percentage: pct,
        size: size,
      );
    }

    if (onTap != null) {
      badgeWidget = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size * 0.28),
        child: badgeWidget,
      );
    }

    return Semantics(
      label: 'Status $componentName: ${(pct * 100).toInt().clamp(0, 100)}%',
      child: badgeWidget,
    );
  }
}
