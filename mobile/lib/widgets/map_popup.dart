import 'package:fixit/pages/client/request_service_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:developer' as developer;
import '../models/service.dart';

const googleMapsApiKey = "AIzaSyDmToh-xq4nhfUAaz6dpYl9IylWNWJMCMI";

class MapPopup extends StatefulWidget {
  const MapPopup(
      {super.key,
      required this.service,
      required this.token,
      required this.uid});

  final Service service;
  final String token;
  final String uid;

  @override
  _MapPopupState createState() => _MapPopupState();
}

class _MapPopupState extends State<MapPopup> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(7.8731, 80.7718), // Default position (Sri Lanka)
    zoom: 11.5,
  );

  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  Map<PolylineId, Polyline> _polylines = {};
  LatLng? _destinationLocation;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _addLocationMarkerIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_destinationLocation != null) {
        _moveCameraToServiceLocation();
      } else {
        _moveCameraToCurrentLocation();
      }
    });
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });

    if (_destinationLocation == null) {
      _moveCameraToCurrentLocation();
    }
  }

  void _moveCameraToCurrentLocation() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      ));
    }
  }

  void _addLocationMarkerIfNeeded() {
    if (widget.service.location.isNotEmpty) {
      final parts = widget.service.location.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          final destinationLatLng = LatLng(lat, lng);
          final marker = Marker(
            markerId: const MarkerId('custom_location'),
            position: destinationLatLng,
            onTap: () => _onMarkerTap(destinationLatLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
          );
          setState(() {
            _markers.add(marker);
            _destinationLocation = destinationLatLng; // Store destination
          });
        }
      }
    }
  }

  void _onMarkerTap(LatLng markerPosition) {
    _showServiceBottomSheet(markerPosition);
  }

  String _calculateDistance(LatLng serviceLocation) {
    if (_currentPosition == null) {
      return 'Distance unknown';
    }

    // Calculate distance using Geolocator's distanceBetween method
    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      serviceLocation.latitude,
      serviceLocation.longitude,
    );

    // Convert to appropriate unit
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m away';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)}km away';
    }
  }

  Future<void> _showDirections() async {
    if (_currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current location not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_destinationLocation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Destination location not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final coordinates = await _getPolyLinePoints(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        _destinationLocation!,
      );

      if (coordinates.isNotEmpty) {
        _generatePolylineFromPoints(coordinates);
        _fitCameraToRoute(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          _destinationLocation!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Route to ${widget.service.title} displayed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find route'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Error getting directions: $e', name: 'MapPopup');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error getting directions'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<LatLng>> _getPolyLinePoints(
      LatLng origin, LatLng destination) async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();

    try {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
        googleApiKey: googleMapsApiKey,
      );

      if (result.points.isNotEmpty) {
        for (PointLatLng point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      } else {
        developer.log('No route points found: ${result.errorMessage}',
            name: 'MapPopup');
      }
    } catch (e) {
      developer.log('Error getting polyline points: $e', name: 'MapPopup');
    }

    return polylineCoordinates;
  }

  void _generatePolylineFromPoints(List<LatLng> polylineCoordinates) {
    const PolylineId id = PolylineId("route");
    Polyline polyline = Polyline(
      polylineId: id,
      color: const Color(0xFF2563EB),
      points: polylineCoordinates,
      width: 5,
      patterns: [], // Solid line
    );

    setState(() {
      _polylines[id] = polyline;
    });
  }

  void _fitCameraToRoute(LatLng origin, LatLng destination) {
    if (_mapController == null) return;

    // Calculate bounds that include both origin and destination
    double minLat = origin.latitude < destination.latitude
        ? origin.latitude
        : destination.latitude;
    double maxLat = origin.latitude > destination.latitude
        ? origin.latitude
        : destination.latitude;
    double minLng = origin.longitude < destination.longitude
        ? origin.longitude
        : destination.longitude;
    double maxLng = origin.longitude > destination.longitude
        ? origin.longitude
        : destination.longitude;

    // Add padding
    const padding = 0.01;
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
  }

  void _clearRoute() {
    setState(() {
      _polylines.clear();
    });
  }

  void _navigateToRequestService() {
    // Now we have complete service information
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestServicePage(
          token: widget.token,
          uid: widget.uid,
          category: widget.service.category,
          title: widget.service.title,
          price: widget.service.price,
          service: widget.service,
        ),
      ),
    );
  }

  void _showServiceBottomSheet(LatLng markerPosition) {
    final distance = _calculateDistance(markerPosition);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.service.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Service details
            if (widget.service.description.isNotEmpty) ...[
              Text(
                widget.service.description,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
            ],

            // Category and Price
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.service.category.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '€${widget.service.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location and distance
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.service.location,
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Distance information
            Row(
              children: [
                const Icon(Icons.directions,
                    size: 16, color: Color(0xFF2563EB)),
                const SizedBox(width: 4),
                Text(
                  distance,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Action buttons
            Column(
              children: [
                // First row of buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Handle contact action
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.message),
                        label: const Text('Message'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Handle directions action
                          Navigator.pop(context);
                          _showDirections();
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34D399),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Second row of buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Handle request service action
                      Navigator.pop(context);
                      _navigateToRequestService();
                    },
                    icon: const Icon(Icons.handyman),
                    label: const Text('Request Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _moveCameraToServiceLocation() {
    if (_mapController != null && _destinationLocation != null) {
      _mapController!
          .animateCamera(CameraUpdate.newLatLng(_destinationLocation!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        initialCameraPosition: _initialCameraPosition,
        markers: _markers,
        polylines:
            Set<Polyline>.of(_polylines.values), // Add the polylines to the map
        onMapCreated: (controller) {
          _mapController = controller;
          _moveCameraToServiceLocation();
        },
      ),
      // Clear route button (only shown when there's an active route)
      floatingActionButton: _polylines.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _clearRoute,
              icon: const Icon(Icons.clear),
              label: Text('Clear Route to ${widget.service.title}'),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
