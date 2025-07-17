import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPopup extends StatefulWidget {
  const MapPopup({super.key, this.location, this.name, this.description});

  final String? location;
  final String? name;
  final String? description;

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
          final marker = Marker(
            markerId: const MarkerId('custom_location'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: widget.name ?? 'Location',
              snippet: widget.description ?? 'Placeholder details here',
            ),
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
