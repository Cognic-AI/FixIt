import 'dart:developer' as developer;

class Service {
  final String id;
  final String title;
  final String description;
  final double price;
  final String location;
  final double rating;
  final int reviewCount;
  final String hostId;
  final String hostName;
  final String category;
  final List<String> amenities;
  final String imageUrl;
  final String dates;
  final double? latitude;
  final double? longitude;
  final bool active;

  Service({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.hostId,
    required this.hostName,
    required this.category,
    required this.amenities,
    required this.imageUrl,
    required this.dates,
    this.latitude,
    this.longitude,
    this.active = true,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    print('[SERVICE_MODEL] Creating Service from JSON');
    print('[SERVICE_MODEL] JSON data: $json');
    developer.log('Creating Service from JSON: ${json['title']}',
        name: 'Service');

    try {
      final service = Service(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        price: (json['price'] ?? 0.0).toDouble(),
        location: json['location'],
        rating: (json['rating'] ?? 0.0).toDouble(),
        reviewCount: json['reviewCount'] ?? 0,
        hostId: json['hostId'],
        hostName: json['hostName'],
        category: json['category'],
        amenities: List<String>.from(json['amenities'] ?? []),
        imageUrl: json['imageUrl'] ?? '',
        dates: json['dates'] ?? '',
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
        active: json['active'] ?? true,
      );
      print('[SERVICE_MODEL] Service created successfully: ${service.title}');
      return service;
    } catch (e) {
      print('[SERVICE_MODEL] Error creating service: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'rating': rating,
      'reviewCount': reviewCount,
      'hostId': hostId,
      'hostName': hostName,
      'category': category,
      'amenities': amenities,
      'imageUrl': imageUrl,
      'dates': dates,
      'latitude': latitude,
      'longitude': longitude,
      'active': active,
    };
  }
}
