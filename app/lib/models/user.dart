class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String userType; // 'client' or 'vendor'
  final String? avatar;
  final double rating;
  final int reviewCount;
  final String location;
  final bool verified;
  final DateTime createdAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.userType,
    this.avatar,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.location,
    this.verified = false,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';
  String get username => '@${email.split('@')[0]}';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      userType: json['userType'],
      avatar: json['avatar'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      location: json['location'],
      verified: json['verified'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'userType': userType,
      'avatar': avatar,
      'rating': rating,
      'reviewCount': reviewCount,
      'location': location,
      'verified': verified,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
