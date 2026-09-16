import 'package:flutter/material.dart';
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

  /// Resolves the specific visual identity for a given component name or ID
  static VehiclePartVisualInfo resolve(String rawName, {String? category}) {
    final name = rawName.toLowerCase();
    final cat = (category ?? '').toLowerCase();

    // 1. Engine Oil (Oli Mesin)
    if (name.contains('oli mesin') ||
        name.contains('engine oil') ||
        name.contains('pelumas mesin')) {
      return const VehiclePartVisualInfo(
        icon: Icons.water_drop_rounded,
        accentColor: Color(0xFFF59E0B), // Warm Amber
        label: 'Oli Mesin',
      );
    }

    // 2. Transmission / Gear Oil (Oli Gardan / CVTF / ATF)
    if (name.contains('gardan') ||
        name.contains('gear oil') ||
        name.contains('transmisi') ||
        name.contains('atf') ||
        name.contains('cvtf')) {
      return const VehiclePartVisualInfo(
        icon: Icons.settings_suggest_rounded,
        accentColor: Color(0xFF6366F1), // Modern Indigo
        label: 'Gardan / Transmisi',
      );
    }

    // 3. Spark Plug (Busi)
    if (name.contains('busi') || name.contains('spark plug')) {
      return const VehiclePartVisualInfo(
        icon: Icons.electric_bolt_rounded,
        accentColor: Color(0xFFEAB308), // Electric Gold
        label: 'Busi',
      );
    }

    // 4. Roller & Slider CVT
    if (name.contains('roller') || name.contains('slider')) {
      return const VehiclePartVisualInfo(
        icon: Icons.motion_photos_on_rounded,
        accentColor: Color(0xFFA855F7), // Vibrant Purple
        label: 'Roller CVT',
      );
    }

    // 5. CVT Belt / V-Belt
    if (name.contains('belt') || name.contains('cvt') || name.contains('v-belt')) {
      return const VehiclePartVisualInfo(
        icon: Icons.all_inclusive_rounded,
        accentColor: Color(0xFF8B5CF6), // Deep Violet
        label: 'Drive Belt',
      );
    }

    // 6. Brake Pads & Fluids (Rem & Kampas)
    if (name.contains('rem') || name.contains('brake')) {
      if (name.contains('minyak')) {
        return const VehiclePartVisualInfo(
          icon: Icons.opacity_rounded,
          accentColor: Color(0xFFE11D48), // Rose Red
          label: 'Minyak Rem',
        );
      }
      return const VehiclePartVisualInfo(
        icon: Icons.disc_full_rounded,
        accentColor: Color(0xFFEF4444), // Crimson Red
        label: 'Kampas Rem',
      );
    }

    // 7. Air Filter (Filter Udara)
    if (name.contains('filter udara') || name.contains('air filter')) {
      return const VehiclePartVisualInfo(
        icon: Icons.air_rounded,
        accentColor: Color(0xFF10B981), // Fresh Emerald
        label: 'Filter Udara',
      );
    }

    // 8. Cabin Filter (Filter AC / Kabin)
    if (name.contains('kabin') || name.contains('cabin') || name.contains('ac')) {
      return const VehiclePartVisualInfo(
        icon: Icons.ac_unit_rounded,
        accentColor: Color(0xFF0284C7), // Sky Blue
        label: 'Filter AC',
      );
    }

    // 9. Fuel Filter (Filter Bensin / Solar)
    if (name.contains('bensin') || name.contains('fuel') || name.contains('solar')) {
      return const VehiclePartVisualInfo(
        icon: Icons.local_gas_station_rounded,
        accentColor: Color(0xFFE11D48), // Ruby
        label: 'Filter Bahan Bakar',
      );
    }

    // 10. Oil Filter (Filter Oli)
    if (name.contains('filter oli') || name.contains('oil filter')) {
      return const VehiclePartVisualInfo(
        icon: Icons.filter_alt_rounded,
        accentColor: Color(0xFFD97706), // Amber Bronze
        label: 'Filter Oli',
      );
    }

    // 11. Coolant / Radiator
    if (name.contains('coolant') ||
        name.contains('radiator') ||
        name.contains('air radiator')) {
      return const VehiclePartVisualInfo(
        icon: Icons.thermostat_rounded,
        accentColor: Color(0xFF06B6D4), // Cyan
        label: 'Coolant',
      );
    }

    // 12. Battery / Aki
    if (name.contains('aki') ||
        name.contains('battery') ||
        name.contains('baterai') ||
        name.contains('accu')) {
      return const VehiclePartVisualInfo(
        icon: Icons.battery_charging_full_rounded,
        accentColor: Color(0xFFF97316), // Dynamic Orange
        label: 'Aki',
      );
    }

    // 13. Drive Chain & Sprocket (Rantai & Gir)
    if (name.contains('rantai') ||
        name.contains('chain') ||
        name.contains('gir') ||
        name.contains('sprocket')) {
      return const VehiclePartVisualInfo(
        icon: Icons.link_rounded,
        accentColor: Color(0xFF14B8A6), // Teal
        label: 'Rantai & Gir',
      );
    }

    // 14. Clutch (Kopling)
    if (name.contains('kopling') || name.contains('clutch')) {
      return const VehiclePartVisualInfo(
        icon: Icons.donut_large_rounded,
        accentColor: Color(0xFFB45309), // Earth Amber
        label: 'Kopling',
      );
    }

    // 15. Tires (Ban)
    if (name.contains('ban') || name.contains('tire')) {
      return const VehiclePartVisualInfo(
        icon: Icons.album_rounded,
        accentColor: Color(0xFF475569), // Slate
        label: 'Ban',
      );
    }

    // 16. Suspension / Shockbreaker
    if (name.contains('shock') || name.contains('suspensi') || name.contains('fork')) {
      return const VehiclePartVisualInfo(
        icon: Icons.swap_vert_rounded,
        accentColor: Color(0xFF64748B), // Steel Grey
        label: 'Suspensi',
      );
    }

    // Fallback by category
    if (cat.contains('mesin')) {
      return const VehiclePartVisualInfo(
        icon: Icons.engineering_rounded,
        accentColor: Color(0xFFF59E0B),
        label: 'Mesin',
      );
    } else if (cat.contains('kelistrikan')) {
      return const VehiclePartVisualInfo(
        icon: Icons.bolt_rounded,
        accentColor: Color(0xFFEAB308),
        label: 'Kelistrikan',
      );
    }

    // Default universal spare part icon
    return const VehiclePartVisualInfo(
      icon: Icons.build_circle_rounded,
      accentColor: Color(0xFF2563EB), // Primary Blue
      label: 'Komponen',
    );
  }
}

/// Interactive Vehicle Part Icon Badge powered by the signature DynamicFillIcon (100% to 0% fill) system.
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

  const VehiclePartIconBadge({
    super.key,
    required this.componentName,
    this.category,
    this.status,
    this.size = 44,
    this.iconSize = 24,
    this.onTap,
    this.showStatusDot = false,
    this.healthPercentage,
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

    Widget dynamicIcon = DynamicFillIcon(
      componentType: type,
      percentage: pct,
      size: size,
    );

    if (onTap != null) {
      dynamicIcon = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size * 0.25),
        child: dynamicIcon,
      );
    }

    return Semantics(
      label: 'Status $componentName: ${(pct * 100).toInt()}%',
      child: dynamicIcon,
    );
  }
}
