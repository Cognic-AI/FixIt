import 'package:fixit/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../services/auth_service.dart';
import '../widgets/service_card.dart';
import '../widgets/event_card.dart';
import '../models/service.dart';
import '../models/event.dart';
import 'search_page.dart';
import 'map_page.dart';
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
                  developer.log('Menu item selected: $value',
                      name: 'HomePage');
                  if (value == 'profile') {
                    developer.log('Navigating to profile page', name: 'HomePage');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfilePage(),
                      ),
                    );
                  } else if (value == 'settings') {
                    developer.log('Navigating to settings page', name: 'HomePage');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
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
                          MaterialPageRoute(builder: (context) => const LoginPage()),
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
                                  builder: (context) =>
                                      MapPage(token: widget.token, uid: widget.user.id)),
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
    );
  }
}
