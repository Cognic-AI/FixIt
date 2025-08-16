// import 'package:fixit/pages/client/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../models/service.dart';
import '../services/user_service.dart';
import 'client/request_service_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? "";

enum AlertType { success, error, warning, info }

class _CustomAlert extends StatefulWidget {
  final String message;
  final AlertType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  const _CustomAlert({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  @override
  _CustomAlertState createState() => _CustomAlertState();
}

class _CustomAlertState extends State<_CustomAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case AlertType.success:
        return const Color(0xFF10B981);
      case AlertType.error:
        return const Color(0xFFEF4444);
      case AlertType.warning:
        return const Color(0xFFF59E0B);
      case AlertType.info:
        return const Color(0xFF3B82F6);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case AlertType.success:
        return Icons.check_circle_rounded;
      case AlertType.error:
        return Icons.error_rounded;
      case AlertType.warning:
        return Icons.warning_rounded;
      case AlertType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _backgroundColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _icon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.actionLabel != null && widget.onAction != null) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: widget.onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      backgroundColor: Colors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      widget.actionLabel!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _animationController.reverse().then((_) {
                      widget.onDismiss?.call();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.token, required this.uid});

  final String token;
  final String uid;

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(7.8731, 80.7718), // Default position (Sri Lanka)
    zoom: 11.5,
  );

  GoogleMapController? _mapController;
  Position? _currentPosition;
  final TextEditingController _searchController = TextEditingController();
  String _selectedServiceType = 'All';
  bool _isSearchExpanded = false;
  Timer? _searchDebouncer;
  bool _isSearching = false;
  bool _isLoadingServices = true;
  List<Service> _services = [];
  List<Service> _filteredServices = [];
  Set<Marker> _markers = {};
  Map<PolylineId, Polyline> _polylines = {};
  Service? _selectedService;
  
  // Suggestion system
  final ValueNotifier<List<String>> _searchSuggestions = ValueNotifier<List<String>>([]);
  final FocusNode _searchFocusNode = FocusNode();

  final List<String> serviceTypes = [
    'All',
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
    _requestLocationPermission();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      setState(() {
        _isLoadingServices = true;
      });
      
      developer.log('MapPage: Loading services', name: 'MapPage');
      final services = await UserService().loadServices(widget.token);
      
      if (mounted) {
        setState(() {
          _services = services;
          _filteredServices = services; // Initially show all services
          _isLoadingServices = false;
        });
        developer.log('MapPage: Loaded ${_services.length} services',
            name: 'MapPage');

        // Update markers after loading services
        _updateMapMarkers();
        
        // Show success message
        if (services.isNotEmpty) {
          _showCustomAlert(
            message: 'Found ${services.length} services in your area',
            type: AlertType.info,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      developer.log('MapPage: Error loading services: $e', name: 'MapPage');
      if (mounted) {
        setState(() {
          _isLoadingServices = false;
        });
        _showCustomAlert(
          message: 'Failed to load services. Please try again.',
          type: AlertType.error,
          actionLabel: 'RETRY',
          onAction: _loadServices,
        );
      }
    }
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

  void _onSearchChanged(String value) {
    // Cancel previous timer if it exists
    _searchDebouncer?.cancel();

    // Update suggestions without setState to avoid keyboard collapse
    _updateSuggestions(value);

    // Create a new timer that will trigger search after 500ms of no typing
    _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      _searchSuggestions.value = [];
      return;
    }

    List<String> suggestions = [];
    final lowercaseQuery = query.toLowerCase();

    // Priority 1: Exact service title matches
    for (final service in _services) {
      if (service.title.toLowerCase() == lowercaseQuery) {
        suggestions.insert(0, service.title); // Add to the beginning
      }
    }

    // Priority 2: Service titles that start with the query
    for (final service in _services) {
      if (service.title.toLowerCase().startsWith(lowercaseQuery) &&
          service.title.toLowerCase() != lowercaseQuery) {
        if (!suggestions.contains(service.title)) {
          suggestions.add(service.title);
        }
      }
    }

    // Priority 3: Categories that start with the query
    for (final category in serviceTypes) {
      if (category != 'All' && 
          category.toLowerCase().startsWith(lowercaseQuery)) {
        final categoryLabel = '${category[0].toUpperCase()}${category.substring(1)} Services';
        if (!suggestions.contains(categoryLabel)) {
          suggestions.add(categoryLabel);
        }
      }
    }

    // Priority 4: Service titles that contain the query
    for (final service in _services) {
      if (service.title.toLowerCase().contains(lowercaseQuery) &&
          !service.title.toLowerCase().startsWith(lowercaseQuery) &&
          service.title.toLowerCase() != lowercaseQuery) {
        if (!suggestions.contains(service.title)) {
          suggestions.add(service.title);
        }
      }
    }

    // Priority 5: Service descriptions that contain the query
    for (final service in _services) {
      if (service.description.toLowerCase().contains(lowercaseQuery) &&
          !service.title.toLowerCase().contains(lowercaseQuery)) {
        if (!suggestions.contains(service.title)) {
          suggestions.add(service.title);
        }
      }
    }

    // Limit to 6 suggestions and update ValueNotifier
    _searchSuggestions.value = suggestions.take(6).toList();
  }

  void _selectSuggestion(String suggestion) {
    // Check if it's a category suggestion
    if (suggestion.endsWith(' Services')) {
      final categoryName = suggestion.replaceAll(' Services', '').toLowerCase();
      setState(() {
        _selectedServiceType = categoryName;
        _searchController.clear();
        _searchFocusNode.unfocus();
      });
    } else {
      // It's a service title - set it as the search query and reset category to 'All'
      setState(() {
        _selectedServiceType = 'All'; // Reset category when searching for specific service
        _searchController.text = suggestion;
        _searchFocusNode.unfocus();
      });
    }
    
    // Clear suggestions and perform search
    _searchSuggestions.value = [];
    _performSearch();
  }

  void _performSearch() {
    String searchQuery = _searchController.text.trim();
    String serviceType = _selectedServiceType;

    // Set searching state
    setState(() {
      _isSearching = true;
    });

    developer.log(
        'MapPage: Searching for: "$searchQuery" in category: "$serviceType"',
        name: 'MapPage');

    // Perform the actual search filtering
    List<Service> filteredResults = _services.where((service) {
      // First check for exact title match (highest priority)
      if (searchQuery.isNotEmpty && 
          service.title.toLowerCase() == searchQuery.toLowerCase()) {
        return true;
      }

      // Then check for partial title match with category filter
      final matchesSearch = searchQuery.isEmpty ||
          service.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          service.description.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesCategory = serviceType == 'All' ||
          service.category.toLowerCase() == serviceType.toLowerCase();

      // Note: tags field might be a string. need to handle it appropriately
      final serviceTags = service.tags
          .toLowerCase()
          .split(',')
          .map((tag) => tag.trim())
          .toList();
      final matchesTags = searchQuery.isEmpty ||
          serviceTags.any((tag) => tag.contains(searchQuery.toLowerCase()));

      return matchesSearch && matchesCategory && (searchQuery.isEmpty || matchesTags);
    }).toList();

    // If we found an exact title match, prioritize it
    if (searchQuery.isNotEmpty && filteredResults.isNotEmpty) {
      final exactMatches = filteredResults
          .where((service) => 
              service.title.toLowerCase() == searchQuery.toLowerCase())
          .toList();
      
      if (exactMatches.isNotEmpty) {
        // If we have exact matches, show only those unless user has a specific category filter
        if (serviceType == 'All') {
          filteredResults = exactMatches;
        }
      }
    }

    // Simulate search delay 
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _filteredServices = filteredResults;
          _isSearching = false;
        });
        developer.log(
            'MapPage: Search completed. Found ${_filteredServices.length} services for "$searchQuery"',
            name: 'MapPage');

        // Update map markers with filtered services
        _updateMapMarkers();

        // Show feedback for specific service searches
        if (searchQuery.isNotEmpty && filteredResults.length == 1) {
          final service = filteredResults.first;
          if (service.title.toLowerCase() == searchQuery.toLowerCase()) {
            _showCustomAlert(
              message: 'Found "${service.title}" - Check the map!',
              type: AlertType.success,
              duration: const Duration(seconds: 3),
            );
            
            // Zoom to the specific service if location is available
            final coordinates = _parseLocationString(service.location);
            if (coordinates != null && _mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(coordinates, 15.0),
              );
            }
          }
        }
      }
    });
  }

  void _updateMapMarkers() {
    Set<Marker> newMarkers = {};

    for (int i = 0; i < _filteredServices.length; i++) {
      final service = _filteredServices[i];
      final coordinates = _parseLocationString(service.location);

      if (coordinates != null) {
        final marker = Marker(
          markerId: MarkerId(service.id),
          position: coordinates,
          onTap: () => _onMarkerTap(service),
          icon: _getMarkerIcon(service.category),
        );
        newMarkers.add(marker);
      }
    }

    setState(() {
      _markers = newMarkers;
    });

    developer.log('MapPage: Updated map with ${_markers.length} markers',
        name: 'MapPage');

    // Removed `_fitCameraToMarkers` to prevent overriding the user's current location focus
  }

  LatLng? _parseLocationString(String locationStr) {
    try {
      // Handle different location formats
      if (locationStr.isEmpty) return null;

      // Remove any whitespace
      locationStr = locationStr.trim();

      // Format 1: "lat,lng" 
      if (locationStr.contains(',')) {
        final parts = locationStr.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null &&
              lng != null &&
              lat >= -90 &&
              lat <= 90 &&
              lng >= -180 &&
              lng <= 180) {
            return LatLng(lat, lng);
          }
        }
      }

      // Format 2: "lat lng" (space separated)
      if (locationStr.contains(' ')) {
        final parts = locationStr.split(' ');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null &&
              lng != null &&
              lat >= -90 &&
              lat <= 90 &&
              lng >= -180 &&
              lng <= 180) {
            return LatLng(lat, lng);
          }
        }
      }

      // Format 3: For demonstration, if location is a city name in Sri Lanka
      final cityCoordinates = _getCityCoordinates(locationStr.toLowerCase());
      if (cityCoordinates != null) {
        return cityCoordinates;
      }

      // If no valid coordinates found, log and return null
      developer.log('MapPage: Could not parse location: $locationStr',
          name: 'MapPage');
      return null;
    } catch (e) {
      developer.log('MapPage: Error parsing location "$locationStr": $e',
          name: 'MapPage');
      return null;
    }
  }

  LatLng? _getCityCoordinates(String cityName) {
    // Basic mapping of Sri Lankan cities to coordinates
    final Map<String, LatLng> cityMap = {
      'colombo': const LatLng(6.9271, 79.8612),
      'kandy': const LatLng(7.2906, 80.6337),
      'galle': const LatLng(6.0535, 80.2210),
      'jaffna': const LatLng(9.6615, 80.0255),
      'negombo': const LatLng(7.2083, 79.8358),
      'matara': const LatLng(5.9549, 80.5550),
      'kurunegala': const LatLng(7.4818, 80.3609),
      'anuradhapura': const LatLng(8.3114, 80.4037),
      'batticaloa': const LatLng(7.7170, 81.7000),
      'trincomalee': const LatLng(8.5874, 81.2152),
    };

    return cityMap[cityName];
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

  BitmapDescriptor _getMarkerIcon(String category) {
    // Return different marker icons based on service category
    switch (category.toLowerCase()) {
      case 'cleaning':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'plumbing':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      case 'electrical':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow);
      case 'painting':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'gardening':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange);
      case 'handyman':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case 'moving':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueMagenta);
      case 'tutoring':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet);
      case 'beauty':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
      case 'photography':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  IconData _getCategoryIcon(String category) {
    // Return different icons based on service category
    switch (category.toLowerCase()) {
      case 'cleaning':
        return Icons.cleaning_services_rounded;
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'electrical':
        return Icons.electrical_services_rounded;
      case 'painting':
        return Icons.format_paint_rounded;
      case 'gardening':
        return Icons.yard_rounded;
      case 'handyman':
        return Icons.handyman_rounded;
      case 'moving':
        return Icons.local_shipping_rounded;
      case 'tutoring':
        return Icons.school_rounded;
      case 'beauty':
        return Icons.face_rounded;
      case 'photography':
        return Icons.camera_alt_rounded;
      case 'catering':
        return Icons.restaurant_rounded;
      default:
        return Icons.miscellaneous_services_rounded;
    }
  }

  void _showCustomAlert({
    required String message,
    required AlertType type,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!mounted) return;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 60,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _CustomAlert(
            message: message,
            type: type,
            actionLabel: actionLabel,
            onAction: onAction,
            onDismiss: () => overlayEntry.remove(),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after duration
    Timer(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void _onMarkerTap(Service service) {
    // Handle marker tap - show service details
    developer.log('MapPage: Marker tapped for service: ${service.title}',
        name: 'MapPage');

    // ToDo: Implement a bottom sheet or dialog to show service details
    _showServiceBottomSheet(service);
  }

  void _showServiceBottomSheet(Service service) {
    // Calculate distance for the bottom sheet
    final coordinates = _parseLocationString(service.location);
    final distance = coordinates != null
        ? _calculateDistance(coordinates)
        : 'Distance unknown';

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
                    service.title,
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
              service.category.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              service.description,
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Price, location and distance
            Row(
              children: [
                const Text(
                  'LKR',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  service.price.toStringAsFixed(2),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    service.location,
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
                    // Expanded(
                    //   child: OutlinedButton.icon(
                    //     onPressed: () {
                    //       // Handle contact action
                    //       Navigator.push(context, ChatPage(conversation: conversation, currentUserId: currentUserId, token: token, request: request));
                    //     },
                    //     icon: const Icon(Icons.message),
                    //     label: const Text('Message'),
                    //     style: OutlinedButton.styleFrom(
                    //       foregroundColor: const Color(0xFF2563EB),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Handle directions action
                          Navigator.pop(context);
                          _showDirections(service);
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
                      // Navigate to request service page
                      Navigator.pop(context);
                      _navigateToRequestService(service);
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

  int get searchResultsCount => _filteredServices.length;

  Future<void> _refreshServices() async {
    await _loadServices();
    _performSearch(); // Re-apply current search after refresh
  }

  void _onServiceTypeChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedServiceType = newValue;
      });
      // Trigger search with the new service type
      _performSearch();
    }
  }

  Future<void> _showDirections(Service service) async {
    if (_currentPosition == null) {
      if (mounted) {
        _showCustomAlert(
          message: 'Please enable location services to get directions',
          type: AlertType.warning,
          actionLabel: 'RETRY',
          onAction: _requestLocationPermission,
        );
      }
      return;
    }

    final serviceCoordinates = _parseLocationString(service.location);
    if (serviceCoordinates == null) {
      if (mounted) {
        _showCustomAlert(
          message: 'Service location is not available',
          type: AlertType.error,
        );
      }
      return;
    }

    setState(() {
      _selectedService = service;
    });

    try {
      final coordinates = await _getPolyLinePoints(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        serviceCoordinates,
      );

      if (coordinates.isNotEmpty) {
        _generatePolylineFromPoints(coordinates);
        _fitCameraToRoute(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          serviceCoordinates,
        );

        if (mounted) {
          _showCustomAlert(
            message: 'Route to ${service.title} is now displayed on the map',
            type: AlertType.success,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        if (mounted) {
          _showCustomAlert(
            message: 'Unable to find a route to this location',
            type: AlertType.warning,
          );
        }
      }
    } catch (e) {
      developer.log('Error getting directions: $e', name: 'MapPage');
      if (mounted) {
        _showCustomAlert(
          message: 'Failed to get directions. Please try again.',
          type: AlertType.error,
          actionLabel: 'RETRY',
          onAction: () => _showDirections(service),
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
            name: 'MapPage');
      }
    } catch (e) {
      developer.log('Error getting polyline points: $e', name: 'MapPage');
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

  void _fitCameraToMarkers() {
    if (_mapController == null || _markers.isEmpty) return;

    // Calculate bounds that include all markers
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;
      
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    // Add padding
    const padding = 0.02;
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80.0));
  }

  void _clearRoute() {
    setState(() {
      _polylines.clear();
      _selectedService = null;
    });
  }

  void _navigateToRequestService(Service service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestServicePage(
          token: widget.token,
          uid: widget.uid,
          category: service.category,
          title: service.title,
          price: service.price,
          service: service,
        ),
      ),
    );
  }

  void _toggleSearchExpanded() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
    });
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Search icon or loading indicator
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isSearching
                            ? Container(
                                key: const ValueKey('loading'),
                                width: 24,
                                height: 24,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                ),
                              )
                            : const Icon(
                                Icons.search_rounded,
                                key: ValueKey('search'),
                                color: Color(0xFF6B7280),
                                size: 24,
                              ),
                      ),
                      const SizedBox(width: 12),

                      // Search text field
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search for services near you...',
                            hintStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),

                      // Clear search button
                      if (_searchController.text.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _searchSuggestions.value = [];
                            _performSearch();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],

                      // Service type chip
                      if (_selectedServiceType != 'All') ...[
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(_selectedServiceType),
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedServiceType.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedServiceType = 'All';
                                  });
                                  _performSearch();
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Filter toggle button
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleSearchExpanded,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isSearchExpanded 
                              ? const Color(0xFF2563EB).withOpacity(0.1)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isSearchExpanded 
                                ? const Color(0xFF2563EB).withOpacity(0.3)
                                : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: _isSearchExpanded ? 0.5 : 0,
                          child: Icon(
                            Icons.tune_rounded,
                            color: _isSearchExpanded 
                                ? const Color(0xFF2563EB)
                                : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search suggestions
          ValueListenableBuilder<List<String>>(
            valueListenable: _searchSuggestions,
            builder: (context, suggestions, child) {
              if (suggestions.isEmpty) return const SizedBox.shrink();
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey[200]!,
                            Colors.grey[100]!,
                            Colors.grey[200]!,
                          ],
                        ),
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = suggestions[index];
                          final isCategory = suggestion.endsWith(' Services');
                          
                          // Check if it's an exact match with a service
                          final matchingService = _services.firstWhere(
                            (service) => service.title.toLowerCase() == suggestion.toLowerCase(),
                            orElse: () => _services.first, // Default fallback
                          );
                          final isExactService = matchingService.title.toLowerCase() == suggestion.toLowerCase();
                          
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _selectSuggestion(suggestion),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20, 
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isCategory 
                                            ? const Color(0xFF2563EB).withOpacity(0.1)
                                            : isExactService 
                                                ? const Color(0xFF10B981).withOpacity(0.1)
                                                : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isCategory 
                                            ? Icons.category_rounded
                                            : isExactService
                                                ? Icons.business_rounded
                                                : Icons.search_rounded,
                                        size: 16,
                                        color: isCategory 
                                            ? const Color(0xFF2563EB)
                                            : isExactService
                                                ? const Color(0xFF10B981)
                                                : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildHighlightedText(
                                            suggestion,
                                            _searchController.text,
                                          ),
                                          if (isExactService) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '${matchingService.category.toUpperCase()} • LKR ${matchingService.price.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ] else if (isCategory) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'Browse all services in this category',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isCategory 
                                            ? const Color(0xFF2563EB).withOpacity(0.1)
                                            : isExactService
                                                ? const Color(0xFF10B981).withOpacity(0.1)
                                                : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        isCategory ? 'CATEGORY' : isExactService ? 'SERVICE' : 'SEARCH',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: isCategory 
                                              ? const Color(0xFF2563EB)
                                              : isExactService
                                                  ? const Color(0xFF10B981)
                                                  : Colors.grey[600],
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Enhanced service types dropdown
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isSearchExpanded ? null : 0,
            child: _isSearchExpanded ? Column(
              children: [
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey[200]!,
                        Colors.grey[100]!,
                        Colors.grey[200]!,
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 18,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Filter by Category',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: serviceTypes.map((serviceType) {
                          final isSelected = _selectedServiceType == serviceType;
                          final isAll = serviceType == 'All';
                          
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _onServiceTypeChanged(serviceType);
                                _toggleSearchExpanded();
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16, 
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? const Color(0xFF2563EB)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected 
                                        ? const Color(0xFF2563EB)
                                        : Colors.grey[200]!,
                                    width: 1.5,
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ] : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isAll) ...[
                                      Icon(
                                        _getCategoryIcon(serviceType),
                                        size: 16,
                                        color: isSelected 
                                            ? Colors.white
                                            : const Color(0xFF2563EB),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      isAll ? 'All Services' : serviceType.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected 
                                            ? Colors.white
                                            : Colors.grey[700],
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            scrollGesturesEnabled:
                !_isSearchExpanded, // Disable scroll when dropdown is open
            zoomGesturesEnabled:
                !_isSearchExpanded, // Disable zoom when dropdown is open
            tiltGesturesEnabled:
                !_isSearchExpanded, // Disable tilt when dropdown is open
            rotateGesturesEnabled:
                !_isSearchExpanded, // Disable rotate when dropdown is open
            initialCameraPosition: _initialCameraPosition,
            markers: _markers, // Add the markers to the map
            polylines: Set<Polyline>.of(
                _polylines.values), // Add the polylines to the map
            onMapCreated: (controller) {
              _mapController = controller;
              _moveCameraToCurrentLocation(); // Try moving camera when map is created
            },
          ),

          // Search overlay
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _buildSearchBar(),
                // Enhanced results counter
                if (!_isSearchExpanded)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isLoadingServices
                        ? Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Loading services...',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: searchResultsCount > 0 
                                ? const Color(0xFF2563EB).withOpacity(0.1)
                                : _services.isEmpty
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            searchResultsCount > 0 
                                ? Icons.location_on_rounded
                                : _services.isEmpty 
                                    ? Icons.error_outline_rounded
                                    : Icons.search_off_rounded,
                            size: 16,
                            color: searchResultsCount > 0 
                                ? const Color(0xFF2563EB)
                                : _services.isEmpty
                                    ? Colors.orange
                                    : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _services.isEmpty
                                    ? 'No services available'
                                    : searchResultsCount > 0 
                                        ? '$searchResultsCount ${searchResultsCount == 1 ? 'service' : 'services'} found'
                                        : 'No services match your search',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (_selectedServiceType != 'All' && searchResultsCount > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'in ${_selectedServiceType.toUpperCase()}',
                                  style: TextStyle(
                                    color: const Color(0xFF2563EB),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                              ] else if (searchResultsCount == 0 && _services.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Try adjusting your search or filter',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _refreshServices,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                            if (searchResultsCount > 0) ...[
                              const SizedBox(width: 4),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    // Fit camera to show all markers
                                    if (_markers.isNotEmpty) {
                                      _fitCameraToMarkers();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.center_focus_strong_rounded,
                                      size: 18,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      // Enhanced clear route button (only shown when there's an active route)
      floatingActionButton: _polylines.isNotEmpty
          ? Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton.extended(
                onPressed: _clearRoute,
                icon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                  ),
                ),
                label: Text(
                  _selectedService != null
                      ? 'Clear Route to ${_selectedService!.title.length > 15 ? '${_selectedService!.title.substring(0, 15)}...' : _selectedService!.title}'
                      : 'Clear Route',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 8,
                extendedPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(text);
    }

    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    final int index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(text);
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        children: [
          if (index > 0)
            TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
          if (index + query.length < text.length)
            TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer?.cancel();
    _searchSuggestions.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
