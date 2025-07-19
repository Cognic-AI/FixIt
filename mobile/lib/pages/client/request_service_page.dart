import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/auth_service.dart';

class RequestServicePage extends StatefulWidget {
  const RequestServicePage({
    super.key,
    required this.token,
    required this.uid,
    required this.category,
    required this.title,
    required this.price,
  });
  final String uid; 
  final String token;
  final String category; 
  final String title; 
  final double price; 

  @override
  State<RequestServicePage> createState() => _RequestServicePageState();
}

class _RequestServicePageState extends State<RequestServicePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String _selectedCategory = 'cleaning';
  LatLng? _selectedLocation;

  final List<String> categories = [
    'cleaning',
    'plumbing',
    'electrical',
    'painting',
    'gardening',
    'handyman',
    'moving',
    'tutoring',
    'beauty',
    'photography',
    'catering',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  void _loadUserLocation() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user != null && user.location.isNotEmpty) {
      _locationController.text = user.location;
      // Try to parse coordinates if they're in "lat,lng" format
      final parts = user.location.split(',');
      if (parts.length == 2) {
        try {
          final lat = double.parse(parts[0].trim());
          final lng = double.parse(parts[1].trim());
          _selectedLocation = LatLng(lat, lng);
        } catch (e) {
          developer.log('Could not parse user location coordinates: $e', name: 'RequestServicePage');
        }
      }
    } else {
      // If no profile location is set, show a placeholder
      _locationController.text = '';
    }
  }

  void _openMapDialog() async {
    LatLng? result = await showDialog<LatLng>(
      context: context,
      builder: (context) => _MapDialog(initialLocation: _selectedLocation),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
        _locationController.text = "${result.latitude}, ${result.longitude}";
      });
    }
  }

  void _showLocationOptions() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user?.location.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.person_pin_circle, color: Color(0xFF2563EB)),
                title: const Text('Use Profile Location'),
                subtitle: Text(user!.location),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _locationController.text = user.location;
                    // Try to parse coordinates
                    final parts = user.location.split(',');
                    if (parts.length == 2) {
                      try {
                        final lat = double.parse(parts[0].trim());
                        final lng = double.parse(parts[1].trim());
                        _selectedLocation = LatLng(lat, lng);
                      } catch (e) {
                        developer.log('Could not parse coordinates: $e', name: 'RequestServicePage');
                      }
                    }
                  });
                },
              ),
            if (user?.location.isEmpty != false)
              ListTile(
                leading: const Icon(Icons.person_pin_circle_outlined, color: Colors.grey),
                title: const Text('Profile Location'),
                subtitle: const Text('No location set in profile'),
                enabled: false,
              ),
            ListTile(
              leading: const Icon(Icons.my_location, color: Color(0xFF2563EB)),
              title: const Text('Use Current Location'),
              subtitle: const Text('Get your current GPS location'),
              onTap: () {
                Navigator.pop(context);
                _useCurrentLocation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Color(0xFF2563EB)),
              title: const Text('Select on Map'),
              subtitle: const Text('Choose a specific location'),
              onTap: () {
                Navigator.pop(context);
                _openMapDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Getting current location...'),
            ],
          ),
        ),
      );

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Navigator.pop(context); // Close loading dialog
        await Geolocator.openLocationSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      Navigator.pop(context); // Close loading dialog

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _locationController.text = "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location selected successfully!')),
      );

    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      developer.log('Error getting current location: $e', name: 'RequestServicePage');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get current location. Please try again.')),
      );
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      final requestData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'budget': _budgetController.text,
        'userId': widget.uid,
        'location': _locationController.text.isNotEmpty ? _locationController.text : 'No location specified',
      };

      try {
        // Simulate API call
        developer.log('Submitting request: $requestData', name: 'RequestServicePage');
        // Add your API call logic here

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service request submitted successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        developer.log('Error submitting request: $e', name: 'RequestServicePage');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit service request.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Service'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Display the service title
              Text(
                'Service Provider: ${widget.title}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Category
              Text(
                'Category: ${widget.category.toUpperCase()}', 
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Price
              Text(
                'Price: €${widget.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Service Location *',
                  hintText: 'Select service location',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.location_on),
                    onPressed: _showLocationOptions,
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please select a location for the service';
                  }
                  return null;
                },
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Describe your required service',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                style: const TextStyle(color: Colors.black), 
              ),
              const SizedBox(height: 16),

              // Budget
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Budget (Optional)',
                  hintText: 'Enter your budget',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Submit Request',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

class _MapDialog extends StatefulWidget {
  final LatLng? initialLocation;

  const _MapDialog({Key? key, this.initialLocation}) : super(key: key);

  @override
  State<_MapDialog> createState() => _MapDialogState();
}

class _MapDialogState extends State<_MapDialog> {
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      if (_selectedLocation == null) {
        _selectedLocation = _currentLocation;
      }
    });

    // Pan the map to the current location
    if (_mapController != null && _currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_currentLocation!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Location'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.initialLocation ?? const LatLng(7.8731, 80.7718),
            zoom: 11.5,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            // Pan to current location if available
            if (_currentLocation != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLng(_currentLocation!),
              );
            }
          },
          markers: _selectedLocation != null
              ? {
                  Marker(
                    markerId: const MarkerId('selected-location'),
                    position: _selectedLocation!,
                  ),
                }
              : {},
          onTap: (LatLng position) {
            setState(() {
              _selectedLocation = position;
            });
          },
          myLocationEnabled: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedLocation),
          child: const Text('Select'),
        ),
      ],
    );
  }
}
