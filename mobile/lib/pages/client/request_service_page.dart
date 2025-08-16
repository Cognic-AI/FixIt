import 'package:fixit/models/service.dart';
import 'package:fixit/services/messaging_service.dart';
import 'package:fixit/services/user_service.dart';
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
    required this.service,
  });
  final String uid;
  final String token;
  final String category;
  final String title;
  final double price;
  final Service service;

  @override
  State<RequestServicePage> createState() => _RequestServicePageState();
}

class _RequestServicePageState extends State<RequestServicePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  LatLng? _selectedLocation;
  String _serviceType = 'on-site'; // 'on-site' or 'visit-provider'

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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cleaning':
        return Icons.cleaning_services;
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'painting':
        return Icons.format_paint;
      case 'gardening':
        return Icons.grass;
      case 'handyman':
        return Icons.build;
      case 'moving':
        return Icons.moving;
      case 'tutoring':
        return Icons.school;
      case 'beauty':
        return Icons.face;
      case 'photography':
        return Icons.camera_alt;
      case 'catering':
        return Icons.restaurant;
      default:
        return Icons.handyman;
    }
  }

  void _loadUserLocation() {
    // Only load user location for on-site services
    if (_serviceType != 'on-site') return;

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
          developer.log('Could not parse user location coordinates: $e',
              name: 'RequestServicePage');
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
        _locationController.text =
            "${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}";
      });
    }
  }

  void _showLocationOptions() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text(
              'Select Location',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user?.location.isNotEmpty == true)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF2563EB).withOpacity(0.3)),
                  color: const Color(0xFF2563EB).withOpacity(0.05),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_pin_circle,
                        color: Color(0xFF2563EB), size: 20),
                  ),
                  title: const Text('Profile Location',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(user!.location,
                      style: TextStyle(color: Colors.grey[600])),
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
                          developer.log('Could not parse coordinates: $e',
                              name: 'RequestServicePage');
                        }
                      }
                    });
                  },
                ),
              ),
            if (user?.location.isEmpty != false)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.grey.shade50,
                ),
                child: const ListTile(
                  leading: Icon(Icons.person_pin_circle_outlined,
                      color: Colors.grey),
                  title: Text('Profile Location',
                      style: TextStyle(color: Colors.grey)),
                  subtitle: Text('No location set in profile',
                      style: TextStyle(color: Colors.grey)),
                  enabled: false,
                ),
              ),
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                color: const Color(0xFF10B981).withOpacity(0.05),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.my_location,
                      color: Color(0xFF10B981), size: 20),
                ),
                title: const Text('Current Location',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('Use your GPS location',
                    style: TextStyle(color: Colors.grey[600])),
                onTap: () {
                  Navigator.pop(context);
                  _useCurrentLocation();
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                color: const Color(0xFF7C3AED).withOpacity(0.05),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.map, color: Color(0xFF7C3AED), size: 20),
                ),
                title: const Text('Select on Map',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('Choose a specific location',
                    style: TextStyle(color: Colors.grey[600])),
                onTap: () {
                  Navigator.pop(context);
                  _openMapDialog();
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
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
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
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
        _locationController.text =
            "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Current location selected successfully!')),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      developer.log('Error getting current location: $e',
          name: 'RequestServicePage');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to get current location. Please try again.')),
      );
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF2563EB)),
                SizedBox(width: 20),
                Text('Submitting your request...'),
              ],
            ),
          ),
        ),
      );

      // final requestData = {
      //   'serviceId': widget.service.id,
      //   'clientId': widget.uid,
      //   'location': widget.service.location,
      //   'providerId': widget.service.providerId,
      //   'clientLocation': _selectedLocation != null
      //       ? "${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}"
      //       : "",
      //   'note': _descriptionController.text.isNotEmpty
      //       ? _descriptionController.text
      //       : 'No additional description provided',
      //   'budget': _budgetController.text.isNotEmpty
      //       ? "\$${_budgetController.text}"
      //       : 'Budget not specified',
      //   'serviceType': _serviceType,
      // };

      try {
        // // Simulate API call with delay
        // await Future.delayed(const Duration(seconds: 2));
        // developer.log('Submitting request: $requestData',
        //     name: 'RequestServicePage');
        String _id = await UserService().createRequest(
            token: widget.token,
            serviceId: widget.service.id,
            clientId: widget.uid,
            providerId: widget.service.providerId,
            location: widget.service.location,
            note: _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
            budget: _budgetController.text.isNotEmpty
                ? double.tryParse(_budgetController.text)
                : null,
            serviceType: _serviceType,
            clientLocation: _selectedLocation != null
                ? "${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}"
                : "");

        await MessagingService().sendMessage(
          conversationId: _id,
          senderId: widget.uid,
          senderName: "System",
          senderType: 'client',
          receiverId: widget.service.providerId,
          receiverName: "System",
          content: "New Request has been sent",
          token: widget.token,
        );

        Navigator.pop(context); // Close loading dialog

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Request Submitted!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _serviceType == 'on-site'
                      ? 'Your service request has been submitted successfully. The service provider will contact you to arrange a visit to your location.'
                      : 'Your service request has been submitted successfully. The service provider will contact you with their location details and availability.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close success dialog
                    Navigator.pop(context); // Go back to previous screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        developer.log('Error submitting request: $e',
            name: 'RequestServicePage');

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Submission Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Failed to submit your service request. Please check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Request Service',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Service Details Header Card
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getCategoryIcon(widget.category),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.category.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'LKR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Starting Price: ',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            'LKR ${widget.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Form Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Service Type Selection
                    const Text(
                      'Service Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: const Row(
                              children: [
                                Icon(Icons.home_repair_service,
                                    color: Color(0xFF2563EB), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'On-Site Service',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            subtitle: const Text(
                              'Service provider comes to your location',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            value: 'on-site',
                            groupValue: _serviceType,
                            activeColor: const Color(0xFF2563EB),
                            onChanged: (value) {
                              setState(() {
                                _serviceType = value!;
                                if (_serviceType == 'on-site') {
                                  _loadUserLocation();
                                } else {
                                  // Clear location data for visit-provider services
                                  _locationController.clear();
                                  _selectedLocation = null;
                                }
                              });
                            },
                          ),
                          Divider(height: 1, color: Colors.grey.shade300),
                          RadioListTile<String>(
                            title: const Row(
                              children: [
                                Icon(Icons.store,
                                    color: Color(0xFF10B981), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Visit Provider',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            subtitle: const Text(
                              'You visit the service provider\'s location',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            value: 'visit-provider',
                            groupValue: _serviceType,
                            activeColor: const Color(0xFF10B981),
                            onChanged: (value) {
                              setState(() {
                                _serviceType = value!;
                                if (_serviceType == 'on-site') {
                                  _loadUserLocation();
                                } else {
                                  // Clear location data for visit-provider services
                                  _locationController.clear();
                                  _selectedLocation = null;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Location Field with improved design (only show if on-site service)
                    if (_serviceType == 'on-site') ...[
                      const Text(
                        'Service Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          color: Colors.white,
                        ),
                        child: TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            labelText: 'Where do you need the service?',
                            hintText: 'Select your location',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            prefixIcon: const Icon(Icons.location_on,
                                color: Color(0xFF2563EB)),
                            suffixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.map,
                                    color: Colors.white, size: 20),
                                onPressed: _showLocationOptions,
                              ),
                            ),
                            labelStyle: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          readOnly: true,
                          validator: (value) {
                            if (_serviceType == 'on-site' &&
                                (value?.isEmpty ?? true)) {
                              return 'Please select a location for the service';
                            }
                            return null;
                          },
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Description Field
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        color: Colors.white,
                      ),
                      child: TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Additional Details',
                          hintText: 'Tell us more about what you need...',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                          prefixIcon:
                              Icon(Icons.description, color: Color(0xFF2563EB)),
                          labelStyle: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        maxLines: 4,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Budget Field
                    const Text(
                      'Budget (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        color: Colors.white,
                      ),
                      child: TextFormField(
                        controller: _budgetController,
                        decoration: const InputDecoration(
                          labelText: 'Enter your budget',
                          hintText: 'Enter your budget in LKR',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                          prefixIcon:
                              Icon(Icons.attach_money, color: Color(0xFF2563EB)),
                          labelStyle: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Submit Request',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
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
    try {
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
        _currentLocation = LatLng(position.latitude, position.longitude);
        if (_selectedLocation == null) {
          _selectedLocation = _currentLocation;
        }
      });

      // Pan the map to the current location
      if (_mapController != null && _currentLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentLocation!,
              zoom: 15.0,
            ),
          ),
        );
      }
    } catch (e) {
      developer.log('Error getting current location in map: $e',
          name: 'MapDialog');
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
            // Pan to current location if available, otherwise get current location
            if (_currentLocation != null) {
              _mapController!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: _currentLocation!,
                    zoom: 15.0,
                  ),
                ),
              );
            } else {
              // Trigger getting current location which will then pan the map
              _getCurrentLocation();
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
