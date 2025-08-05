import 'package:fixit/pages/client/service_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.token});

  final String token;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _hasChanges = false;
  LatLng? _selectedLocation;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupChangeListeners();
  }

  void _setupChangeListeners() {
    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _locationController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _locationController.text = user.location;
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_onFieldChanged);
    _lastNameController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _locationController.removeListener(_onFieldChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
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
          _hasChanges = true;
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

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          return await _showUnsavedChangesDialog();
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
          ],
        ),
        body: Consumer<AuthService>(
          builder: (context, authService, child) {
            final user = authService.currentUser;

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Picture Section
                    _buildProfilePictureSection(user),
                    const SizedBox(height: 32),

                    // Personal Information Section
                    _buildSectionHeader('Personal Information'),
                    const SizedBox(height: 16),
                    _buildPersonalInfoFields(),

                    const SizedBox(height: 32),

                    // Contact Information Section
                    _buildSectionHeader('Contact Information'),
                    const SizedBox(height: 16),
                    _buildContactInfoFields(),

                    const SizedBox(height: 32),

                    // Location Section
                    _buildSectionHeader('Location'),
                    const SizedBox(height: 16),
                    _buildLocationField(),

                    const SizedBox(height: 40),

                    // Save Button (only show if not in app bar)
                    if (!_hasChanges) _buildSaveButton(),

                    const SizedBox(height: 24),

                    // Additional Options
                    _buildAdditionalOptions(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
                'You have unsaved changes. Are you sure you want to leave?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection(dynamic user) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF2563EB).withOpacity(0.2),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                  child: user?.profileImageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user!.profileImageUrl!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                user.firstName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          user?.firstName[0].toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _changeProfilePicture,
                    icon: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 20),
                    padding: const EdgeInsets.all(8),
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name *',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF2563EB), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Required';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF2563EB), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Required';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactInfoFields() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            suffixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
          ),
          enabled: false,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            hintText: '+1 (555) 123-4567',
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\(\)\+]')),
          ],
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(value)) {
                return 'Please enter a valid phone number';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Location *',
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: IconButton(
              icon: const Icon(Icons.map_outlined),
              onPressed: _openMapDialog,
              tooltip: 'Select on map',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            errorText: _locationError,
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter your location';
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
              const Icon(Icons.info_outline,
                  color: Color(0xFF2563EB), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This location will be shared with vendors after a service is requested. You can set a different location for specific requests.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildAdditionalOptions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock_outline, color: Color(0xFF2563EB)),
            ),
            title: const Text('Change Password'),
            subtitle: const Text('Update your account password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePassword,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history, color: Color(0xFF2563EB)),
            ),
            title: const Text('Service History'),
            subtitle: const Text('View your past service requests'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _serviceHistory,
          ),
        ],
      ),
    );
  }

  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Change Profile Picture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('Camera');
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('Gallery');
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.person_remove,
                  label: 'Remove',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('Remove Picture');
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2563EB),
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            const Text('Coming Soon'),
          ],
        ),
        content: Text(
            '$feature functionality will be available in the next update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fix the errors above');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement profile update in AuthService
      developer.log('💾 Saving profile changes', name: 'EditProfilePage');

      // Simulate API call with realistic delay
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _hasChanges = false;
        });

        _showSuccessSnackBar('Profile updated successfully!');

        // Navigate back after a short delay to show the success message
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      developer.log('❌ Error updating profile: $e', name: 'EditProfilePage');
      _showErrorSnackBar('Error updating profile. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changePassword() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.lock_outline, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  const Text('Change Password'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: oldPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock_open_outlined),
                      ),
                      obscureText: true,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordController,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline),
                        helperText:
                            'At least 8 characters with letters and numbers',
                      ),
                      obscureText: true,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.verified_user_outlined),
                      ),
                      obscureText: true,
                      enabled: !isLoading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          // Validate input
                          if (oldPasswordController.text.isEmpty ||
                              newPasswordController.text.isEmpty ||
                              confirmPasswordController.text.isEmpty) {
                            setState(() {
                              errorMessage = 'All fields are required.';
                            });
                            return;
                          }

                          if (newPasswordController.text.length < 8) {
                            setState(() {
                              errorMessage =
                                  'New password must be at least 8 characters long.';
                            });
                            return;
                          }

                          if (newPasswordController.text !=
                              confirmPasswordController.text) {
                            setState(() {
                              errorMessage = 'New passwords do not match.';
                            });
                            return;
                          }

                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            await AuthService().resetPassword(
                              oldPasswordController.text,
                              newPasswordController.text,
                              widget.token,
                            );
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              errorMessage =
                                  'Failed to change password. Please check your current password and try again.';
                            });
                            return;
                          }

                          // If successful:
                          Navigator.pop(context);
                          _showSuccessSnackBar(
                              'Password changed successfully.');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _serviceHistory() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ServiceHistoryPage(
                token: widget.token,
                clientId: AuthService().currentUser?.id ?? '')));
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
        content: const Text('How would you like to set your location?'),
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
          const Icon(Icons.location_on, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          const Text('Select Location'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
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
                      infoWindow: const InfoWindow(
                        title: 'Selected Location',
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
