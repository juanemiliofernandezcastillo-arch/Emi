// Basic smoke test for IronPulse app.
import 'package:flutter_test/flutter_test.dart';
import 'package:iron_pulse_flutter/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const IronPulseApp());
    expect(find.byType(IronPulseApp), findsOneWidget);
  });
}
