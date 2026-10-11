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
