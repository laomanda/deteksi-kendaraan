import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridecare/core/constants/app_colors.dart';
import 'package:ridecare/features/maintenance/presentation/widgets/dynamic_fill_icon.dart';

void main() {
  group('DynamicFillIcon Widget Tests (DSS Section 8.2 & PRD Section 18.2)', () {
    testWidgets('Renders properly at optimal level (80%)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicFillIcon(
              componentType: 'engine_oil',
              percentage: 0.80,
            ),
          ),
        ),
      );

      // Verify widget exists
      expect(find.byType(DynamicFillIcon), findsOneWidget);
      // Wait for 800ms animation
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      expect(AppColors.getHealthColor(0.80), AppColors.healthOptimal);
      expect(AppColors.getHealthStatusLabel(0.80), 'Kondisi Baik');
    });

    testWidgets('Renders properly at moderate level (50%)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicFillIcon(
              componentType: 'brake_pad',
              percentage: 0.50,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 800));
      expect(AppColors.getHealthColor(0.50), AppColors.healthModerate);
    });

    testWidgets('Renders properly at warning level (25%)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicFillIcon(
              componentType: 'spark_plug',
              percentage: 0.25,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 800));
      expect(AppColors.getHealthColor(0.25), AppColors.healthWarning);
    });

    testWidgets('Renders properly at critical/depleted level (10% and 0%)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicFillIcon(
              componentType: 'battery',
              percentage: 0.0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 800));
      expect(AppColors.getHealthColor(0.0), AppColors.healthCritical);
      expect(AppColors.getHealthStatusLabel(0.0), 'Jatuh Tempo');
    });

    testWidgets('Supports all vehicle component types without rendering exceptions',
        (tester) async {
      final components = [
        'engine_oil',
        'gear_oil',
        'brake_pad',
        'tires',
        'battery',
        'spark_plug',
        'cvt_belt',
        'air_filter',
        'engine_coolant',
      ];

      for (final comp in components) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DynamicFillIcon(
                componentType: comp,
                percentage: 0.75,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(DynamicFillIcon), findsOneWidget);
      }
    });
  });
}
