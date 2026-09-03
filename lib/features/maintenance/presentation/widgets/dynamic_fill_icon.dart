import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'component_path_registry.dart';

/// Signature Feature: Dynamic Fill Icon System (DSS Section 8.2 & PRD Section 8)
class DynamicFillIcon extends StatefulWidget {
  final String componentType;
  final double percentage; // 0.0 to 1.0
  final double size;

  const DynamicFillIcon({
    super.key,
    required this.componentType,
    required this.percentage,
    this.size = 44.0,
  });

  @override
  State<DynamicFillIcon> createState() => _DynamicFillIconState();
}

class _DynamicFillIconState extends State<DynamicFillIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _lastPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _lastPercentage = widget.percentage.clamp(0.0, 1.0);
    _animation = Tween<double>(begin: 0.0, end: _lastPercentage).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant DynamicFillIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.percentage.clamp(0.0, 1.0);
    if (oldWidget.percentage != widget.percentage) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: target,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ),
      );
      _controller.reset();
      _controller.forward();
      _lastPercentage = target;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clampedPct = widget.percentage.clamp(0.0, 1.0);
    final semanticLabel =
        'Status ${widget.componentType}: ${(clampedPct * 100).toInt()} persen, ${AppColors.getHealthStatusLabel(clampedPct)}';

    return Semantics(
      label: semanticLabel,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final animatedVal = _animation.value;
          final color = _resolveInterpolatedColor(animatedVal);

          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _DynamicFillPainter(
                componentType: widget.componentType,
                progress: animatedVal,
                fillColor: color,
                isDepleted: clampedPct <= 0.05,
              ),
            ),
          );
        },
      ),
    );
  }

  Color _resolveInterpolatedColor(double value) {
    if (value >= 0.80) {
      return AppColors.healthOptimal;
    } else if (value >= 0.50) {
      final t = (value - 0.50) / 0.30;
      return Color.lerp(AppColors.healthModerate, AppColors.healthOptimal, t)!;
    } else if (value >= 0.20) {
      final t = (value - 0.20) / 0.30;
      return Color.lerp(AppColors.healthWarning, AppColors.healthModerate, t)!;
    } else {
      final t = (value / 0.20).clamp(0.0, 1.0);
      return Color.lerp(AppColors.healthCritical, AppColors.healthWarning, t)!;
    }
  }
}

class _DynamicFillPainter extends CustomPainter {
  final String componentType;
  final double progress; // 0.0 to 1.0
  final Color fillColor;
  final bool isDepleted;

  _DynamicFillPainter({
    required this.componentType,
    required this.progress,
    required this.fillColor,
    required this.isDepleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = ComponentPathRegistry.getPath(componentType, size);

    // 1. Draw subtle background surface of the component container
    final bgPaint = Paint()
      ..color = AppColors.surfaceSubtle
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);

    // 2. Vertical clipping for dynamic fill (from bottom to top)
    if (progress > 0.001) {
      canvas.save();
      final fillTop = size.height * (1.0 - progress.clamp(0.0, 1.0));
      final clipRect = Rect.fromLTRB(0.0, fillTop, size.width, size.height);
      canvas.clipRect(clipRect);

      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
      canvas.restore();
    }

    // 3. Monoline outline (1.5px)
    final outlinePaint = Paint()
      ..color = isDepleted ? AppColors.healthCritical : AppColors.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDepleted ? 2.0 : 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, outlinePaint);

    // 4. If depleted (0%), draw solid red 2px baseline (DSS Table 7)
    if (isDepleted) {
      final basePaint = Paint()
        ..color = AppColors.healthCritical
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(size.width * 0.2, size.height * 0.96),
        Offset(size.width * 0.8, size.height * 0.96),
        basePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicFillPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.isDepleted != isDepleted ||
        oldDelegate.componentType != componentType;
  }
}
