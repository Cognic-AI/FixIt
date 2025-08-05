import 'package:fixit/models/user.dart';
import 'package:fixit/pages/client/ai_chat_page.dart';
import 'package:fixit/pages/client/subscribed_services_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../services/service_request_service.dart';
import '../models/service_request.dart';
import '../widgets/service_card.dart';
import '../widgets/event_card.dart';
import '../models/service.dart';
import '../models/event.dart';
import 'search_page.dart';
import 'map_page.dart';
import 'client/messages_page.dart';
import 'client/requested_services_page.dart';
import 'client/edit_profile_page.dart';
import 'client/settings_page.dart';
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
  final MessagingService _messagingService = MessagingService();
  final ServiceRequestService _requestService = ServiceRequestService();

  final List<Event> nearbyEvents = [
    Event(
      id: '1',
      title: 'Maroon 5 Concert',
      location: 'Recife Arena',
      date: 'Apr 15, 2024',
      price: 120.0,
      imageUrl:
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400',
      category: 'Concerts',
      description: 'Join us for an unforgettable night with Maroon 5!',
      organizer: 'Live Nation',
      capacity: 5000,
      ticketsAvailable: 0,
      time: "7:00 PM",
    ),
  ];

  @override
  void initState() {
    super.initState();
    developer.log('HomePage initialized', name: 'HomePage');
    developer.log('Featured services count: ${featuredServices.length}',
        name: 'HomePage');
    developer.log('Nearby events count: ${nearbyEvents.length}',
        name: 'HomePage');
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
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
                          Icon(
                            icon,
                            color: Colors.white,
                            size: 24,
                          ),
                          if (badgeCount > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
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
                      Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                      if (badge > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
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
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    developer.log('🔨 Building HomePage', name: 'HomePage');
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'FixIt',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
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
              // Messages Button with Badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () {
                      developer.log(
                          'Messages button pressed - navigating to MessagesPage',
                          name: 'HomePage');
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
                  ),
                  // Unread messages badge
                  FutureBuilder<int>(
                    future: Future.value(_messagingService.getTotalUnreadCount(
                        widget.user.id, widget.token)),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.data ?? 0;
                      if (unreadCount == 0) return const SizedBox.shrink();

                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
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
                        ),
                      ),
                    );
                  } else if (value == 'settings') {
                    developer.log('Navigating to settings page',
                        name: 'HomePage');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(token: widget.token),
                      ),
                    );
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
                        Icon(Icons.person, size: 20),
                        SizedBox(width: 12),
                        Text('Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 20),
                        SizedBox(width: 12),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20),
                        SizedBox(width: 12),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Hero Section
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
                children: [
                  const Text(
                    'Find Local Services Near You',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connect with trusted service providers in your area',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
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
                          icon: const Icon(Icons.search),
                          label: const Text('Find Services'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
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
                          icon: const Icon(Icons.map),
                          label: const Text('View Map'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Quick Access Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                            .then(
                                (counts) => counts[RequestStatus.pending] ?? 0),
                        builder: (context, snapshot) {
                          final pendingCount = snapshot.data ?? 0;
                          return _buildQuickAccessItem(
                            icon: Icons.assignment_outlined,
                            label: 'Requests',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RequestedServicesPage(
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
                              builder: (context) => SubscribedServicesPage(
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
          ),

          // Near You Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Near You',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
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
                    child: const Text('See More'),
                  ),
                ],
              ),
            ),
          ),

          // Featured Services
          SliverToBoxAdapter(
            child: SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: featuredServices.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ServiceCard(
                      service: featuredServices[index],
                      token: widget.token,
                      userId: widget.user.id,
                    ),
                  );
                },
              ),
            ),
          ),

          // Events Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Events',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to events page
                    },
                    child: const Text('See All Events'),
                  ),
                ],
              ),
            ),
          ),

          // Events List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: EventCard(event: nearbyEvents[index]),
                );
              },
              childCount: nearbyEvents.length,
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
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AiChatPage(
                    userId: widget.user.id,
                    token: widget.token, // Pass the token for authentication
                  ),
                ),
              );
            },
            backgroundColor: const Color(0xFF2563EB),
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          ),
          // Unread messages badge for FAB
          FutureBuilder<int>(
            future: _messagingService.getTotalUnreadCount(
                widget.user.id, widget.token),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return const SizedBox.shrink();

              return Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
