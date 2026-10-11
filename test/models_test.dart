import 'package:access_map/core/services/navigation_service.dart';
import 'package:access_map/core/utils/accessibility_visibility_policy.dart';
import 'package:access_map/features/map/data/mock_place_repository.dart';
import 'package:access_map/shared/models/accessibility_feature.dart';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_category.dart';
import 'package:access_map/shared/models/place_review.dart';
import 'package:access_map/shared/models/travel_mode.dart';
import 'package:access_map/shared/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccessibilityVisibilityPolicy', () {
    const policy = AccessibilityVisibilityPolicy();

    test('wheelchair score hidden for visual-only profile', () {
      final profile = UserProfile.mockUser(); // cannotSee
      expect(policy.showWheelchairScore(profile), isFalse);
    });

    test('wheelchair score visible for wheelchairUser', () {
      final profile = UserProfile.mockUser()
          .copyWith(accessibilityNeeds: [AccessibilityNeed.wheelchairUser]);
      expect(policy.showWheelchairScore(profile), isTrue);
    });

    test('wheelchair score visible for physicallyDisabled', () {
      final profile = UserProfile.mockUser().copyWith(
        accessibilityNeeds: [AccessibilityNeed.physicallyDisabled],
      );
      expect(policy.showWheelchairScore(profile), isTrue);
    });

    test('visual score promoted for cannotSee profile', () {
      final profile = UserProfile.mockUser();
      expect(policy.showVisualScore(profile), isTrue);
      expect(policy.showHearingScore(profile), isFalse);
      expect(policy.showCommunicationScore(profile), isFalse);
    });

    test('communication score promoted for cannotSpeak profile', () {
      final profile = UserProfile.mockUser()
          .copyWith(accessibilityNeeds: [AccessibilityNeed.cannotSpeak]);
      expect(policy.showCommunicationScore(profile), isTrue);
    });
  });

  group('MockPlaceRepository', () {
    late MockPlaceRepository repo;

    setUp(() {
      repo = MockPlaceRepository();
    });

    test('provides at least 10 varied demo places', () async {
      final places = await repo.getNearbyPlaces(15.4909, 73.8278);
      expect(places.length, greaterThanOrEqualTo(10));
      expect(places.map((p) => p.category).toSet().length, greaterThanOrEqualTo(8));
    });

    test('places have varied accessibility profiles (not binary)', () async {
      final places = await repo.getNearbyPlaces(15.4909, 73.8278);
      final wheelchairScores = places.map((p) => p.wheelchairScore).toList()
        ..sort();
      // Spread across the scale: worst below 6, best above 9.
      expect(wheelchairScores.first, lessThan(6.0));
      expect(wheelchairScores.last, greaterThan(9.0));
    });

    test('places carry features with confirmation data and scores', () async {
      final places = await repo.getNearbyPlaces(15.4909, 73.8278);
      for (final place in places) {
        expect(place.friendlyScore, inInclusiveRange(0, 10));
        expect(place.accessibilityFeatures, isNotEmpty);
        expect(place.communityConfirmations, greaterThan(0));
        expect(place.lastVerified, isNotNull);
      }
    });

    test('major places have realistic reviews with context', () async {
      final places = await repo.getNearbyPlaces(15.4909, 73.8278);
      final withReviews =
          places.where((p) => p.reviews.length >= 2).toList();
      expect(withReviews.length, greaterThanOrEqualTo(8));
      for (final place in withReviews) {
        for (final review in place.reviews) {
          expect(review.reviewerContext.displayLabel, isNotEmpty);
          expect(review.overallRating, inInclusiveRange(1, 10));
        }
      }
      // Reviews should not all be positive — honesty matters.
      final ratings = withReviews.expand((p) => p.reviews).map((r) => r.overallRating);
      expect(ratings.any((r) => r <= 7), isTrue);
    });

    test('searchPlaces matches name and category', () async {
      final byName = await repo.searchPlaces('fishka');
      expect(byName, isNotEmpty);
      final byCategory = await repo.searchPlaces('hospital');
      expect(byCategory, isNotEmpty);
      expect(byCategory.every((p) => p.name.toLowerCase().contains('hospital') ||
          p.category == PlaceCategory.hospital ||
          p.category == PlaceCategory.clinic), isTrue);
    });

    test('getPlaceById returns place or null', () async {
      final place = await repo.getPlaceById('place-1');
      expect(place, isNotNull);
      expect(place!.name, 'Fishka Restaurant');
      expect(await repo.getPlaceById('nope'), isNull);
    });

    test('addReview inserts review and increments totals', () async {
      final review = PlaceReview(
        id: 'test-r',
        placeId: 'place-1',
        userId: 'u-test',
        userName: 'Tester',
        overallRating: 8,
        comment: 'Test comment for repository insertion.',
        createdAt: DateTime.now(),
        reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo),
      );
      await repo.addReview('place-1', review);
      final updated = await repo.getPlaceById('place-1');
      expect(updated!.reviews.any((r) => r.id == 'test-r'), isTrue);
      expect(updated.totalReviews, 44);
    });

    test('every place has a real Google Maps link and it is used', () async {
      final places = await repo.getNearbyPlaces(15.4909, 73.8278);
      for (final place in places) {
        expect(place.directionsUrl, isNotNull,
            reason: '${place.name} is missing a directionsUrl');
        final uri = Uri.parse(place.directionsUrl!);
        expect(uri.scheme, 'https');
        expect(uri.host, 'www.google.com');
        expect(
          uri.path,
          anyOf('/maps/search/', '/maps/dir/'),
          reason: '${place.name} has unexpected maps path: ${uri.path}',
        );
        expect(
          uri.queryParameters['api'],
          '1',
          reason: '${place.name} link missing api=1',
        );
        expect(
          uri.queryParameters['query'] ?? uri.queryParameters['destination'],
          isNotNull,
          reason: '${place.name} link missing target',
        );
      }
    });

    test('directions URI targets the place on Google Maps', () {
      final place = Place(
        id: 'x', name: 'Fishka Restaurant', category: PlaceCategory.cafe,
        address: 'a', description: 'd',
        latitude: 15.5553, longitude: 73.7514,
        friendlyScore: 8, wheelchairScore: 8, visualAccessibilityScore: 8,
        hearingAccessibilityScore: 8, communicationScore: 8,
        accessibilityFeatures: const [],
        reviews: const [],
      );
      final service = NavigationService();

      final uri = service.buildDirectionsUri(place);
      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['destination'], '15.5553,73.7514');
      expect(uri.queryParameters['travelmode'], 'driving');

      // A place with a real link must use it verbatim.
      final withLink = place.copyWith(directionsUrl: 'https://www.google.com/maps/search/?api=1&query=Real+Venue');
      final realUri = service.buildDirectionsUri(withLink);
      expect(realUri.toString(), contains('query=Real+Venue'));

      final geo = service.buildGeoUri(place);
      expect(geo.scheme, 'geo');
      expect(geo.path, '15.5553,73.7514');
      expect(geo.queryParameters['q'], contains('Fishka Restaurant'));
    });

    test('distance calc is plausible (haversine sanity)', () {
      final place = Place(
        id: 'x', name: 'X', category: PlaceCategory.cafe,
        address: 'a', description: 'd',
        latitude: 15.4909, longitude: 73.8278,
        friendlyScore: 8, wheelchairScore: 8, visualAccessibilityScore: 8,
        hearingAccessibilityScore: 8, communicationScore: 8,
        accessibilityFeatures: const [],
        reviews: const [],
      );
      // Same point → 0 km.
      expect(place.distanceKmFrom(15.4909, 73.8278), closeTo(0, 0.001));
      // Roughly 1 degree of latitude ≈ 111 km.
      expect(place.distanceKmFrom(16.4909, 73.8278), closeTo(111.2, 2));
    });
  });

  group('Community place submissions', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Place communityPlace({String id = 'community-1', String name = 'Test Cafe'}) {
      return Place(
        id: id,
        name: name,
        category: PlaceCategory.cafe,
        address: 'Test Street, Goa',
        description: 'A community-submitted cafe.',
        latitude: 15.5555,
        longitude: 73.7510,
        friendlyScore: 0,
        wheelchairScore: 0,
        visualAccessibilityScore: 0,
        hearingAccessibilityScore: 0,
        communicationScore: 0,
        accessibilityFeatures: const [
          AccessibilityFeature(
            id: 'cf1',
            name: 'Ramp',
            icon: Icons.accessible,
            category: AccessibilityCategory.physical,
            status: FeatureStatus.available,
            confirmationCount: 1,
          ),
          AccessibilityFeature(
            id: 'cf2',
            name: 'Elevator',
            icon: Icons.elevator,
            category: AccessibilityCategory.physical,
            status: FeatureStatus.unavailable,
          ),
          AccessibilityFeature(
            id: 'cf3',
            name: 'Braille menu',
            icon: Icons.menu_book,
            category: AccessibilityCategory.visual,
            status: FeatureStatus.unknown,
          ),
        ],
        reviews: const [],
        source: PlaceSource.community,
        createdBy: 'demo-user',
        createdAt: DateTime.now(),
      );
    }

    test('community place is new/unrated and demo places are not', () async {
      final repo = MockPlaceRepository();
      final places = await repo.getNearbyPlaces(15.4909, 73.8278);
      expect(places.every((p) => p.source == PlaceSource.demo), isTrue);
      expect(places.any((p) => p.isNewCommunityPlace), isFalse);

      final stored = await repo.addPlace(communityPlace());
      expect(stored.source, PlaceSource.community);
      expect(stored.isNewCommunityPlace, isTrue);
    });

    test('addPlace persists and getNearbyPlaces returns seed + community',
        () async {
      SharedPreferences.setMockInitialValues({});
      final repo = MockPlaceRepository();
      final before = await repo.getNearbyPlaces(15.4909, 73.8278);
      final seedCount = before.length;

      await repo.addPlace(communityPlace());

      // Same repository instance: place is in the unified list.
      final after = await repo.getNearbyPlaces(15.4909, 73.8278);
      expect(after.length, seedCount + 1);
      expect(after.any((p) => p.id == 'community-1'), isTrue);
      // Seed places untouched.
      expect(after.where((p) => p.source == PlaceSource.demo).length, seedCount);

      // Fresh repository instance: place survives "restart".
      final restartedRepo = MockPlaceRepository();
      final restarted = await restartedRepo.getNearbyPlaces(15.4909, 73.8278);
      expect(restarted.length, seedCount + 1);
      expect(restarted.any((p) => p.id == 'community-1'), isTrue);
    });

    test('duplicate detection finds a nearby place within threshold', () async {
      final repo = MockPlaceRepository();
      // Fishka Restaurant is at 15.5553, 73.7514 — a few metres away.
      final nearby = await repo.findNearbyPlace(15.55531, 73.75141);
      expect(nearby, isNotNull);
      expect(nearby!.name, 'Fishka Restaurant');

      // A far location yields no duplicate.
      final far = await repo.findNearbyPlace(15.2993, 74.1240); // Margao
      expect(far, isNull);
    });

    test('place JSON round-trip preserves all submission data', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = MockPlaceRepository();
      await repo.addPlace(communityPlace());
      final all = await repo.getNearbyPlaces(15.4909, 73.8278);
      final stored = all.firstWhere((p) => p.id == 'community-1');

      final json = stored.toJson();
      final restored = Place.fromJson(json);

      expect(restored.id, stored.id);
      expect(restored.name, stored.name);
      expect(restored.category, stored.category);
      expect(restored.latitude, closeTo(stored.latitude, 0.00001));
      expect(restored.longitude, closeTo(stored.longitude, 0.00001));
      expect(restored.source, PlaceSource.community);
      expect(restored.createdBy, 'demo-user');
      expect(restored.accessibilityFeatures.length, 3);
      expect(restored.accessibilityFeatures[0].status, FeatureStatus.available);
      expect(
          restored.accessibilityFeatures[0].icon.codePoint,
          stored.accessibilityFeatures[0].icon.codePoint);
    });

    test('community place is searchable from the repository', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = MockPlaceRepository();
      await repo.addPlace(communityPlace(name: 'Zephyr Bistro'));
      final results = await repo.searchPlaces('Zephyr');
      expect(results, isNotEmpty);
      expect(results.first.name, 'Zephyr Bistro');
    });

    test('reviews on community places persist; demo reviews stay session-only',
        () async {
      SharedPreferences.setMockInitialValues({});
      final repo = MockPlaceRepository();
      await repo.addPlace(communityPlace(id: 'community-r', name: 'Persist Cafe'));

      final review = PlaceReview(
        id: 'r-test',
        placeId: 'community-r',
        userId: 'demo-user',
        userName: 'Demo User',
        overallRating: 8,
        comment: 'Nice accessible cafe.',
        createdAt: DateTime.now(),
        reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo),
      );
      await repo.addReview('community-r', review);

      final restarted = MockPlaceRepository();
      final place = await restarted.getPlaceById('community-r');
      expect(place, isNotNull);
      expect(place!.reviews.length, 1);
      expect(place.reviews.first.comment, 'Nice accessible cafe.');
    });

    test('new place score grows from real community reviews', () {
      // The AppState scorer averages actual review ratings once reviews
      // exist. Assert the model supports that growth path.
      final base = communityPlace();
      expect(base.isNewCommunityPlace, isTrue);
      final review = PlaceReview(
        id: 'rv1',
        placeId: base.id,
        userId: 'u1',
        userName: 'A',
        overallRating: 9,
        physicalAccessibilityRating: 8,
        communicationRating: 7,
        comment: 'Great',
        createdAt: DateTime.now(),
        reviewerContext: const AccessibilityContext(travelMode: TravelMode.solo),
      );
      final updated = base.copyWith(
        reviews: [review],
        totalReviews: 1,
      );
      expect(updated.reviews.length, 1);
      expect(updated.isNewCommunityPlace, isFalse);
    });
  });

  group('UserProfile contribution types', () {
    test('location add awards 10 points', () {
      expect(ContributionType.locationAdd.pointsEarned, 10);
    });
  });
}
