class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final String date;
  final String time;
  final double price;
  final String category;
  final String imageUrl;
  final int capacity;
  final int ticketsAvailable;
  final String organizer;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.time,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.capacity,
    required this.ticketsAvailable,
    required this.organizer,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      location: json['location'],
      date: json['date'],
      time: json['time'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      category: json['category'],
      imageUrl: json['imageUrl'] ?? '',
      capacity: json['capacity'] ?? 0,
      ticketsAvailable: json['ticketsAvailable'] ?? 0,
      organizer: json['organizer'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'date': date,
      'time': time,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'capacity': capacity,
      'ticketsAvailable': ticketsAvailable,
      'organizer': organizer,
    };
  }
}
