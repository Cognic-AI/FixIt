import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/vendor_service.dart';
import '../../services/auth_service.dart';
import '../../models/service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class AddServicePage extends StatefulWidget {
  const AddServicePage(
      {super.key, required this.token, required this.vendorId});

  final String token;
  final String vendorId;

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _datesController = TextEditingController();

  String _selectedCategory = 'cleaning';
  final List<String> _amenities = [];
  final _amenityController = TextEditingController();
  bool _isLoading = false;
  LatLng? _selectedLocation;
  String? _locationError;

  final List<String> _categories = [
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
    developer.log('Initializing AddServicePage', name: 'AddServicePage');

    // Load services when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vendorService = Provider.of<VendorService>(context, listen: false);
      vendorService.loadMyServices(
        widget.token,
      );
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    _datesController.dispose();
    _amenityController.dispose();
    super.dispose();
  }

  void _openMapDialog() async {
    try {
      setState(() {
        _locationError = null;
      });
      
      LatLng? result = await showDialog<LatLng>(
        context: context,
        builder: (context) => _MapDialog(initialLocation: _selectedLocation),
      );

      if (result != null) {
        setState(() {
          _selectedLocation = result;
          _locationController.text = "${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}";
        });
      }
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location. Please try again.';
      });
      _showErrorSnackBar('Failed to get location: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Service'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<VendorService>(
        builder: (context, vendorService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add New Service Form Title
                Row(
                  children: [
                    const Text(
                      'Add New Service',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (vendorService.myServices.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Title
                      CustomTextField(
                        controller: _titleController,
                        label: 'Service Title *',
                        hintText: 'Enter service title',
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter service title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      CustomTextField(
                        controller: _descriptionController,
                        label: 'Description *',
                        hintText: 'Describe your service',
                        maxLines: 4,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter service description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Price
                      CustomTextField(
                        controller: _priceController,
                        label: 'Price (\$) *',
                        hintText: 'Enter service price',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter service price';
                          }
                          if (double.tryParse(value!) == null) {
                            return 'Please enter a valid price';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Location with Map
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              hintText: 'Enter service location',
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.map_outlined),
                                onPressed: _openMapDialog,
                                tooltip: 'Select on map',
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                              ),
                              errorText: _locationError,
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter service location';
                              }
                              return null;
                            },
                            maxLines: 2,
                            minLines: 1,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'This location will be visible to clients when they browse services.',
                                    style: TextStyle(
                                      color: Colors.blue[800],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category
                      const Text(
                        'Category *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCategory = newValue!;
                              });
                            },
                            items: _categories
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value.toUpperCase()),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Image URL
                      CustomTextField(
                        controller: _imageUrlController,
                        label: 'Image URL',
                        hintText: 'Enter image URL (optional)',
                      ),
                      const SizedBox(height: 16),

                      // Availability Dropdown
                      const Text(
                        'Availability',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _datesController.text.isEmpty
                                ? 'Available'
                                : _datesController.text,
                            items: const [
                              DropdownMenuItem(
                                value: 'Available',
                                child: Text('Available'),
                              ),
                              DropdownMenuItem(
                                value: 'Unavailable',
                                child: Text('Unavailable'),
                              ),
                            ],
                            onChanged: (String? newValue) {
                              setState(() {
                                _datesController.text = newValue ?? 'Available';
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Amenities/Features
                      const Text(
                        'Service Features',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _amenityController,
                              label: '',
                              hintText: 'Add a feature',
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _addAmenity,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_amenities.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _amenities.map((amenity) {
                            return Chip(
                              label: Text(amenity),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() {
                                  _amenities.remove(amenity);
                                });
                              },
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: 'Add Service',
                          onPressed: _isLoading ? null : _submitService,
                          isLoading: _isLoading,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addAmenity() {
    final amenity = _amenityController.text.trim();
    if (amenity.isNotEmpty && !_amenities.contains(amenity)) {
      setState(() {
        _amenities.add(amenity);
        _amenityController.clear();
      });
    }
  }

  void _submitService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final vendorService = Provider.of<VendorService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final service = Service(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
        providerId: widget.vendorId,
        providerEmail: currentUser.email,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        availability:
            _datesController.text.trim().isNotEmpty, // true if dates entered
        price: double.parse(_priceController.text.trim()),
        location: _locationController.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        tags: _amenities.join(','),
        images: _imageUrlController.text.trim(),
      );

      final success = await vendorService.addService(
        service,
        widget.token,
        widget.vendorId,
      );

      if (success) {
        developer.log('✅ Service added successfully', name: 'AddServicePage');
        if (mounted) {
          // Clear the form
          _titleController.clear();
          _descriptionController.clear();
          _priceController.clear();
          _locationController.clear();
          _imageUrlController.clear();
          _datesController.clear();
          _amenities.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Service added successfully!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                            'Total services: ${vendorService.myServices.length + 1}'),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Reload services to show the new one
          await vendorService.loadMyServices(
            widget.token,
          );
        }
      } else {
        throw Exception('Failed to add service');
      }
    } catch (e) {
      developer.log('Error adding service: $e', name: 'AddServicePage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Reload services in VendorService
        final vendorService =
            Provider.of<VendorService>(context, listen: false);
        await vendorService.loadMyServices(
          widget.token,
        );
      }
    }
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLocationPrompt();
    });
  }

  Future<void> _showLocationPrompt() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Choose Location Method'),
        content: const Text('How would you like to set the service location?'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'current'),
            icon: const Icon(Icons.my_location),
            label: const Text('Use Current Location'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'different'),
            icon: const Icon(Icons.map),
            label: const Text('Pick on Map'),
          ),
        ],
      ),
    );

    if (choice == 'current') {
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location services are disabled. Please enable them.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is required to use current location.'),
              ),
            );
          }
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _selectedLocation = _currentLocation;
        });

        // Pan the map to the current location
        if (_mapController != null && _currentLocation != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(_currentLocation!),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get current location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          const Text('Select Service Location'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialLocation ?? const LatLng(7.8731, 80.7718), // Default to Sri Lanka
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
                      infoWindow: const InfoWindow(
                        title: 'Service Location',
                      ),
                    ),
                  }
                : {},
            onTap: (LatLng position) {
              setState(() {
                _selectedLocation = position;
              });
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedLocation != null
              ? () => Navigator.pop(context, _selectedLocation)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
          child: const Text('Select'),
        ),
      ],
    );
  }
}
