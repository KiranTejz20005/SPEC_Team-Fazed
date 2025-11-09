import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fillora/main.dart';

void main() {
  testWidgets('App starts and shows onboarding screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FilloraApp());

    // Verify that onboarding screen is displayed
    expect(find.text('Welcome to Fillora.in'), findsOneWidget);
  });
}
