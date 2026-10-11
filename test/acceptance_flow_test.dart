import 'package:access_map/app/access_map_app.dart';
import 'package:access_map/app/app_state.dart';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/models/travel_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the app, flushing the 300ms mock repository delay so no
/// timers are left pending at the end of a test.
Future<void> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(const AccessPathAiApp());
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Completes onboarding (PA Assisted + Can't See) and returns to the map.
Future<AppState> completeOnboarding(WidgetTester tester) async {
  await pumpApp(tester);

  await tester.tap(find.text('PA Assisted'));
  await tester.pump();
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  await tester.tap(find.text("Can't See"));
  await tester.pump();
  await tester.ensureVisible(find.text('Open Map'));
  await tester.pump();
  await tester.tap(find.text('Open Map'));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 400));

  return tester.element(find.byType(MaterialApp)).read<AppState>();
}

const _detailsList = ValueKey('place-details-list');
const _reviewList = ValueKey('write-review-list');
const _needsScroll = ValueKey('need-selection-scroll');

/// Drags the need-selection scroll view until [finder] finds a widget.
Future<void> scrollUntilVisibleNeeds(
  WidgetTester tester,
  Finder finder,
) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byKey(_needsScroll), const Offset(0, -250));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// Drags the keyed list until [finder] finds at least one widget.
/// Tolerates multiple matches (unlike dragUntilVisible's .single check).
Future<void> scrollUntilVisible(
  WidgetTester tester,
  Finder finder,
  Key listKey,
) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byKey(listKey), const Offset(0, -250));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('cannot proceed to needs without selecting a mode', (tester) async {
    await pumpApp(tester);

    final continueBtn = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Continue'),
        matching: find.bySubtype<ElevatedButton>(),
      ),
    );
    expect(continueBtn.onPressed, isNull);
  });

  testWidgets('need selection shows every accessibility option with description', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('PA Assisted'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Every option from the profile page must appear on onboarding.
    for (final need in AccessibilityNeed.values) {
      await scrollUntilVisibleNeeds(tester, find.text(need.displayName));
      expect(find.text(need.displayName), findsOneWidget);
      expect(find.text(need.description), findsOneWidget);
    }
  });

  testWidgets('cannot open map without selecting a need', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('PA Assisted'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final openMap = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Open Map'),
        matching: find.bySubtype<ElevatedButton>(),
      ),
    );
    expect(openMap.onPressed, isNull);
  });

  testWidgets('mode and need persist into profile after onboarding', (tester) async {
    final state = await completeOnboarding(tester);

    expect(state.profile.onboardingComplete, isTrue);
    expect(state.profile.travelMode, TravelMode.paAssisted);
    expect(state.profile.accessibilityNeeds, isNotEmpty);
  });

  testWidgets('map shell shows places, search and tabs after onboarding', (tester) async {
    await completeOnboarding(tester);

    expect(find.text('Search accessible places...'), findsOneWidget);
    expect(find.text('Map'), findsWidgets);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Contribute'), findsOneWidget);
    expect(find.text('Profile'), findsWidgets);
    // Demo place data is visible.
    expect(find.text('Fishka Restaurant'), findsWidgets);
  });

  testWidgets('wheelchair score hidden for visual profile, shown after profile change', (tester) async {
    await completeOnboarding(tester);

    // Open the first place details.
    await tester.tap(find.text('Fishka Restaurant').first);
    await tester.pumpAndSettle();

    expect(find.text('Friendly Score'), findsOneWidget);
    expect(find.text('Wheelchair-Friendly'), findsNothing);

    // Go back to the shell, open Profile via the nav bar, add a
    // wheelchair need.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await scrollUntilVisible(
      tester,
      find.text('Demo Wheelchair Profile'),
      const ValueKey('profile-list'),
    );
    await tester.tap(find.text('Demo Wheelchair Profile'));
    await tester.pumpAndSettle();

    final state = tester.element(find.byType(MaterialApp)).read<AppState>();
    expect(state.profile.shouldShowWheelchairScore, isTrue);
  });

  testWidgets('search finds a place and opens its details', (tester) async {
    await completeOnboarding(tester);

    await tester.enterText(find.byType(TextField).first, 'fishka');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fishka Restaurant').first);
    await tester.pumpAndSettle();

    expect(find.text('Friendly Score'), findsOneWidget);
    expect(find.text('Accessibility overview'), findsOneWidget);
    expect(find.byIcon(Icons.directions), findsOneWidget);
    await scrollUntilVisible(tester, find.text('Accessibility features'), _detailsList);
    expect(find.text('Accessibility features'), findsOneWidget);
    await scrollUntilVisible(tester, find.text('Reviews'), _detailsList);
    expect(find.text('Reviews'), findsOneWidget);
  });

  testWidgets('review submission awards +5 community points', (tester) async {
    final state = await completeOnboarding(tester);
    final pointsBefore = state.profile.communityPoints;

    // Open place details and start a review.
    await tester.tap(find.text('Fishka Restaurant').first);
    await tester.pumpAndSettle();
    await scrollUntilVisible(tester, find.text('Write'), _detailsList);
    await tester.tap(find.text('Write'));
    await tester.pumpAndSettle();

    // The comment field sits below the rating sliders, so scroll to it.
    await scrollUntilVisible(tester, find.byType(TextField), _reviewList);
    await tester.enterText(
      find.byType(TextField),
      'Staff guided me patiently and the entrance was step-free throughout.',
    );
    await tester.pump();
    await scrollUntilVisible(tester, find.text('Submit Review'), _reviewList);
    await tester.tap(find.text('Submit Review'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    final stateAfter =
        tester.element(find.byType(MaterialApp)).read<AppState>();
    expect(stateAfter.profile.communityPoints, pointsBefore + 5);
    expect(stateAfter.profile.reviewCount, greaterThan(0));
    expect(stateAfter.profile.recentActivity.first.type.displayName, 'Review');
  });

  testWidgets('helpful vote works from details', (tester) async {
    await completeOnboarding(tester);

    await tester.tap(find.text('Fishka Restaurant').first);
    await tester.pumpAndSettle();
    await scrollUntilVisible(tester, find.textContaining('Helpful'), _detailsList);

    final votesBefore = tester
        .element(find.byType(MaterialApp))
        .read<AppState>()
        .places
        .first
        .reviews
        .first
        .helpfulVotes;

    await tester.tap(find.textContaining('Helpful').first);
    await tester.pumpAndSettle();

    final state = tester.element(find.byType(MaterialApp)).read<AppState>();
    expect(
      state.places.first.reviews.first.helpfulVotes,
      votesBefore + 1,
    );
  });

  testWidgets('feature confirmation awards +3 points', (tester) async {
    final state = await completeOnboarding(tester);

    await tester.tap(find.text('Fishka Restaurant').first);
    await tester.pumpAndSettle();

    final pointsBefore = state.profile.communityPoints;
    await scrollUntilVisible(tester, find.text('Confirm'), _detailsList);
    await tester.tap(find.text('Confirm').first);
    await tester.pumpAndSettle();

    final stateAfter =
        tester.element(find.byType(MaterialApp)).read<AppState>();
    expect(stateAfter.profile.communityPoints, pointsBefore + 3);
    expect(
      stateAfter.profile.recentActivity.first.description,
      contains('Confirmed'),
    );
  });
}
