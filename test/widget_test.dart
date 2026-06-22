// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:unimove/main.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://hkyipemvlhqmyhnawkix.supabase.co',
      publishableKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhreWlwZW12bGhxbXlobmF3a2l4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE3NzMwMDQsImV4cCI6MjA5NzM0OTAwNH0.YiV8l8M2n-gnJMdTLCgKMCMlj2QVy0mIVUDBceNURM0',
    );
  });

  testWidgets('Shows UniMove splash before login', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    expect(find.byKey(const Key('unimove-splash-logo')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('Create an Account'), findsOneWidget);
  });
}
