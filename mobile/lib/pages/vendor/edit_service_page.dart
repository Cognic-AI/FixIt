import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/vendor_service.dart';
import '../../models/service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class EditServicePage extends StatefulWidget {
  const EditServicePage({
    super.key,
    required this.token,
    required this.service,
  });

  final String token;
  final Service service;

  @override
  State<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _locationController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _datesController;

  late String _selectedCategory;
  late final List<String> _amenities;
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
    developer.log('Initializing EditServicePage', name: 'EditServicePage');

    // Initialize controllers with existing service data
    _titleController = TextEditingController(text: widget.service.title);
    _descriptionController =
        TextEditingController(text: widget.service.description);
    _priceController =
        TextEditingController(text: widget.service.price.toString());
    _locationController = TextEditingController(text: widget.service.location);
    _imageUrlController = TextEditingController(text: widget.service.images);
    _datesController = TextEditingController(
        text: widget.service.availability ? 'Available' : 'Unavailable');

    _selectedCategory = widget.service.category;
    _amenities = widget.service.tags.isNotEmpty
        ? widget.service.tags
            .split(',')
            .where((tag) => tag.trim().isNotEmpty)
            .toList()
        : [];

    // Parse location if it's in lat,lng format
    if (widget.service.location.contains(',')) {
      try {
        final parts = widget.service.location.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) {
            _selectedLocation = LatLng(lat, lng);
          }
        }
      } catch (e) {
        developer.log('Could not parse location coordinates: $e',
            name: 'EditServicePage');
      }
    }
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
          _locationController.text =
              "${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}";
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
        title: const Text('Edit Service'),
        backgroundColor: const Color(0xFF006FD6),
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
                // Edit Service Form Title
                Row(
                  children: [
                    const Text(
                      'Edit Service',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006FD6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'EDIT',
                        style: TextStyle(
                          color: Color(0xFF006FD6),
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
                        label: 'Price (LKR) *',
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
                              prefixIcon:
                                  const Icon(Icons.location_on_outlined),
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
                                borderSide: const BorderSide(
                                    color: Color(0xFF006FD6), width: 2),
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
                              border: Border.all(
                                  color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Color(0xFF006FD6), size: 16),
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
                              backgroundColor: const Color(0xFF006FD6),
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
                          text: 'Update Service',
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
      final vendorService = Provider.of<VendorService>(context, listen: false);

      // Prepare updated service data
      final updatedData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'availability': _datesController.text.trim() == 'Available',
        'price': double.parse(_priceController.text.trim()),
        'location': _locationController.text.trim(),
        'tags': _amenities.join(','),
        'images': _imageUrlController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      print('Updating service with data: $updatedData');

      await vendorService.updateService(
        widget.service.id,
        updatedData,
        widget.token,
      );

      if (mounted) {
        developer.log('✅ Service updated successfully',
            name: 'EditServicePage');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Service updated successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Go back to the previous page
        Navigator.pop(context);
      }
    } catch (e) {
      developer.log('Error updating service: $e', name: 'EditServicePage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
    _selectedLocation = widget.initialLocation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialLocation == null) {
        _showLocationPrompt();
      }
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
              content: const Text(
                  'Location services are disabled. Please enable them.'),
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
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Location permission is required to use current location.'),
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
          const Icon(Icons.location_on, color: Color(0xFF006FD6)),
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
              target: widget.initialLocation ??
                  const LatLng(7.8731, 80.7718), // Default to Sri Lanka
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
            backgroundColor: const Color(0xFF006FD6),
            foregroundColor: Colors.white,
          ),
          child: const Text('Select'),
        ),
      ],
    );
  }
}
