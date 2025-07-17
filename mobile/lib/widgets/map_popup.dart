import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPopup extends StatefulWidget {
  const MapPopup(
      {super.key,
      this.location,
      this.name,
      this.description,
      this.onRequestService});

  final String? location;
  final String? name;
  final String? description;
  final void Function()? onRequestService;
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
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _addLocationMarkerIfNeeded();
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

    _moveCameraToCurrentLocation();
  }

  void _moveCameraToCurrentLocation() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      ));
    }
  }

  void _addLocationMarkerIfNeeded() {
    if (widget.location != null) {
      final parts = widget.location!.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          if (_currentPosition != null) {}
          final marker = Marker(
            markerId: const MarkerId('custom_location'),
            position: LatLng(lat, lng),
            onTap: () => _onMarkerTap(LatLng(lat, lng)),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
          );
          setState(() {
            _markers.add(marker);
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
                    widget.name ?? 'Service Location',
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
            if (widget.description != null) ...[
              Text(
                widget.description!,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
            ],

            // Location and distance
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.location ?? 'Unknown location',
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
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Handle request service action
                          widget.onRequestService!();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.handyman),
                        label: const Text('Request Service'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Handle directions action
                          Navigator.pop(context);
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        initialCameraPosition: _initialCameraPosition,
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
          _moveCameraToCurrentLocation();
        },
      ),
    );
  }
}
