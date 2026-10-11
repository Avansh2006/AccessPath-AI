import 'package:access_map/app/access_map_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('onboarding requires accessibility need before map opens', (
    tester,
  ) async {
    await tester.pumpWidget(const AccessPathAiApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to AccessPath AI'), findsOneWidget);
    await tester.tap(find.text('PA Assisted'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(
      find.text('What accessibility needs should we consider?'),
      findsOneWidget,
    );
    final openMap = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Open Map'),
        matching: find.bySubtype<ElevatedButton>(),
      ),
    );
    expect(openMap.onPressed, isNull);
  });

  testWidgets('user can complete onboarding and see map shell', (tester) async {
    await tester.pumpWidget(const AccessPathAiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('PA Assisted'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Can't See"));
    await tester.pump();
    await tester.ensureVisible(find.text('Open Map'));
    await tester.pump();
    await tester.tap(find.text('Open Map'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Map'), findsWidgets);
    expect(find.text('Search accessible places...'), findsOneWidget);
  });
}
