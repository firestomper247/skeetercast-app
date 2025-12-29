import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeetercast_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: const MainNavigation(),
      ),
    );

    // Verify that the navigation bar is present
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}