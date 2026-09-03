import 'package:flutter_test/flutter_test.dart';
import 'package:ridecare/main.dart';

void main() {
  testWidgets('RideCareApp initial smoke test', (WidgetTester tester) async {
    // Build RideCareApp with hasInitialVehicle = false (Onboarding flow)
    await tester.pumpWidget(
      const RideCareApp(hasInitialVehicle: false),
    );

    // Verify Onboarding / Branding is presented
    expect(find.text('RideCare'), findsOneWidget);
    expect(find.text('Kedaulatan Data 100% Offline'), findsOneWidget);
  });
}
