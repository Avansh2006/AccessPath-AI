import 'package:access_map/features/map/domain/place_repository.dart';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/models/accessibility_rating.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_category.dart';
import 'package:access_map/shared/models/place_review.dart';
import 'package:access_map/shared/models/travel_mode.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePlaceRepository implements PlaceRepository, LivePlaceUpdates {
  SupabasePlaceRepository(this.client);

  final SupabaseClient client;

  /// Listens to Postgres changes on `places` and `reviews`. Events only
  /// arrive when both tables are in the `supabase_realtime` publication.
  @override
  Future<void> Function() subscribeToPlaceChanges({
    required void Function() onChange,
    required void Function(LiveUpdatesStatus status) onStatus,
  }) {
    onStatus(LiveUpdatesStatus.connecting);
    final channel = client.channel('live-accessibility-map');
    for (final table in const ['places', 'reviews']) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => onChange(),
      );
    }
    channel.subscribe((status, _) {
      switch (status) {
        case RealtimeSubscribeStatus.subscribed:
          onStatus(LiveUpdatesStatus.live);
        case RealtimeSubscribeStatus.channelError:
        case RealtimeSubscribeStatus.timedOut:
          onStatus(LiveUpdatesStatus.error);
        case RealtimeSubscribeStatus.closed:
          break;
      }
    });
    return () async {
      await client.removeChannel(channel);
    };
  }

  @override
  Future<List<Place>> getNearbyPlaces(
    double lat,
    double lng, {
    double radiusKm = 10,
  }) async {
    final rows = await client.from('places').select('*, reviews(*)').limit(200);
    final places =
        (rows as List<dynamic>)
            .map((row) => _placeFromRow(row as Map<String, dynamic>))
            .where((place) => place.distanceKmFrom(lat, lng) <= radiusKm)
            .toList()
          ..sort(
            (a, b) => a
                .distanceKmFrom(lat, lng)
                .compareTo(b.distanceKmFrom(lat, lng)),
          );
    return places;
  }

  @override
  Future<List<Place>> searchPlaces(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      final rows = await client
          .from('places')
          .select('*, reviews(*)')
          .limit(200);
      return (rows as List<dynamic>)
          .map((row) => _placeFromRow(row as Map<String, dynamic>))
          .toList();
    }
    final rows = await client.from('places').select('*, reviews(*)').limit(200);
    return (rows as List<dynamic>)
        .map((row) => _placeFromRow(row as Map<String, dynamic>))
        .where(
          (place) =>
              place.name.toLowerCase().contains(normalized) ||
              place.address.toLowerCase().contains(normalized) ||
              place.category.displayName.toLowerCase().contains(normalized),
        )
        .toList();
  }

  @override
  Future<Place?> getPlaceById(String id) async {
    final row = await client
        .from('places')
        .select('*, reviews(*)')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : _placeFromRow(row);
  }

  @override
  Future<List<Place>> getPlacesByCategory(PlaceCategory category) async {
    final rows = await client
        .from('places')
        .select('*, reviews(*)')
        .eq('category', category.name)
        .limit(200);
    return (rows as List<dynamic>)
        .map((row) => _placeFromRow(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addReview(String placeId, PlaceReview review) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Authentication is required to submit reviews.');
    }
    await client.from('reviews').insert({
      'id': review.id,
      'place_id': placeId,
      'created_by': user.id,
      'user_name': review.userName,
      'comment': review.comment,
      'overall_rating': review.overallRating,
      'reviewer_context': {
        'travelMode': review.reviewerContext.travelMode?.name,
        'needs': review.reviewerContext.accessibilityNeeds
            .map((item) => item.name)
            .toList(),
      },
      for (final criterion in AccessibilityCriterion.values)
        '${_columnName(criterion)}_status':
            (review.accessibilityRatings[criterion] ??
                    const AccessibilityRating.unknown())
                .status
                .name,
      for (final criterion in AccessibilityCriterion.values)
        '${_columnName(criterion)}_rating':
            review.accessibilityRatings[criterion]?.value,
    });
  }

  @override
  Future<Place> addPlace(Place place) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Authentication is required to add places.');
    }
    final row = await client
        .from('places')
        .insert({
          'id': place.id,
          'name': place.name,
          'category': place.category.name,
          'address': place.address,
          'phone': place.phone,
          'website': place.website,
          'directions_url': place.directionsUrl,
          'description': place.description,
          'latitude': place.latitude,
          'longitude': place.longitude,
          'accessibility_features':
              place.toJson()['accessibilityFeatures'] as List<dynamic>,
          'image_urls': place.imageUrls,
          'photos': place.photos.map((photo) => photo.toJson()).toList(),
          'created_by': user.id,
        })
        .select('*, reviews(*)')
        .single();
    return _placeFromRow(row);
  }

  @override
  Future<void> updatePlace(Place place) async {
    final user = client.auth.currentUser;
    if (user == null || place.createdBy != user.id) return;
    await client
        .from('places')
        .update({
          'accessibility_features':
              place.toJson()['accessibilityFeatures'] as List<dynamic>,
          'photos': place.photos.map((photo) => photo.toJson()).toList(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', place.id);
  }

  @override
  Future<Place?> findNearbyPlace(
    double lat,
    double lng, {
    double radiusKm = 0.15,
  }) async {
    final rows = await client.from('places').select('*, reviews(*)').limit(200);
    final candidates =
        (rows as List<dynamic>)
            .map((row) => _placeFromRow(row as Map<String, dynamic>))
            .where((place) => place.distanceKmFrom(lat, lng) <= radiusKm)
            .toList()
          ..sort(
            (a, b) => a
                .distanceKmFrom(lat, lng)
                .compareTo(b.distanceKmFrom(lat, lng)),
          );
    return candidates.isEmpty ? null : candidates.first;
  }

  Place _placeFromRow(Map<String, dynamic> row) {
    final reviews =
        (row['reviews'] as List<dynamic>? ?? [])
            .map((item) => _reviewFromRow(item as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final score = const AccessibilityScoreCalculator().calculate(
      reviews.map((review) => review.accessibilityRatings),
    );
    final overallTen = (score.overall ?? 0) / 10;
    double categoryTen(AccessibilityCriterion criterion) =>
        (score.categoryScores[criterion] ?? 0) / 10;
    return Place(
      id: row['id'] as String,
      name: row['name'] as String,
      category: PlaceCategory.values.firstWhere(
        (item) => item.name == row['category'],
        orElse: () => PlaceCategory.communityCenter,
      ),
      address: row['address'] as String? ?? '',
      phone: row['phone'] as String?,
      website: row['website'] as String?,
      directionsUrl: row['directions_url'] as String?,
      description: row['description'] as String? ?? '',
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      friendlyScore: overallTen,
      wheelchairScore: categoryTen(AccessibilityCriterion.stepFreeAccess),
      visualAccessibilityScore: categoryTen(AccessibilityCriterion.wayfinding),
      hearingAccessibilityScore: categoryTen(AccessibilityCriterion.wayfinding),
      communicationScore: categoryTen(AccessibilityCriterion.wayfinding),
      accessibilityFeatures:
          (row['accessibility_features'] as List<dynamic>? ?? [])
              .map(
                (item) => Place.featureFromJson(item as Map<String, dynamic>),
              )
              .toList(),
      reviews: reviews,
      imageUrls: List<String>.from(row['image_urls'] as List<dynamic>? ?? []),
      photos: (row['photos'] as List<dynamic>? ?? [])
          .map((item) => PlacePhoto.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalReviews: reviews.length,
      source: PlaceSource.community,
      createdBy: row['created_by'] as String?,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? ''),
      lastCommunityUpdate: DateTime.tryParse(
        row['updated_at'] as String? ?? '',
      ),
    );
  }

  PlaceReview _reviewFromRow(Map<String, dynamic> row) {
    final context = row['reviewer_context'] as Map<String, dynamic>? ?? {};
    final travelModeName = context['travelMode'] as String?;
    return PlaceReview(
      id: row['id'] as String,
      placeId: row['place_id'] as String,
      userId: row['created_by'] as String? ?? 'community',
      userName: row['user_name'] as String? ?? 'Community member',
      overallRating: (row['overall_rating'] as num? ?? 0).toDouble(),
      comment: row['comment'] as String? ?? '',
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      reviewerContext: AccessibilityContext(
        travelMode: travelModeName == null
            ? null
            : TravelMode.values.firstWhere(
                (item) => item.name == travelModeName,
                orElse: () => TravelMode.solo,
              ),
        accessibilityNeeds: (context['needs'] as List<dynamic>? ?? [])
            .map(
              (name) => AccessibilityNeed.values.firstWhere(
                (item) => item.name == name,
                orElse: () => AccessibilityNeed.other,
              ),
            )
            .toList(),
      ),
      helpfulVotes: row['helpful_votes'] as int? ?? 0,
      reported: row['reported'] as bool? ?? false,
      accessibilityRatings: {
        for (final criterion in AccessibilityCriterion.values)
          criterion: _ratingFromRow(row, criterion),
      },
    );
  }

  static AccessibilityRating _ratingFromRow(
    Map<String, dynamic> row,
    AccessibilityCriterion criterion,
  ) {
    final prefix = _columnName(criterion);
    final status = row['${prefix}_status'] as String? ?? 'unknown';
    final value = row['${prefix}_rating'] as num?;
    if (status == AccessibilityRatingStatus.rated.name && value != null) {
      return AccessibilityRating.rated(value.toDouble());
    }
    return status == AccessibilityRatingStatus.notApplicable.name
        ? const AccessibilityRating.notApplicable()
        : const AccessibilityRating.unknown();
  }

  static String _columnName(AccessibilityCriterion criterion) =>
      switch (criterion) {
        AccessibilityCriterion.stepFreeAccess => 'step_free',
        AccessibilityCriterion.lifts => 'lifts',
        AccessibilityCriterion.accessibleWashrooms => 'accessible_washrooms',
        AccessibilityCriterion.seating => 'seating',
        AccessibilityCriterion.wayfinding => 'wayfinding',
      };
}
