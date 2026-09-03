import 'package:flutter/material.dart';

/// Registry generating clean, normalized (0.0 to 1.0) automotive vector paths for each component type
class ComponentPathRegistry {
  ComponentPathRegistry._();

  /// Gets the normalized path (in [0,0] to [1,1] space) scaled to [size]
  static Path getPath(String componentType, Size size) {
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;

    switch (componentType.toLowerCase()) {
      case 'engine_oil':
      case 'engineoil':
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
        break;

      case 'gear_oil':
      case 'gearoil':
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
        break;

      case 'brake_pad':
      case 'brakepad':
        // Automotive brake caliper & pad outline
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.20, h * 0.25, w * 0.60, h * 0.55),
            Radius.circular(w * 0.12),
          ),
        );
        // Caliper pin/mount ears
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
        break;

      case 'tires':
      case 'tire_tread':
      case 'tiretread':
        // Wheel tire outer profile with inner rim cutout
        path.addOval(Rect.fromLTWH(w * 0.16, h * 0.16, w * 0.68, h * 0.68));
        break;

      case 'battery':
        // Battery block with positive & negative terminal posts
        // Negative post (left)
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.28, h * 0.18, w * 0.14, h * 0.10),
            Radius.circular(w * 0.02),
          ),
        );
        // Positive post (right)
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.58, h * 0.18, w * 0.14, h * 0.10),
            Radius.circular(w * 0.02),
          ),
        );
        // Main battery casing
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.18, h * 0.26, w * 0.64, h * 0.62),
            Radius.circular(w * 0.08),
          ),
        );
        break;

      case 'spark_plug':
      case 'sparkplug':
        // Spark plug insulator, thread and electrode
        // Terminal nut
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.42, h * 0.12, w * 0.16, h * 0.10),
            Radius.circular(w * 0.02),
          ),
        );
        // Ceramic insulator
        path.moveTo(w * 0.36, h * 0.22);
        path.lineTo(w * 0.64, h * 0.22);
        path.lineTo(w * 0.60, h * 0.48);
        path.lineTo(w * 0.40, h * 0.48);
        path.close();
        // Hex body & threaded portion
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.30, h * 0.48, w * 0.40, h * 0.36),
            Radius.circular(w * 0.04),
          ),
        );
        // Ground electrode
        path.moveTo(w * 0.45, h * 0.84);
        path.lineTo(w * 0.45, h * 0.94);
        path.lineTo(w * 0.55, h * 0.94);
        path.lineTo(w * 0.55, h * 0.88);
        break;

      case 'cvt_belt':
      case 'cvtbelt':
        // Dual pulley with belt drive outline
        path.addOval(Rect.fromLTWH(w * 0.18, h * 0.32, w * 0.30, h * 0.36));
        path.addOval(Rect.fromLTWH(w * 0.52, h * 0.32, w * 0.30, h * 0.36));
        path.moveTo(w * 0.33, h * 0.32);
        path.lineTo(w * 0.67, h * 0.32);
        path.lineTo(w * 0.67, h * 0.68);
        path.lineTo(w * 0.33, h * 0.68);
        path.close();
        break;

      case 'air_filter':
      case 'airfilter':
        // Air filter box
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.18, h * 0.22, w * 0.64, h * 0.60),
            Radius.circular(w * 0.08),
          ),
        );
        break;

      case 'engine_coolant':
      case 'enginecoolant':
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
        break;

      default:
        // Default clean automotive hexagon / shield
        path.moveTo(w * 0.50, h * 0.14);
        path.lineTo(w * 0.80, h * 0.30);
        path.lineTo(w * 0.80, h * 0.70);
        path.lineTo(w * 0.50, h * 0.92);
        path.lineTo(w * 0.20, h * 0.70);
        path.lineTo(w * 0.20, h * 0.30);
        path.close();
        break;
    }

    return path;
  }
}
