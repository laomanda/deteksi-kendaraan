import 'package:flutter/material.dart';

/// Registry generating clean, normalized (0.0 to 1.0) automotive vector paths for each component type
class ComponentPathRegistry {
  ComponentPathRegistry._();

  /// Normalizes any input string (e.g. 'Ban Depan/Belakang' -> 'ban_depan_belakang')
  static String normalize(String key) {
    return key
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Gets the normalized path (in [0,0] to [1,1] space) scaled to [size]
  static Path getPath(String componentType, Size size) {
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;
    final normalized = normalize(componentType);

    // Grouping by component category with full alias tolerance
    if (normalized == 'battery' ||
        normalized.contains('aki') ||
        normalized.contains('accu') ||
        normalized.contains('battery')) {
      // Battery block with positive & negative terminal posts
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.28, h * 0.18, w * 0.14, h * 0.10),
          Radius.circular(w * 0.02),
        ),
      );
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.58, h * 0.18, w * 0.14, h * 0.10),
          Radius.circular(w * 0.02),
        ),
      );
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.18, h * 0.26, w * 0.64, h * 0.62),
          Radius.circular(w * 0.08),
        ),
      );
    } else if (normalized == 'gear_oil' ||
        normalized == 'gearoil' ||
        normalized.contains('gardan') ||
        normalized.contains('at_fluid') ||
        normalized.contains('mt_fluid') ||
        normalized.contains('atf') ||
        normalized.contains('cvtf') ||
        normalized.contains('transmisi')) {
      // Gear contour container
      path.moveTo(w * 0.40, h * 0.15);
      path.lineTo(w * 0.60, h * 0.15);
      path.lineTo(w * 0.60, h * 0.30);
      path.lineTo(w * 0.80, h * 0.40);
      path.lineTo(w * 0.80, h * 0.90);
      path.cubicTo(w * 0.80, h * 0.96, w * 0.75, h * 0.96, w * 0.70, h * 0.96);
      path.lineTo(w * 0.30, h * 0.96);
      path.cubicTo(w * 0.25, h * 0.96, w * 0.20, h * 0.96, w * 0.20, h * 0.90);
      path.lineTo(w * 0.20, h * 0.40);
      path.lineTo(w * 0.40, h * 0.30);
      path.close();
    } else if (normalized == 'tires' ||
        normalized.contains('tire') ||
        normalized.contains('ban')) {
      // Wheel tire outer profile with inner rim cutout
      path.addOval(Rect.fromLTWH(w * 0.16, h * 0.16, w * 0.68, h * 0.68));
    } else if (normalized == 'cvt_belt' ||
        normalized == 'cvtbelt' ||
        normalized.contains('cvt') ||
        normalized.contains('belt') ||
        normalized.contains('roller')) {
      // Dual pulley with belt drive outline
      path.addOval(Rect.fromLTWH(w * 0.18, h * 0.32, w * 0.30, h * 0.36));
      path.addOval(Rect.fromLTWH(w * 0.52, h * 0.32, w * 0.30, h * 0.36));
      path.moveTo(w * 0.33, h * 0.32);
      path.lineTo(w * 0.67, h * 0.32);
      path.lineTo(w * 0.67, h * 0.68);
      path.lineTo(w * 0.33, h * 0.68);
      path.close();
    } else if (normalized == 'brake_pad' ||
        normalized == 'brakepad' ||
        normalized.contains('brake') ||
        normalized.contains('rem')) {
      // Automotive brake caliper & pad outline
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.20, h * 0.25, w * 0.60, h * 0.55),
          Radius.circular(w * 0.12),
        ),
      );
      path.moveTo(w * 0.15, h * 0.40);
      path.lineTo(w * 0.20, h * 0.40);
      path.lineTo(w * 0.20, h * 0.65);
      path.lineTo(w * 0.15, h * 0.65);
      path.close();
      path.moveTo(w * 0.80, h * 0.40);
      path.lineTo(w * 0.85, h * 0.40);
      path.lineTo(w * 0.85, h * 0.65);
      path.lineTo(w * 0.80, h * 0.65);
      path.close();
    } else if (normalized == 'spark_plug' ||
        normalized == 'sparkplug' ||
        normalized.contains('busi') ||
        normalized.contains('spark')) {
      // Spark plug insulator, thread and electrode
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.42, h * 0.12, w * 0.16, h * 0.10),
          Radius.circular(w * 0.02),
        ),
      );
      path.moveTo(w * 0.36, h * 0.22);
      path.lineTo(w * 0.64, h * 0.22);
      path.lineTo(w * 0.60, h * 0.48);
      path.lineTo(w * 0.40, h * 0.48);
      path.close();
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.30, h * 0.48, w * 0.40, h * 0.36),
          Radius.circular(w * 0.04),
        ),
      );
      path.moveTo(w * 0.45, h * 0.84);
      path.lineTo(w * 0.45, h * 0.94);
      path.lineTo(w * 0.55, h * 0.94);
      path.lineTo(w * 0.55, h * 0.88);
    } else if (normalized == 'drive_chain' ||
        normalized == 'drivechain' ||
        normalized.contains('rantai') ||
        normalized.contains('chain')) {
      // Motorcycle drive chain link silhouette
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.18, h * 0.32, w * 0.64, h * 0.36),
          Radius.circular(w * 0.18),
        ),
      );
    } else if (normalized == 'clutch_plate' ||
        normalized == 'clutchplate' ||
        normalized.contains('kopling') ||
        normalized.contains('clutch')) {
      // Clutch plate friction disc silhouette
      path.addOval(Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.64, h * 0.64));
    } else if (normalized == 'sprocket' ||
        normalized.contains('gir') ||
        normalized.contains('sprocket')) {
      // Gear / sprocket silhouette
      path.addOval(Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.64, h * 0.64));
    } else if (normalized.contains('wiper')) {
      // Windshield wiper silhouette
      path.moveTo(w * 0.20, h * 0.80);
      path.lineTo(w * 0.75, h * 0.25);
      path.lineTo(w * 0.82, h * 0.32);
      path.lineTo(w * 0.27, h * 0.87);
      path.close();
    } else if (normalized.contains('filter_udara') ||
        normalized.contains('air_filter') ||
        normalized.contains('airfilter') ||
        normalized.contains('kabin') ||
        normalized.contains('cabin')) {
      // Air filter box
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.18, h * 0.22, w * 0.64, h * 0.60),
          Radius.circular(w * 0.08),
        ),
      );
    } else if (normalized.contains('coolant') ||
        normalized.contains('radiator')) {
      // Radiator coolant flask / reservoir
      path.moveTo(w * 0.40, h * 0.14);
      path.lineTo(w * 0.60, h * 0.14);
      path.lineTo(w * 0.60, h * 0.28);
      path.lineTo(w * 0.78, h * 0.42);
      path.lineTo(w * 0.78, h * 0.90);
      path.cubicTo(w * 0.78, h * 0.96, w * 0.74, h * 0.96, w * 0.70, h * 0.96);
      path.lineTo(w * 0.30, h * 0.96);
      path.cubicTo(w * 0.26, h * 0.96, w * 0.22, h * 0.96, w * 0.22, h * 0.90);
      path.lineTo(w * 0.22, h * 0.42);
      path.lineTo(w * 0.40, h * 0.28);
      path.close();
    } else if (normalized.contains('filter') &&
        (normalized.contains('oli') ||
            normalized.contains('oil') ||
            normalized.contains('fuel') ||
            normalized.contains('solar') ||
            normalized.contains('bensin'))) {
      // Canister filter (Oil/Fuel filter)
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.24, h * 0.20, w * 0.52, h * 0.64),
          Radius.circular(w * 0.08),
        ),
      );
    } else if (normalized == 'engine_oil' ||
        normalized == 'engineoil' ||
        normalized.contains('oli') ||
        normalized.contains('oil')) {
      // Minimalist automotive oil can / canister
      path.moveTo(w * 0.35, h * 0.15);
      path.lineTo(w * 0.65, h * 0.15); // spout top
      path.lineTo(w * 0.65, h * 0.25);
      path.lineTo(w * 0.78, h * 0.32); // right shoulder
      path.lineTo(w * 0.78, h * 0.88); // right body
      path.cubicTo(w * 0.78, h * 0.94, w * 0.74, h * 0.96, w * 0.68, h * 0.96);
      path.lineTo(w * 0.32, h * 0.96); // bottom
      path.cubicTo(w * 0.26, h * 0.96, w * 0.22, h * 0.94, w * 0.22, h * 0.88);
      path.lineTo(w * 0.22, h * 0.32); // left body
      path.lineTo(w * 0.35, h * 0.25);
      path.close();
      // Handle loop
      path.moveTo(w * 0.78, h * 0.40);
      path.cubicTo(w * 0.92, h * 0.40, w * 0.92, h * 0.70, w * 0.78, h * 0.70);
      path.close();
    } else {
      // Default clean automotive hexagon / shield
      path.moveTo(w * 0.50, h * 0.14);
      path.lineTo(w * 0.80, h * 0.30);
      path.lineTo(w * 0.80, h * 0.70);
      path.lineTo(w * 0.50, h * 0.92);
      path.lineTo(w * 0.20, h * 0.70);
      path.lineTo(w * 0.20, h * 0.30);
      path.close();
    }

    return path;
  }
}

