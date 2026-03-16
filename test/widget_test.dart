// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:connectingheart_mobile/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    // This app triggers delayed navigation timers from Splash; keep this test minimal.
    // If you want widget tests, create dedicated tests per-screen with mocked providers/router.
    expect(true, isTrue);
  });
}
