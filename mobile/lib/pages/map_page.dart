import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/service.dart';
import '../widgets/service_card.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  Service? _selectedService;

  final List<Service> nearbyServices = [
    Service(
      id: '1',
      title: 'Great Apartment',
      price: 150.0,
      location: 'Recife',
      rating: 4.8,
      imageUrl:
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400',
      dates: 'Mar 12 – Mar 15',
      hostName: 'Karen Roe',
      category: 'accommodation',
      latitude: -8.0476,
      longitude: -34.877,
      description: 'A spacious apartment in the heart of Recife.',
      reviewCount: 45,
      hostId: 'host123',
      amenities: ['WiFi', 'Air Conditioning', 'Kitchen'],
      active: true,
    ),
    Service(
      id: '2',
      title: 'Cozy Studio',
      price: 85.0,
      location: 'Olinda',
      rating: 4.6,
      imageUrl:
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=400',
      dates: 'Mar 20 – Mar 23',
      hostName: 'João Silva',
      category: 'accommodation',
      latitude: -8.0089,
      longitude: -34.8553,
      description: 'A cozy studio apartment in historic Olinda.',
      reviewCount: 32,
      hostId: 'host456',
      amenities: ['WiFi', 'TV', 'Balcony'],
      active: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  void _createMarkers() {
    for (final service in nearbyServices) {
      _markers.add(
        Marker(
          markerId: MarkerId(service.id),
          position: LatLng(service.latitude!, service.longitude!),
          infoWindow: InfoWindow(
            title: service.title,
            snippet: '€${service.price.toStringAsFixed(0)}',
          ),
          onTap: () {
            setState(() {
              _selectedService = service;
            });
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              // Center map on user location
              if (_mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(
                    const LatLng(-8.0476, -34.877), // Recife coordinates
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-8.0476, -34.877), // Recife coordinates
              zoom: 12,
            ),
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          // Location Info Banner
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
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
              child: const Column(
                children: [
                  Text(
                    'Recife & Olinda Area',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mar 12 - Mar 15',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Service Details Bottom Sheet
          if (_selectedService != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Service Card
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ServiceCard(
                        service: _selectedService!,
                        isHorizontal: true,
                      ),
                    ),

                    // Close Button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedService = null;
                          });
                        },
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Services List (Sidebar)
          Positioned(
            top: 100,
            right: 16,
            child: Container(
              width: 60,
              height: 200,
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
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Nearby',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: nearbyServices.length,
                      itemBuilder: (context, index) {
                        final service = nearbyServices[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedService = service;
                            });
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLng(
                                LatLng(service.latitude!, service.longitude!),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _selectedService?.id == service.id
                                  ? const Color(0xFF2563EB)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '€${service.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _selectedService?.id == service.id
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
