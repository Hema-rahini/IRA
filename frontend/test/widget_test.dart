import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ira/main.dart';

void main() {
  testWidgets('App launch smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);

    // Fast-forward past the splash screen timer to settle
    await tester.pump(const Duration(seconds: 5));
  });
}
