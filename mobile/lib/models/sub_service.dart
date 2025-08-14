class SubService {
  final String description;
  final double price;

  SubService({
    required this.description,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'price': price,
    };
  }

  factory SubService.fromJson(Map<String, dynamic> json) {
    return SubService(
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }
}
