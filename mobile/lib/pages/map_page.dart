import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../models/service.dart';
import '../services/user_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.token});

  final String token;

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
  List<Service> _services = [];
  List<Service> _filteredServices = [];
  Set<Marker> _markers = {};

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
      developer.log('🗺️ MapPage: Loading services', name: 'MapPage');
      final services = await UserService().loadServices(widget.token);
      setState(() {
        _services = services;
        _filteredServices = services; // Initially show all services
      });
      developer.log('🗺️ MapPage: Loaded ${_services.length} services', name: 'MapPage');
      
      // Update markers after loading services
      _updateMapMarkers();
    } catch (e) {
      developer.log('🗺️ MapPage: Error loading services: $e', name: 'MapPage');
      // Handle error appropriately
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
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
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
    
    // Create a new timer that will trigger search after 500ms of no typing
    _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
    
    setState(() {});
  }

  void _performSearch() {
    String searchQuery = _searchController.text.trim();
    String serviceType = _selectedServiceType;
    
    // Set searching state
    setState(() {
      _isSearching = true;
    });
    
    developer.log('🔍 MapPage: Searching for: "$searchQuery" in category: "$serviceType"', name: 'MapPage');
    
    // Perform the actual search filtering
    List<Service> filteredResults = _services.where((service) {
      // Apply search filters similar to search page
      final matchesSearch = searchQuery.isEmpty ||
          service.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          service.description.toLowerCase().contains(searchQuery.toLowerCase());
      
      final matchesCategory = serviceType == 'All' || service.category.toLowerCase() == serviceType.toLowerCase();
      
      // Note: tags field might be a string, so we need to handle it appropriately
      final serviceTags = service.tags.toLowerCase().split(',').map((tag) => tag.trim()).toList();
      final matchesTags = searchQuery.isEmpty ||
          serviceTags.any((tag) => tag.contains(searchQuery.toLowerCase()));

      return matchesSearch && matchesCategory && (searchQuery.isEmpty || matchesTags);
    }).toList();
    
    // Simulate search delay (you can remove this in production)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _filteredServices = filteredResults;
          _isSearching = false;
        });
        developer.log('MapPage: Search completed. Found ${_filteredServices.length} services', name: 'MapPage');
        
        // TODO: Update map markers with filtered services
        _updateMapMarkers();
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
          infoWindow: InfoWindow(
            title: service.title,
            snippet: '${service.category.toUpperCase()} - €${service.price.toStringAsFixed(2)}',
            onTap: () => _onMarkerTap(service),
          ),
          icon: _getMarkerIcon(service.category),
        );
        newMarkers.add(marker);
      }
    }
    
    setState(() {
      _markers = newMarkers;
    });
    
    developer.log('🗺️ MapPage: Updated map with ${_markers.length} markers', name: 'MapPage');
    
    // Optionally adjust camera to show all markers
    if (_markers.isNotEmpty) {
      _fitCameraToMarkers();
    }
  }

  LatLng? _parseLocationString(String locationStr) {
    try {
      // Handle different location formats
      if (locationStr.isEmpty) return null;
      
      // Remove any whitespace
      locationStr = locationStr.trim();
      
      // Format 1: "lat,lng" (e.g., "6.9271,79.8612")
      if (locationStr.contains(',')) {
        final parts = locationStr.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null && 
              lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
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
          if (lat != null && lng != null && 
              lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
            return LatLng(lat, lng);
          }
        }
      }
      
      // Format 3: For demonstration, if location is a city name in Sri Lanka
      // You can add a mapping of city names to coordinates
      final cityCoordinates = _getCityCoordinates(locationStr.toLowerCase());
      if (cityCoordinates != null) {
        return cityCoordinates;
      }
      
      // If no valid coordinates found, log and return null
      developer.log('⚠️ MapPage: Could not parse location: $locationStr', name: 'MapPage');
      return null;
      
    } catch (e) {
      developer.log('⚠️ MapPage: Error parsing location "$locationStr": $e', name: 'MapPage');
      return null;
    }
  }

  LatLng? _getCityCoordinates(String cityName) {
    // Basic mapping of Sri Lankan cities to coordinates
    // You can expand this or use a proper geocoding service
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

  BitmapDescriptor _getMarkerIcon(String category) {
    // Return different marker icons based on service category
    // For now, use default marker, but you can customize this
    switch (category.toLowerCase()) {
      case 'cleaning':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'plumbing':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      case 'electrical':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case 'painting':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'gardening':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'handyman':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case 'moving':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
      case 'tutoring':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case 'beauty':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
      case 'photography':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  void _onMarkerTap(Service service) {
    // Handle marker tap - show service details
    developer.log('🗺️ MapPage: Marker tapped for service: ${service.title}', name: 'MapPage');
    
    // You can implement a bottom sheet or dialog to show service details
    _showServiceBottomSheet(service);
  }

  void _showServiceBottomSheet(Service service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.4,
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
            
            // Price and location
            Row(
              children: [
                const Icon(Icons.euro, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  '${service.price.toStringAsFixed(2)}',
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
            
            const Spacer(),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Handle contact action
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Handle view details action
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
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

  void _fitCameraToMarkers() {
    if (_markers.isEmpty || _mapController == null) return;
    
    // Calculate bounds to fit all markers
    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;
    
    for (final marker in _markers) {
      minLat = minLat < marker.position.latitude ? minLat : marker.position.latitude;
      maxLat = maxLat > marker.position.latitude ? maxLat : marker.position.latitude;
      minLng = minLng < marker.position.longitude ? minLng : marker.position.longitude;
      maxLng = maxLng > marker.position.longitude ? maxLng : marker.position.longitude;
    }
    
    // Add some padding
    const padding = 0.01;
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );
    
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
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

  void _toggleSearchExpanded() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
    });
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Search icon or loading indicator
                      _isSearching 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            )
                          : const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Icon(Icons.search, color: Colors.grey),
                            ),
                      
                      // Search text field
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search services on map...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      
                      // Service type chip
                      if (_selectedServiceType != 'All') ...[
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF2563EB).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedServiceType.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedServiceType = 'All';
                                  });
                                  _performSearch();
                                },
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isSearchExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                  onPressed: _toggleSearchExpanded,
                ),
              ],
            ),
          ),
          
          // Dropdown list of service types
          if (_isSearchExpanded) ...[
            const Divider(height: 1),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: GestureDetector(
                onTap: () {}, // Absorb tap gestures
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(), // Prevent gesture conflicts
                  itemCount: serviceTypes.length,
                  itemBuilder: (context, index) {
                    final serviceType = serviceTypes[index];
                    final isSelected = _selectedServiceType == serviceType;
                    
                    return GestureDetector(
                      onTap: () {
                        _onServiceTypeChanged(serviceType);
                        _toggleSearchExpanded(); // Close the dropdown after selection
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: ListTile(
                          title: Text(
                            serviceType == 'All' ? 'All Services' : serviceType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? const Color(0xFF2563EB) : Colors.black87,
                            ),
                          ),
                          trailing: isSelected 
                              ? const Icon(
                                  Icons.check,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                )
                              : null,
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
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
            scrollGesturesEnabled: !_isSearchExpanded, // Disable scroll when dropdown is open
            zoomGesturesEnabled: !_isSearchExpanded,   // Disable zoom when dropdown is open
            tiltGesturesEnabled: !_isSearchExpanded,   // Disable tilt when dropdown is open
            rotateGesturesEnabled: !_isSearchExpanded, // Disable rotate when dropdown is open
            initialCameraPosition: _initialCameraPosition,
            markers: _markers, // Add the markers to the map
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
                // Results counter
                if (!_isSearchExpanded && _services.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${searchResultsCount} services found',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: _refreshServices,
                          child: const Icon(
                            Icons.refresh,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer?.cancel();
    super.dispose();
  }
}
