import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// A selected geographic point plus the best-known human-readable address.
class GeoSelection {
  final double latitude;
  final double longitude;
  final String address;

  const GeoSelection({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

/// Resolves coordinates into addresses and reads the device location.
///
/// The MVP uses geolocator's built-in reverse geocoding where available;
/// when no address can be resolved it falls back to a coordinate label so
/// the flow never blocks. A future backend can swap in a real geocoder.
class GeocodingService {
  const GeocodingService();

  /// Reverse-geocode [latitude]/[longitude]. Never throws.
  Future<String> reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return _coordinateLabel(latitude, longitude);
      final p = placemarks.first;
      final parts = [
        if (p.street?.isNotEmpty == true) p.street!,
        if (p.locality?.isNotEmpty == true) p.locality!,
        if (p.administrativeArea?.isNotEmpty == true) p.administrativeArea!,
      ];
      if (parts.isEmpty) return _coordinateLabel(latitude, longitude);
      return parts.join(', ');
    } catch (_) {
      return _coordinateLabel(latitude, longitude);
    }
  }

  /// Forward-geocode a typed place name/address into coordinates.
  /// Returns null when nothing could be resolved. Never throws.
  Future<GeoSelection?> searchPlace(String query) async {
    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) return null;
      final loc = locations.first;
      final address = await reverseGeocode(loc.latitude, loc.longitude);
      return GeoSelection(
        latitude: loc.latitude,
        longitude: loc.longitude,
        address: address,
      );
    } catch (_) {
      return null;
    }
  }

  /// Current device position, asking for permission only when called.
  /// Returns null when permission is denied or location is unavailable.
  Future<GeoSelection?> currentPosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final address = await reverseGeocode(position.latitude, position.longitude);
      return GeoSelection(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (_) {
      return null;
    }
  }

  static String _coordinateLabel(double lat, double lng) =>
      '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
}
