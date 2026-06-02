import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastPosition;

  Position? get lastPosition => _lastPosition;

  /// Request location permission and get current position.
  Future<Position> getCurrentPosition({bool forceRefresh = false}) async {
    if (!forceRefresh && _lastPosition != null) {
      return _lastPosition!;
    }

    final permission = await _checkAndRequestPermission();
    if (!permission) {
      throw Exception(
          'Izin lokasi ditolak. Aktifkan lokasi di pengaturan perangkat.');
    }

    _lastPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ).timeout(const Duration(seconds: 15));
    return _lastPosition!;
  }

  /// Check and request location permissions.
  Future<bool> _checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'Layanan lokasi tidak aktif. Nyalakan GPS di pengaturan.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// Get human-readable address from coordinates.
  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return 'Lokasi tidak diketahui';

      final p = placemarks.first;
      final parts = <String>[];

      if (p.street != null && p.street!.isNotEmpty) parts.add(p.street!);
      if (p.subLocality != null && p.subLocality!.isNotEmpty) {
        parts.add(p.subLocality!);
      }
      if (p.locality != null && p.locality!.isNotEmpty) {
        parts.add(p.locality!);
      }
      if (p.subAdministrativeArea != null &&
          p.subAdministrativeArea!.isNotEmpty) {
        parts.add(p.subAdministrativeArea!);
      }

      return parts.isNotEmpty ? parts.join(', ') : 'Lokasi tidak diketahui';
    } catch (e) {
      return 'Lokasi tidak diketahui';
    }
  }

  /// Calculate distance between two coordinates in kilometers.
  double calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  /// Stream position updates.
  Stream<Position> get positionStream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 50, // Emit new event every 50m
        ),
      );
}
