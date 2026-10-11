import 'package:url_launcher/url_launcher.dart';
import 'package:access_map/shared/models/place.dart';

/// Abstraction for external navigation/directions.
/// Currently opens Google Maps. Can be swapped to Apple Maps, Mapbox, etc.
class NavigationService {
  /// Builds the Google Maps directions URL for [place].
  /// Prefers the place's real [Place.directionsUrl] when available so the
  /// user lands on the actual venue; otherwise routes to its coordinates.
  /// Exposed for testing.
  Uri buildDirectionsUri(Place place) {
    final real = place.directionsUrl;
    if (real != null && real.isNotEmpty) {
      return Uri.parse(real);
    }
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${place.latitude},${place.longitude}'
      '&destination_place_id='
      '&travelmode=driving',
    );
  }

  /// Builds a geo: fallback URI centered on the place.
  Uri buildGeoUri(Place place) {
    return Uri.parse(
      'geo:${place.latitude},${place.longitude}'
      '?q=${Uri.encodeComponent('${place.name} (${place.latitude}, ${place.longitude})')}',
    );
  }

  Future<bool> openExternalDirections(Place place) async {
    final directionsUri = buildDirectionsUri(place);

    // Launch directly — on Android 11+ canLaunchUrl returns false for
    // apps not declared in <queries>, but external launch still works.
    if (await launchUrl(directionsUri, mode: LaunchMode.externalApplication)) {
      return true;
    }

    // Fallback: geo: URI handled by any maps app on the device.
    final geoUri = buildGeoUri(place);
    try {
      return await launchUrl(geoUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
