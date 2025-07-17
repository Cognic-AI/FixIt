class Service {
  final String id;
  final String providerId;
  final String providerEmail;
  final String title;
  final String description;
  final String category;
  final bool availability;
  final double price;
  final String location;
  final String createdAt;
  final String updatedAt;
  final String tags;
  final String images;

  Service({
    required this.id,
    required this.providerId,
    required this.providerEmail,
    required this.title,
    required this.description,
    required this.category,
    required this.availability,
    required this.price,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
    required this.images,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? '',
      providerId: json['providerId'] ?? '',
      providerEmail: json['providerEmail'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      availability: json['availability'] ?? false,
      price: (json['price'] ?? 0).toDouble(),
      location: json['location'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      tags: json['tags'] ?? '',
      images: json['images'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'providerEmail': providerEmail,
      'title': title,
      'description': description,
      'category': category,
      'availability': availability,
      'price': price,
      'location': location,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'tags': tags,
      'images': images,
    };
  }
}
