import 'package:fixit/models/user.dart';
import 'package:fixit/pages/client/ai_chat_page.dart';
import 'package:fixit/pages/client/subscribed_services_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../services/service_request_service.dart';
import '../services/user_service.dart';
import '../models/service_request.dart';
import '../widgets/service_card.dart';
import '../models/service.dart';
import 'search_page.dart';
import 'map_page.dart';
import 'client/messages_page.dart';
import 'client/requested_services_page.dart';
import 'client/edit_profile_page.dart';
// import 'client/settings_page.dart';
import 'auth/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user, required this.token});

  final User user;
  final String token;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Service> featuredServices = [];
  List<Service> nearbyServices = [];
  final MessagingService _messagingService = MessagingService();
  final ServiceRequestService _requestService = ServiceRequestService();
  final UserService _userService = UserService();
  bool _isLoadingNearbyServices = false;

  @override
  void initState() {
    super.initState();
    developer.log('HomePage initialized', name: 'HomePage');
    developer.log('Nearby services count: ${nearbyServices.length}',
        name: 'HomePage');
    _loadNearbyServices();
  }

  Future<void> _loadNearbyServices() async {
    setState(() {
      _isLoadingNearbyServices = true;
    });

    try {
      developer.log('🏠 Loading nearby services', name: 'HomePage');
      
      // Get all services
      final allServices = await _userService.loadServices(widget.token);
      
      // Get user's current location from their profile
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user != null && user.location.isNotEmpty) {
        final userLocation = _parseLocationString(user.location);
        
        if (userLocation != null) {
          // Filter services by distance (within 50km)
          final servicesWithDistance = <Map<String, dynamic>>[];
          
          for (final service in allServices) {
            final serviceLocation = _parseLocationString(service.location);
            if (serviceLocation != null) {
              final distance = Geolocator.distanceBetween(
                userLocation.latitude,
                userLocation.longitude,
                serviceLocation.latitude,
                serviceLocation.longitude,
              );
              
              // Only include services within 50km (50000 meters)
              if (distance <= 50000) {
                servicesWithDistance.add({
                  'service': service,
                  'distance': distance,
                });
              }
            }
          }
          
          // Sort by distance and take first 10
          servicesWithDistance.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
          
          final nearby = servicesWithDistance
              .take(10)
              .map((item) => item['service'] as Service)
              .toList();
          
          setState(() {
            nearbyServices = nearby;
          });
          
          developer.log('Found ${nearbyServices.length} nearby services', name: 'HomePage');
        } else {
          developer.log('Could not parse user location: ${user.location}', name: 'HomePage');
        }
      } else {
        developer.log('User location not available', name: 'HomePage');
      }
    } catch (e) {
      developer.log('Error loading nearby services: $e', name: 'HomePage');
    } finally {
      setState(() {
        _isLoadingNearbyServices = false;
      });
    }
  }

  // Parse location string to LatLng (similar to map_page.dart)
  ({double latitude, double longitude})? _parseLocationString(String locationStr) {
    try {
      if (locationStr.isEmpty) return null;
      
      locationStr = locationStr.trim();
      
      // Format: "lat,lng" or "lat lng"
      if (locationStr.contains(',')) {
        final parts = locationStr.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null && 
              lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
            return (latitude: lat, longitude: lng);
          }
        }
      }
      
      if (locationStr.contains(' ')) {
        final parts = locationStr.split(' ');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null && 
              lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
            return (latitude: lat, longitude: lng);
          }
        }
      }
      
      return null;
    } catch (e) {
      developer.log('Error parsing location "$locationStr": $e', name: 'HomePage');
      return null;
    }
  }

  Widget _buildQuickAccessItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    dynamic badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            badge is Future
                ? FutureBuilder<int>(
                    future: badge as Future<int>,
                    builder: (context, snapshot) {
                      final badgeCount = snapshot.data ?? 0;
                      return Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          if (badgeCount > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  badgeCount > 99 ? '99+' : '$badgeCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    })
                : Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      if (badge > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              badge > 99 ? '99+' : '$badge',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    developer.log('Building HomePage', name: 'HomePage');
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            collapsedHeight: 80,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Transform.translate(
                offset: const Offset(0, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      child: Image.asset(
                        'assets/images/logo-no-bg.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.build_rounded,
                            size: 48,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -8),
                      child: const Text(
                        'A one-step solution to fix everyday problems',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2563EB),
                      Color(0xFF7C3AED),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  developer.log(
                      'Search button pressed - navigating to SearchPage',
                      name: 'HomePage');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SearchPage(
                              token: widget.token,
                              uid: widget.user.id,
                            )),
                  );
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  developer.log('Menu item selected: $value', name: 'HomePage');
                  if (value == 'profile') {
                    developer.log('Navigating to profile page',
                        name: 'HomePage');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(
                          token: widget.token,
                          userId: widget.user.id,
                        ),
                      ),
                    );
                    // } else if (value == 'settings') {
                    //   developer.log('Navigating to settings page',
                    //       name: 'HomePage');
                    //   Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //       builder: (context) => SettingsPage(token: widget.token),
                    //     ),
                    //   );
                  } else if (value == 'logout') {
                    developer.log('Logging out user', name: 'HomePage');
                    try {
                      await Provider.of<AuthService>(context, listen: false)
                          .signOut();
                      developer.log('User logged out successfully',
                          name: 'HomePage');
                      // Navigate to login and clear all previous routes
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                          (Route<dynamic> route) => false,
                        );
                      }
                    } catch (e) {
                      developer.log('Error during logout: $e',
                          name: 'HomePage', error: e);
                      // Show error message to user
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error logging out: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 20, color: Color(0xFF2563EB)),
                        SizedBox(width: 12),
                        Text('Profile'),
                      ],
                    ),
                  ),
                  // const PopupMenuItem(
                  //   value: 'settings',
                  //   child: Row(
                  //     children: [
                  //       Icon(Icons.settings, size: 20),
                  //       SizedBox(width: 12),
                  //       Text('Settings'),
                  //     ],
                  //   ),
                  // ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20, color: Color(0xFF2563EB)),
                        SizedBox(width: 12),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Hero Section with personalized welcome
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF7C3AED),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personalized greeting
                  Text(
                    'Hello, ${widget.user.firstName}! 👋',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'What service do you need today?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Main action buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.2),
                                spreadRadius: 0,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SearchPage(
                                          token: widget.token,
                                          uid: widget.user.id,
                                        )),
                              );
                            },
                            icon: const Icon(Icons.search, size: 20),
                            label: const Text(
                              'Find Services',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MapPage(
                                      token: widget.token,
                                      uid: widget.user.id)),
                            );
                          },
                          icon: const Icon(Icons.map, size: 20),
                          label: const Text(
                            'View Map',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Quick access section with improved design
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Access',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQuickAccessItem(
                              icon: Icons.chat_bubble_outline,
                              label: 'Messages',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MessagesPage(
                                      userId: widget.user.id,
                                      token: widget.token,
                                    ),
                                  ),
                                );
                              },
                              badge: _messagingService.getTotalUnreadCount(
                                  widget.user.id, widget.token),
                            ),
                            FutureBuilder<int>(
                              future: _requestService
                                  .getRequestCounts(widget.user.id)
                                  .then((counts) =>
                                      counts[RequestStatus.pending] ?? 0),
                              builder: (context, snapshot) {
                                final pendingCount = snapshot.data ?? 0;
                                return _buildQuickAccessItem(
                                  icon: Icons.assignment_outlined,
                                  label: 'Requests',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            RequestedServicesPage(
                                          clientId: widget.user.id,
                                          token: widget.token,
                                        ),
                                      ),
                                    );
                                  },
                                  badge: pendingCount,
                                );
                              },
                            ),
                            _buildQuickAccessItem(
                              icon: Icons.bookmark_outline,
                              label: 'Saved',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SubscribedServicesPage(
                                      token: widget.token,
                                      uid: widget.user.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildQuickAccessItem(
                              icon: Icons.person_outline,
                              label: 'Profile',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfilePage(
                                      token: widget.token,
                                      userId: widget.user.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Services near you Section 
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Services Near You',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find trusted professionals in your area',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Nearby services horizontal scroll
                  if (_isLoadingNearbyServices)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    )
                  else if (nearbyServices.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No services found nearby',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Update your location in profile settings to see services near you',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ClipRect(
                      child: SizedBox(
                        height: 375,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: nearbyServices.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 16),
                              child: ServiceCard(
                                service: nearbyServices[index],
                                token: widget.token,
                                userId: widget.user.id,
                                showMessageButton: false,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Tips Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Pro Tip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Use the AI assistant for instant help with service recommendations, pricing estimates, and booking guidance. Just tap the blue robot icon!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.4),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AiChatPage(
                      userId: widget.user.id,
                      token: widget.token,
                    ),
                  ),
                );
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          // // Unread messages badge for FAB
          // FutureBuilder<int>(
          //   future: _messagingService.getTotalUnreadCount(
          //       widget.user.id, widget.token),
          //   builder: (context, snapshot) {
          //     final unreadCount = snapshot.data ?? 0;
          //     if (unreadCount == 0) return const SizedBox.shrink();

          //     return Positioned(
          //       right: 0,
          //       top: 0,
          //       child: Container(
          //         padding: const EdgeInsets.all(2),
          //         decoration: BoxDecoration(
          //           color: Colors.red,
          //           borderRadius: BorderRadius.circular(10),
          //         ),
          //         constraints: const BoxConstraints(
          //           minWidth: 16,
          //           minHeight: 16,
          //         ),
          //         child: Text(
          //           unreadCount > 99 ? '99+' : '$unreadCount',
          //           style: const TextStyle(
          //             color: Colors.white,
          //             fontSize: 10,
          //             fontWeight: FontWeight.bold,
          //           ),
          //           textAlign: TextAlign.center,
          //         ),
          //       ),
          //     );
          //   },
          // ),
        ],
      ),
    );
  }
}
