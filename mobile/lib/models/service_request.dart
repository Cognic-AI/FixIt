import 'dart:developer' as developer;

enum ServiceRequestStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
  rejected
}

class ServiceRequest {
  final String id;
  final String serviceId;
  final String clientId;
  final String vendorId;
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String serviceTitle;
  final double servicePrice;
  final String location;
  final DateTime requestedDate;
  final DateTime? acceptedDate;
  final DateTime? completedDate;
  final ServiceRequestStatus status;
  final String? notes;
  final String? clientNotes;
  final double? rating;
  final String? review;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceRequest({
    required this.id,
    required this.serviceId,
    required this.clientId,
    required this.vendorId,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.serviceTitle,
    required this.servicePrice,
    required this.location,
    required this.requestedDate,
    this.acceptedDate,
    this.completedDate,
    required this.status,
    this.notes,
    this.clientNotes,
    this.rating,
    this.review,
    required this.createdAt,
    required this.updatedAt,
  });

  String get statusDisplayName {
    switch (status) {
      case ServiceRequestStatus.pending:
        return 'Pending';
      case ServiceRequestStatus.accepted:
        return 'Accepted';
      case ServiceRequestStatus.inProgress:
        return 'In Progress';
      case ServiceRequestStatus.completed:
        return 'Completed';
      case ServiceRequestStatus.cancelled:
        return 'Cancelled';
      case ServiceRequestStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isPending => status == ServiceRequestStatus.pending;
  bool get isAccepted => status == ServiceRequestStatus.accepted;
  bool get isInProgress => status == ServiceRequestStatus.inProgress;
  bool get isCompleted => status == ServiceRequestStatus.completed;
  bool get isCancelled => status == ServiceRequestStatus.cancelled;
  bool get isRejected => status == ServiceRequestStatus.rejected;

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    developer.log('📝 Creating ServiceRequest from JSON: ${json['id']}',
        name: 'ServiceRequest');
    return ServiceRequest(
      id: json['id'],
      serviceId: json['serviceId'],
      clientId: json['clientId'],
      vendorId: json['vendorId'],
      clientName: json['clientName'],
      clientEmail: json['clientEmail'],
      clientPhone: json['clientPhone'],
      serviceTitle: json['serviceTitle'],
      servicePrice: (json['servicePrice'] ?? 0.0).toDouble(),
      location: json['location'],
      requestedDate: DateTime.parse(json['requestedDate']),
      acceptedDate: json['acceptedDate'] != null
          ? DateTime.parse(json['acceptedDate'])
          : null,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'])
          : null,
      status: ServiceRequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ServiceRequestStatus.pending,
      ),
      notes: json['notes'],
      clientNotes: json['clientNotes'],
      rating: json['rating']?.toDouble(),
      review: json['review'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'clientId': clientId,
      'vendorId': vendorId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientPhone': clientPhone,
      'serviceTitle': serviceTitle,
      'servicePrice': servicePrice,
      'location': location,
      'requestedDate': requestedDate.toIso8601String(),
      'acceptedDate': acceptedDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'status': status.toString().split('.').last,
      'notes': notes,
      'clientNotes': clientNotes,
      'rating': rating,
      'review': review,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ServiceRequest copyWith({
    String? id,
    String? serviceId,
    String? clientId,
    String? vendorId,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? serviceTitle,
    double? servicePrice,
    String? location,
    DateTime? requestedDate,
    DateTime? acceptedDate,
    DateTime? completedDate,
    ServiceRequestStatus? status,
    String? notes,
    String? clientNotes,
    double? rating,
    String? review,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      clientId: clientId ?? this.clientId,
      vendorId: vendorId ?? this.vendorId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      servicePrice: servicePrice ?? this.servicePrice,
      location: location ?? this.location,
      requestedDate: requestedDate ?? this.requestedDate,
      acceptedDate: acceptedDate ?? this.acceptedDate,
      completedDate: completedDate ?? this.completedDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      clientNotes: clientNotes ?? this.clientNotes,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
