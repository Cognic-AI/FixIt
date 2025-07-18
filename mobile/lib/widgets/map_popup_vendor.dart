import 'package:fixit/models/request.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPopupVendor extends StatefulWidget {
  const MapPopupVendor(
      {super.key,
      this.location,
      this.name,
      this.description,
      this.onMessage,
      required this.request});

  final String? location;
  final String? name;
  final String? description;
  final void Function()? onMessage;
  final Request request;

  @override
  _MapPopupVendorState createState() => _MapPopupVendorState();
}

class _MapPopupVendorState extends State<MapPopupVendor> {
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
    final parts = widget.request.clientLocation.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) {
        final marker = Marker(
          markerId: const MarkerId('client_location'),
          position: LatLng(lat, lng),
          onTap: () => _onMarkerTap(LatLng(lat, lng)),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
        setState(() {
          _markers.add(marker);
        });
      }
    }
  }

  void _onMarkerTap(LatLng markerPosition) {
    _showClientBottomSheet(markerPosition);
  }

  String _calculateDistance(LatLng clientLocation) {
    if (_currentPosition == null) {
      return 'Distance unknown';
    }

    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      clientLocation.latitude,
      clientLocation.longitude,
    );

    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m away';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)}km away';
    }
  }

  void _showClientBottomSheet(LatLng markerPosition) {
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
                    widget.request.clientName,
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
            Text(
              widget.request.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              widget.request.description,
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Price and category
            Row(
              children: [
                const Icon(Icons.category, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  widget.request.category,
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  widget.request.price.toString(),
                  style: const TextStyle(color: Colors.grey),
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
                    widget.request.clientLocation,
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

            // Message button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onMessage?.call();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.message),
                label: const Text('Message Client'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
              ),
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
