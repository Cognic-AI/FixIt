import 'dart:math' as math;
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final Location _location = Location();
  LocationData? _currentLocation;

  /// Get the current location of the user
  Future<LatLng?> getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return null;
        }
      }

      // Check location permissions
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return null;
        }
      }

      // Get current location
      _currentLocation = await _location.getLocation();
      if (_currentLocation != null) {
        return LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
      }
    } catch (e) {
      print('Error getting location: $e');
    }
    return null;
  }

  /// Get distance between two points in kilometers
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth radius in kilometers
    
    double lat1Rad = point1.latitude * (math.pi / 180);
    double lat2Rad = point2.latitude * (math.pi / 180);
    double deltaLat = (point2.latitude - point1.latitude) * (math.pi / 180);
    double deltaLng = (point2.longitude - point1.longitude) * (math.pi / 180);

    double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    PermissionStatus permissionGranted = await _location.hasPermission();
    return permissionGranted == PermissionStatus.granted;
  }

  /// Request location permissions
  Future<bool> requestLocationPermission() async {
    PermissionStatus permissionGranted = await _location.requestPermission();
    return permissionGranted == PermissionStatus.granted;
  }

  /// Listen to location changes
  Stream<LocationData> get locationStream => _location.onLocationChanged;

  /// Get cached current location
  LocationData? get currentLocation => _currentLocation;
}
