import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_category.dart';
import 'package:access_map/shared/models/place_review.dart';

abstract class PlaceRepository {
  Future<List<Place>> getNearbyPlaces(
    double lat,
    double lng, {
    double radiusKm = 10,
  });
  Future<List<Place>> searchPlaces(String query);
  Future<Place?> getPlaceById(String id);
  Future<List<Place>> getPlacesByCategory(PlaceCategory category);
  Future<void> addReview(String placeId, PlaceReview review);
  Future<Place> addPlace(Place place);
  Future<void> updatePlace(Place place);
  Future<Place?> findNearbyPlace(
    double lat,
    double lng, {
    double radiusKm = 0.15,
  });
}

enum LiveUpdatesStatus { unsupported, connecting, live, error }

/// Optional capability for repositories that can push backend changes.
/// Repositories without a realtime backend simply don't implement it.
abstract interface class LivePlaceUpdates {
  /// Calls [onChange] whenever places or reviews change on the backend.
  /// Returns a callback that cancels the subscription.
  Future<void> Function() subscribeToPlaceChanges({
    required void Function() onChange,
    required void Function(LiveUpdatesStatus status) onStatus,
  });
}
