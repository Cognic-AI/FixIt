import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../../services/vendor_service.dart';
import '../../services/auth_service.dart';
import '../../models/service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class AddServicePage extends StatefulWidget {
  const AddServicePage({super.key});

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
    Provider.of<VendorService>(context, listen: false).loadMyServices();
    developer.log('🏗️ Initializing AddServicePage', name: 'AddServicePage');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Service'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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

              // Location
              CustomTextField(
                controller: _locationController,
                label: 'Location *',
                hintText: 'Enter service location',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter service location';
                  }
                  return null;
                },
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

              // Availability/Dates
              CustomTextField(
                controller: _datesController,
                label: 'Availability',
                hintText: 'e.g., Mon-Fri 9AM-5PM',
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
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        location: _locationController.text.trim(),
        rating: 0.0,
        reviewCount: 0,
        hostId: currentUser.id,
        hostName: currentUser.fullName,
        category: _selectedCategory,
        amenities: _amenities,
        imageUrl: _imageUrlController.text.trim(),
        dates: _datesController.text.trim(),
        active: true,
      );

      final success = await vendorService.addService(service);

      if (success) {
        developer.log('✅ Service added successfully', name: 'AddServicePage');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Failed to add service');
      }
    } catch (e) {
      developer.log('❌ Error adding service: $e', name: 'AddServicePage');
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
        await vendorService.loadMyServices();
      }
    }
  }
}
