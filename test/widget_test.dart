// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unimove/main.dart';

void main() {
  testWidgets('Shows UniMove splash before the main app shell', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    expect(find.byKey(const Key('unimove-splash-logo')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    expect(find.text('UniMove'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
