import 'package:access_map/app/access_map_app.dart';
import 'package:access_map/app/app_state.dart';
import 'package:access_map/features/contribute/presentation/add_location_screen.dart';
import 'package:access_map/features/map/presentation/map_screen.dart';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end tests for the community location submission flow (spec #70).

const _accessibilityList = ValueKey('accessibility-list');
const _reviewList = ValueKey('review-list');

/// Deterministic stand-in for pumpAndSettle: the wizard and map embed
/// FlutterMap, whose tile layer retries failed (offline) requests forever,
/// so pumpAndSettle would never return.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Awaits [future] while pumping so its internal fake-async timers fire —
/// awaiting directly would deadlock inside the test zone.
Future<T> pumpUntilComplete<T>(WidgetTester tester, Future<T> future) async {
  var done = false;
  future.then((_) => done = true, onError: (_) => done = true);
  for (var i = 0; i < 30 && !done; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  return future;
}

/// Drags the keyed list until [finder] finds at least one widget.
Future<void> scrollUntilVisible(
  WidgetTester tester,
  Finder finder,
  Key listKey,
) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byKey(listKey), const Offset(0, -250));
    await tester.pump();
  }
  await settle(tester);
}

void main() {
  /// Onboard as PA Assisted + Can't See and land on the map.
  Future<AppState> onboard(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AccessPathAiApp());
    await settle(tester);
    await tester.tap(find.text('PA Assisted'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await settle(tester);
    await tester.tap(find.text("Can't See"));
    await tester.pump();
    await tester.ensureVisible(find.text('Open Map'));
    await tester.pump();
    await tester.tap(find.text('Open Map'));
    // Bounded pumps: the map's tile layer retries failed (offline) requests
    // forever, so pumpAndSettle would never return here.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));
    return tester.element(find.byType(MaterialApp)).read<AppState>();
  }

  /// Enter the Add Location wizard from the Contribute tab.
  Future<void> openWizard(WidgetTester tester) async {
    // Nav-bar icons are unique even though the IndexedStack keeps every
    // tab's AppBar title alive (find.text('Contribute') would match twice).
    await tester.tap(find.byIcon(Icons.volunteer_activism_outlined));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('add-location-card')));
    await settle(tester);
  }

  /// Pick the default map-picker center (Caculo Mall area) as the location.
  /// Returns true when the "add new anyway" duplicate dialog appeared.
  Future<bool> confirmMapLocation(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('confirm-map-location-button')));
    await settle(tester);
    // Reverse geocoding resolves instantly in tests (coordinate fallback).
    await tester.pump(const Duration(milliseconds: 100));
    await tester
        .tap(find.byKey(const ValueKey('confirm-chosen-location-button')));
    await settle(tester);
    final addNew = find.text('No, Add New Location');
    if (addNew.evaluate().isNotEmpty) {
      await tester.tap(addNew.last);
      await settle(tester);
      return true;
    }
    return false;
  }

  Future<void> useBigViewport(WidgetTester tester) async {
    // Tall viewport so the wizard's lazy ListViews build every item —
    // no scroll loops needed for taps or assertions.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = FakeViewPadding.zero;
    addTearDown(tester.view.reset);
  }

  testWidgets(
      'full flow: contribute > add location > submit > on map, searchable, points awarded',
      (tester) async {
    await useBigViewport(tester);
    final state = await onboard(tester);
    final pointsBefore = state.profile.communityPoints;
    final locationsBefore = state.profile.locationCount;
    final placeCountBefore = state.places.length;

    // -- Open the Contribute tab and start the flow --------------------------
    await openWizard(tester);

    // -- Step 1: choose location via map picker ------------------------------
    // Default picker center is Caculo Mall → duplicate dialog appears;
    // continue as a genuinely new location.
    await confirmMapLocation(tester);

    // -- Step 2: basic info --------------------------------------------------
    expect(find.byType(AddLocationScreen), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('place-name-field')), 'Community Test Cafe');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('category-dropdown')));
    await settle(tester);
    await tester.tap(find.text('Cafe').last);
    await settle(tester);

    // Validation guard: an empty name is rejected.
    await tester.enterText(find.byKey(const ValueKey('place-name-field')), '');
    await tester.pump();
    await tester.tap(find.text('Next: Accessibility'));
    await tester.pump();
    expect(find.text('Place name is required.'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('place-name-field')), 'Community Test Cafe');
    await tester.pump();

    await tester.tap(find.text('Next: Accessibility'));
    await settle(tester);

    // -- Step 3: accessibility (tri-state) -----------------------------------
    // Feature toggles sit near the top of a long lazy ListView.
    await tester.tap(find.byKey(const ValueKey('feature-ramp-available')));
    await tester.pump();
    await tester
        .tap(find.byKey(const ValueKey('feature-elevator-unavailable')));
    await tester.pump();

    // 'Next: Photos' sits below the ListView's build extent — drag to it.
    await scrollUntilVisible(
      tester,
      find.text('Next: Photos'),
      _accessibilityList,
    );
    await tester.tap(find.text('Next: Photos'));
    await settle(tester);

    // -- Step 4: photos (optional; skip adding) ------------------------------
    await tester.tap(find.text('Next: Review'));
    await settle(tester);

    // -- Step 5: review & submit ---------------------------------------------
    expect(find.text('Community Test Cafe'), findsWidgets);
    await scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('submit-location-button')),
      _reviewList,
    );
    await tester.tap(find.byKey(const ValueKey('submit-location-button')));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 400));

    // -- Success screen ('Location Added!' appears in AppBar AND body) --------
    expect(find.text('Location Added!'), findsWidgets);
    expect(find.text('+10 Community Points'), findsOneWidget);

    // -- Points awarded (#43) --------------------------------------------------
    expect(state.profile.communityPoints, pointsBefore + 10);
    expect(state.profile.locationCount, locationsBefore + 1);

    // -- View Location opens details with the submitted info -------------------
    await tester.tap(find.byKey(const ValueKey('view-location-button')));
    await settle(tester);
    expect(find.textContaining('Added by the community'), findsOneWidget);
    // Name appears in the AppBar title and the details hero panel.
    expect(find.text('Community Test Cafe'), findsWidgets);
    // Provisional scores, not fake numbers (#40).
    expect(find.text('Friendly Score - New'), findsOneWidget);
    // Feature the contributor marked as available is shown.
    expect(find.text('Ramp'), findsWidgets);
    await tester.pageBack();
    await settle(tester);

    // -- Switch to Map via the nav bar and search (#28, #54) -------------------
      // Set the tab through app state because the extra-tall test viewport can
      // place NavigationBar destination render boxes outside the hit-test area.
      state.changeTab(0);
    await tester.pump(const Duration(milliseconds: 600));
    final mapSearch = find
        .descendant(
          of: find.byType(MapScreen),
          matching: find.byType(TextField),
        )
        .first;
    await tester.enterText(mapSearch, 'Community Test');
    await tester.pump();
    // Flush the repository's 200ms mock delay and search debounce.
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Community Test Cafe'), findsWidgets);

    // The UI search drove the repository: results are community-sourced.
    // (Awaiting searchPlaces() directly would deadlock on its fake-async
    // Future.delayed timer.)
    expect(state.visiblePlaces, isNotEmpty);
    expect(state.visiblePlaces.every((p) => p.name.contains('Community Test')),
        isTrue);
    expect(state.visiblePlaces.first.source, PlaceSource.community);

    // -- Existing dummy places intact (#70 Test 4) ------------------------------
    expect(state.places.length, placeCountBefore + 1);
    expect(state.places.any((p) => p.name == 'Fishka Restaurant'), isTrue);
    expect(state.places.where((p) => p.source == PlaceSource.demo).length,
        placeCountBefore);
  });

  testWidgets('duplicate detection offers update vs new', (tester) async {
    await useBigViewport(tester);
    await onboard(tester);

    await openWizard(tester);

    // The picker defaults to Caculo Mall's exact coordinates → confirming
    // triggers the near-duplicate dialog.
    await tester.tap(find.byKey(const ValueKey('confirm-map-location-button')));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await tester
        .tap(find.byKey(const ValueKey('confirm-chosen-location-button')));
    await settle(tester);

    expect(find.text('A place already exists nearby'), findsOneWidget);
    expect(find.textContaining('Caculo Mall'), findsOneWidget);
    expect(find.text('Yes, Update Existing Place'), findsOneWidget);
    expect(find.text('No, Add New Location'), findsOneWidget);

    // Choose "update" → routes to the existing place's details.
    await tester.tap(find.text('Yes, Update Existing Place'));
    await settle(tester);
    expect(find.text('Caculo Mall'), findsWidgets);
  });

  testWidgets('community place survives app restart (persistence)',
      (tester) async {
    await useBigViewport(tester);
    final state = await onboard(tester);
    final before = state.places.length;

    // Start without awaiting: addLocation's repository delay is a fake-async
    // timer that only fires while pumps run — awaiting directly would deadlock.
    final added = state.addLocation(
      Place(
        id: 'community-restart-test',
        name: 'Persistence Cafe',
        category: state.places.first.category,
        address: 'Somewhere, Goa',
        description: 'Added by test',
        latitude: 15.3333,
        longitude: 74.0833,
        friendlyScore: 0,
        wheelchairScore: 0,
        visualAccessibilityScore: 0,
        hearingAccessibilityScore: 0,
        communicationScore: 0,
        accessibilityFeatures: const [],
        reviews: const [],
        source: PlaceSource.community,
        createdBy: 'demo-user',
        createdAt: DateTime.now(),
      ),
    );
    await pumpUntilComplete(tester, added);
    expect(state.places.length, before + 1);

    // Simulate a restart: fresh AppState over the same (mocked) storage.
    final freshState = AppState()..loadPlaces();
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
    expect(freshState.places.length, before + 1);
    expect(freshState.places.any((p) => p.id == 'community-restart-test'),
        isTrue);
    // Demo places remain.
    expect(freshState.places.any((p) => p.name == 'Fishka Restaurant'), isTrue);
  });

  testWidgets('wheelchair score gating still enforced for community places',
      (tester) async {
    await useBigViewport(tester);
    final state = await onboard(tester);

    // Start without awaiting (fake-async repository delay — see above).
    final added = state.addLocation(
      Place(
        id: 'community-gating-test',
        name: 'Gating Check Center',
        category: state.places.first.category,
        address: 'Somewhere, Goa',
        description: 'Added by test',
        latitude: 15.2222,
        longitude: 74.0555,
        friendlyScore: 0,
        wheelchairScore: 0,
        visualAccessibilityScore: 0,
        hearingAccessibilityScore: 0,
        communicationScore: 0,
        accessibilityFeatures: const [],
        reviews: const [],
        source: PlaceSource.community,
        createdBy: 'demo-user',
        createdAt: DateTime.now(),
      ),
    );
    await pumpUntilComplete(tester, added);

    // Open the place: switch to Map, where the selected place's preview
    // sheet shows, then tap it to push the details screen.
    await tester.tap(find.byIcon(Icons.map_outlined));
    await settle(tester);
    expect(find.text('Gating Check Center'), findsWidgets);
    await tester.tap(find.text('Gating Check Center').first);
    await settle(tester);

    // Can't See profile: provisional panel content is honest — the
    // wheelchair line is withheld (#41 gating).
    expect(find.text('Friendly Score - New'), findsOneWidget);
    expect(find.text('Wheelchair-Friendly - awaiting community ratings'),
        findsNothing);

    // Switch profile to wheelchair user → wheelchair line appears (#41).
    state.updateDemoProfile(needs: [AccessibilityNeed.wheelchairUser]);
    await settle(tester);
    expect(find.text('Wheelchair-Friendly - awaiting community ratings'),
        findsOneWidget);
  });
}
