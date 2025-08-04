class Subscription {
  final String id;
  final String serviceId;
  final String clientId;
  Subscription({
    required this.id,
    required this.serviceId,
    required this.clientId,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      serviceId: json['serviceId'],
      clientId: json['clientId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'clientId': clientId,
    };
  }

  // Helper method to get a short description of the subscription
  String get shortDescription {
    return 'Subscription #$id';
  }
}
