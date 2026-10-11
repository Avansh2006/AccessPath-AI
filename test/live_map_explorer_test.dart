import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/features/map/domain/live_map_explorer.dart';
import 'package:access_map/features/map/domain/place_repository.dart';
import 'package:access_map/features/map/presentation/live_map_widgets.dart';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/models/accessibility_rating.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_category.dart';
import 'package:access_map/shared/models/place_review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _centerLat = 15.4909;
const _centerLng = 73.8278;

Place _place({
  String id = 'p',
  PlaceCategory category = PlaceCategory.restaurant,
  double latitude = _centerLat,
  double longitude = _centerLng,
  List<Map<AccessibilityCriterion, AccessibilityRating>> ratings = const [],
}) {
  return Place(
    id: id,
    name: 'Place $id',
    category: category,
    address: '',
    description: '',
    latitude: latitude,
    longitude: longitude,
    friendlyScore: 0,
    wheelchairScore: 0,
    visualAccessibilityScore: 0,
    hearingAccessibilityScore: 0,
    communicationScore: 0,
    accessibilityFeatures: const [],
    reviews: [
      for (var i = 0; i < ratings.length; i++)
        PlaceReview(
          id: '$id-r$i',
          placeId: id,
          userId: 'u$i',
          userName: 'Reviewer $i',
          overallRating: 0,
          comment: 'Review number $i',
          createdAt: DateTime(2026, 1, i + 1),
          reviewerContext: const AccessibilityContext(),
          accessibilityRatings: ratings[i],
        ),
    ],
  );
}

Map<AccessibilityCriterion, AccessibilityRating> _all(double value) => {
  for (final c in AccessibilityCriterion.values)
    c: AccessibilityRating.rated(value),
};

const _evaluator = SuitabilityEvaluator();
final _allCriteria = AccessibilityCriterion.values.toSet();

void main() {
  group('SuitabilityEvaluator', () {
    test('unrated place is unknown with no evidence, never a score', () {
      final result = _evaluator.evaluate(_place(), _allCriteria);
      expect(result.suitability, Suitability.unknown);
      expect(result.confidence, SuitabilityConfidence.none);
      expect(result.score, isNull);
    });

    test('reviews with only unknown ratings stay unknown', () {
      final result = _evaluator.evaluate(
        _place(
          ratings: [
            {
              for (final c in AccessibilityCriterion.values)
                c: const AccessibilityRating.unknown(),
            },
          ],
        ),
        _allCriteria,
      );
      expect(result.suitability, Suitability.unknown);
    });

    test('well rated by three reviewers is a high-confidence good fit', () {
      final result = _evaluator.evaluate(
        _place(ratings: [_all(5), _all(4.5), _all(4)]),
        _allCriteria,
      );
      expect(result.suitability, Suitability.good);
      expect(result.confidence, SuitabilityConfidence.high);
      expect(result.score, closeTo(90, 0.01));
    });

    test('low ratings are a poor fit', () {
      final result = _evaluator.evaluate(
        _place(ratings: [_all(1), _all(2)]),
        _allCriteria,
      );
      expect(result.suitability, Suitability.poor);
    });

    test('mid ratings are a partial fit', () {
      final result = _evaluator.evaluate(
        _place(ratings: [_all(3)]),
        _allCriteria,
      );
      expect(result.suitability, Suitability.partial);
      expect(result.score, closeTo(60, 0.01));
    });

    test('single review gives low confidence', () {
      final result = _evaluator.evaluate(
        _place(ratings: [_all(5)]),
        _allCriteria,
      );
      expect(result.suitability, Suitability.good);
      expect(result.confidence, SuitabilityConfidence.low);
    });

    test('a relevant criterion rated inaccessible caps good at partial', () {
      final ratings = {
        ..._all(5),
        AccessibilityCriterion.stepFreeAccess: AccessibilityRating.rated(2),
      };
      final result = _evaluator.evaluate(
        _place(ratings: [ratings, ratings, ratings]),
        _allCriteria,
      );
      // Weighted average is 82 but step-free access is unavailable.
      expect(result.score, greaterThan(SuitabilityEvaluator.goodThreshold));
      expect(result.suitability, Suitability.partial);
    });

    test('suitability is personalised to the user\'s needs', () {
      // Great wayfinding and step-free entry, but no lifts or washrooms.
      final ratings = {
        AccessibilityCriterion.wayfinding: AccessibilityRating.rated(5),
        AccessibilityCriterion.stepFreeAccess: AccessibilityRating.rated(5),
        AccessibilityCriterion.lifts: AccessibilityRating.rated(0),
        AccessibilityCriterion.accessibleWashrooms: AccessibilityRating.rated(
          0,
        ),
        AccessibilityCriterion.seating: AccessibilityRating.rated(1),
      };
      final place = _place(ratings: [ratings, ratings]);

      final visual = _evaluator.relevantCriteria([AccessibilityNeed.cannotSee]);
      final wheelchair = _evaluator.relevantCriteria([
        AccessibilityNeed.wheelchairUser,
      ]);

      expect(_evaluator.evaluate(place, visual).suitability, Suitability.good);
      expect(
        _evaluator.evaluate(place, wheelchair).suitability,
        Suitability.poor,
      );
    });

    test('partial coverage of relevant needs lowers confidence', () {
      final ratings = {
        AccessibilityCriterion.stepFreeAccess: AccessibilityRating.rated(5),
      };
      final wheelchair = _evaluator.relevantCriteria([
        AccessibilityNeed.wheelchairUser,
      ]);
      final result = _evaluator.evaluate(
        _place(ratings: [ratings, ratings, ratings]),
        wheelchair,
      );
      expect(result.ratedCriteria, 1);
      expect(result.relevantCriteria, 4);
      expect(result.confidence, SuitabilityConfidence.low);
    });

    test('not-applicable criteria are ignored rather than penalised', () {
      final ratings = {
        ..._all(5),
        AccessibilityCriterion.lifts: const AccessibilityRating.notApplicable(),
      };
      final result = _evaluator.evaluate(
        _place(ratings: [ratings, ratings, ratings]),
        _allCriteria,
      );
      expect(result.relevantCriteria, 4);
      expect(result.confidence, SuitabilityConfidence.high);
      expect(result.suitability, Suitability.good);
    });

    test('no specific needs falls back to all five criteria', () {
      expect(_evaluator.relevantCriteria(const []), _allCriteria);
      expect(
        _evaluator.relevantCriteria(
          const [],
          essentials: const [AccessibilityCriterion.lifts],
        ),
        {AccessibilityCriterion.lifts},
      );
    });
  });

  group('ExplorerCategory', () {
    test('groups place categories', () {
      expect(ExplorerCategory.hospitals.matches(PlaceCategory.clinic), isTrue);
      expect(ExplorerCategory.restaurants.matches(PlaceCategory.cafe), isTrue);
      expect(
        ExplorerCategory.transport.matches(PlaceCategory.transport),
        isTrue,
      );
      expect(ExplorerCategory.malls.matches(PlaceCategory.park), isFalse);
    });

    test('every place category belongs to exactly one group', () {
      for (final category in PlaceCategory.values) {
        final groups = ExplorerCategory.values.where(
          (group) => group.matches(category),
        );
        expect(groups, hasLength(1), reason: category.name);
      }
      expect(ExplorerCategory.other.matches(PlaceCategory.college), isTrue);
    });
  });

  group('filterExplorerPlaces', () {
    // ~0.009 degrees latitude ≈ 1 km.
    final near = _place(id: 'near', latitude: _centerLat + 0.004);
    final mid = _place(
      id: 'mid',
      latitude: _centerLat + 0.015,
      category: PlaceCategory.hospital,
    );
    final far = _place(id: 'far', latitude: _centerLat + 0.04);
    final veryFar = _place(id: 'veryFar', latitude: _centerLat + 0.2);
    final places = [veryFar, far, mid, near];

    List<String> ids(ExplorerRadius radius, [ExplorerCategory? category]) =>
        filterExplorerPlaces(
          places,
          centerLatitude: _centerLat,
          centerLongitude: _centerLng,
          radius: radius,
          category: category,
        ).map((place) => place.id).toList();

    test('radius limits results and sorts nearest first', () {
      expect(ids(ExplorerRadius.oneKm), ['near']);
      expect(ids(ExplorerRadius.twoKm), ['near', 'mid']);
      expect(ids(ExplorerRadius.fiveKm), ['near', 'mid', 'far']);
    });

    test('category combines with radius', () {
      expect(
        ids(ExplorerRadius.fiveKm, ExplorerCategory.hospitals),
        ['mid'],
      );
      expect(ids(ExplorerRadius.oneKm, ExplorerCategory.hospitals), isEmpty);
      expect(ids(ExplorerRadius.fiveKm, ExplorerCategory.transport), isEmpty);
    });
  });

  group('AppState explorer', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('filters by radius/category and refreshes on live updates', () async {
      final repo = _FakeLiveRepository([
        _place(id: 'a', latitude: _centerLat + 0.004),
        _place(
          id: 'b',
          latitude: _centerLat + 0.015,
          category: PlaceCategory.park,
        ),
      ]);
      final state = AppState(placeRepository: repo);
      await state.loadPlaces();

      expect(state.liveUpdatesStatus, LiveUpdatesStatus.live);
      expect(state.explorerPlaces.map((p) => p.id), ['a', 'b']);

      state.setExplorerRadius(ExplorerRadius.oneKm);
      expect(state.explorerPlaces.map((p) => p.id), ['a']);

      state.setExplorerRadius(ExplorerRadius.fiveKm);
      state.setExplorerCategory(ExplorerCategory.parks);
      expect(state.explorerPlaces.map((p) => p.id), ['b']);

      // A backend change arrives: a park gets reviewed.
      repo.places = [
        repo.places.first,
        _place(
          id: 'b',
          latitude: _centerLat + 0.015,
          category: PlaceCategory.park,
          ratings: [_all(5), _all(5), _all(5)],
        ),
      ];
      await state.refreshFromBackend();
      expect(
        state.suitabilityFor(state.explorerPlaces.single).suitability,
        Suitability.good,
      );

      // A failed refresh keeps the last data and flags it.
      repo.fail = true;
      await state.refreshFromBackend();
      expect(state.liveRefreshFailed, isTrue);
      expect(state.explorerPlaces, hasLength(1));
      state.dispose();
      expect(repo.cancelled, isTrue);
    });
  });

  group('widgets', () {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: Center(child: child)),
      ),
    );

    testWidgets('venue card shows honest empty states for unrated places', (
      tester,
    ) async {
      final place = _place();
      await pump(
        tester,
        VenueCard(
          place: place,
          result: _evaluator.evaluate(place, _allCriteria),
          relevantCriteria: _allCriteria,
        ),
      );
      expect(find.text('Place p'), findsOneWidget);
      expect(find.text('No ratings yet'), findsOneWidget);
      expect(find.text('No accessibility ratings yet'), findsOneWidget);
      expect(find.text('No community feedback yet.'), findsOneWidget);
      expect(find.text('No community photos yet.'), findsOneWidget);
      expect(find.textContaining('Unknown'), findsNWidgets(5));
    });

    testWidgets('venue card shows scores, five categories and feedback', (
      tester,
    ) async {
      final place = _place(ratings: [_all(5), _all(4), _all(4.5)]);
      await pump(
        tester,
        VenueCard(
          place: place,
          result: _evaluator.evaluate(place, _allCriteria),
          relevantCriteria: _allCriteria,
        ),
      );
      expect(find.textContaining('Good fit · 90/100 for you'), findsOneWidget);
      expect(find.textContaining('Overall 90/100 · 3 reviews'), findsOneWidget);
      for (final criterion in AccessibilityCriterion.values) {
        expect(find.textContaining('${criterion.label}: '), findsOneWidget);
      }
      // Most recent review is shown.
      expect(find.textContaining('Review number 2'), findsOneWidget);
    });

    testWidgets('marker exposes suitability to screen readers', (
      tester,
    ) async {
      final place = _place(ratings: [_all(1)]);
      var tapped = false;
      await pump(
        tester,
        SizedBox(
          width: 46,
          height: 46,
          child: SuitabilityMarker(
            place: place,
            result: _evaluator.evaluate(place, _allCriteria),
            selected: false,
            onTap: () => tapped = true,
          ),
        ),
      );
      expect(
        find.bySemanticsLabel(
          'Place p, Restaurant, Poor fit, Low confidence',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(SuitabilityMarker));
      expect(tapped, isTrue);
    });
  });
}

class _FakeLiveRepository implements PlaceRepository, LivePlaceUpdates {
  _FakeLiveRepository(this.places);

  List<Place> places;
  bool fail = false;
  bool cancelled = false;

  @override
  Future<List<Place>> getNearbyPlaces(
    double lat,
    double lng, {
    double radiusKm = 10,
  }) async {
    if (fail) throw Exception('offline');
    return List.of(places);
  }

  @override
  Future<void> Function() subscribeToPlaceChanges({
    required void Function() onChange,
    required void Function(LiveUpdatesStatus status) onStatus,
  }) {
    onStatus(LiveUpdatesStatus.live);
    return () async => cancelled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
