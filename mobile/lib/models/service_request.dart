import 'dart:developer' as developer;

enum RequestStatus { pending, accepted, completed, rejected }

enum RequestHistoryStatus { completed, rejected }

class ServiceRequest {
  final String id;
  final String clientId;
  final String clientName;
  final String vendorId;
  final String vendorName;
  final String serviceId;
  final String serviceTitle;
  final String serviceCategory;
  final String description;
  final String location;
  final String budget;
  final String serviceType;
  final double servicePrice;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? rejectionReason;
  final DateTime? scheduledDate;
  final String? note;
  final String conversationId;
  final String clientLocation;

  ServiceRequest(
      {required this.id,
      required this.clientId,
      required this.clientName,
      required this.vendorId,
      required this.vendorName,
      required this.serviceId,
      required this.serviceTitle,
      required this.serviceCategory,
      required this.description,
      required this.location,
      required this.budget,
      required this.serviceType,
      required this.servicePrice,
      required this.status,
      required this.createdAt,
      required this.updatedAt,
      this.rejectionReason,
      this.scheduledDate,
      this.note,
      required this.conversationId,
      required this.clientLocation});

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    developer.log('Creating ServiceRequest from JSON: ${json['id']}',
        name: 'ServiceRequest');
    return ServiceRequest(
      id: json['id'],
      clientId: json['clientId'],
      clientName: json['clientName'],
      vendorId: json['vendorId'],
      vendorName: json['vendorName'],
      serviceId: json['serviceId'],
      serviceTitle: json['serviceTitle'],
      serviceCategory: json['serviceCategory'],
      description: json['description'],
      location: json['location'],
      budget: (json['budget'] != "" ? (json['budget']).toString() : '0'),
      serviceType: json['serviceType'] ?? 'on-site',
      servicePrice: (json['servicePrice'] ?? 0).toDouble(),
      status: RequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      rejectionReason: json['rejectionReason'],
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'])
          : null,
      note: json['notes'],
      conversationId: json['conversationId'] ?? '',
      clientLocation: json['clientLocation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'serviceCategory': serviceCategory,
      'description': description,
      'location': location,
      'budget': budget,
      'serviceType': serviceType,
      'servicePrice': servicePrice,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'rejectionReason': rejectionReason,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'notes': note,
      'clientLocation': clientLocation,
    };
  }

  String get statusDisplayName {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.rejected:
        return 'Rejected';
    }
  }

  String get statusDescription {
    switch (status) {
      case RequestStatus.pending:
        return 'Waiting for vendor confirmation';
      case RequestStatus.accepted:
        return 'Service confirmed and in progress';
      case RequestStatus.completed:
        return 'Service completed successfully';
      case RequestStatus.rejected:
        return 'Request was rejected';
    }
  }
}
