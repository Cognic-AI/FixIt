class Request {
  final String id;
  final String serviceId;
  final String providerId;
  final String clientId;
  final String state;
  final String location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String chatId;
  final String title;
  final String description;
  final String category;
  final bool availability;
  final double price;
  final String tags;
  final String images;
  Request({
    required this.id,
    required this.serviceId,
    required this.providerId,
    required this.clientId,
    required this.state,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    required this.chatId,
    required this.title,
    required this.description,
    required this.category,
    required this.availability,
    required this.price,
    required this.tags,
    required this.images,
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      id: json['id'],
      serviceId: json['serviceId'],
      providerId: json['providerId'],
      clientId: json['clientId'],
      state: json['state'],
      location: json['location'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      chatId: json['chatId'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      availability: json['availability'] ?? false,
      price: (json['price'] as num).toDouble(),
      tags: json['tags'] ?? '',
      images: json['images'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'providerId': providerId,
      'clientId': clientId,
      'state': state,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'chatId': chatId,
      'title': title,
      'description': description,
      'category': category,
      'availability': availability,
      'price': price,
      'tags': tags,
      'images': images,
    };
  }

  // Helper method to get a short description of the request
  String get shortDescription {
    return 'Request #$id ($state)';
  }

  // You might want to add methods to check state
  bool get isPending => state == 'pending';
  bool get isAccepted => state == 'accepted';
  bool get isCompleted => state == 'completed';
  bool get isCancelled => state == 'cancelled';
}
