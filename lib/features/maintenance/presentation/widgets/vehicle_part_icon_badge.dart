import 'package:flutter/material.dart';

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

/// Interactive Vehicle Part Icon Badge with thematic pastel background,
/// micro-animation feedback on press, and optional status indicator dot.
class VehiclePartIconBadge extends StatefulWidget {
  final String componentName;
  final String? category;
  final String? status; // 'OVERDUE' | 'DUE SOON' | 'GOOD'
  final double size;
  final double iconSize;
  final VoidCallback? onTap;
  final bool showStatusDot;

  const VehiclePartIconBadge({
    super.key,
    required this.componentName,
    this.category,
    this.status,
    this.size = 46,
    this.iconSize = 24,
    this.onTap,
    this.showStatusDot = true,
  });

  @override
  State<VehiclePartIconBadge> createState() => _VehiclePartIconBadgeState();
}

class _VehiclePartIconBadgeState extends State<VehiclePartIconBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color? _getStatusDotColor() {
    if (widget.status == null) return null;
    final s = widget.status!.toUpperCase();
    if (s.contains('OVERDUE')) return const Color(0xFFEF4444);
    if (s.contains('DUE')) return const Color(0xFFF59E0B);
    if (s.contains('GOOD')) return const Color(0xFF10B981);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final visual = VehiclePartVisualInfo.resolve(
      widget.componentName,
      category: widget.category,
    );
    final dotColor = _getStatusDotColor();

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(widget.size * 0.32),
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) {
                if (widget.onTap != null) _controller.forward();
              },
              onTapUp: (_) {
                if (widget.onTap != null) _controller.reverse();
              },
              onTapCancel: () {
                if (widget.onTap != null) _controller.reverse();
              },
              borderRadius: BorderRadius.circular(widget.size * 0.32),
              splashColor: visual.accentColor.withValues(alpha: 0.25),
              highlightColor: visual.accentColor.withValues(alpha: 0.12),
              child: Ink(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: visual.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(widget.size * 0.32),
                  border: Border.all(
                    color: visual.accentColor.withValues(alpha: 0.24),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    visual.icon,
                    size: widget.iconSize,
                    color: visual.accentColor,
                  ),
                ),
              ),
            ),
          ),
          if (widget.showStatusDot && dotColor != null)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: dotColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
