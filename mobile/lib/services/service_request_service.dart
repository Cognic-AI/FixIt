import 'dart:convert';
import 'dart:developer' as developer;
import 'package:fixit/models/request.dart';

import '../models/service_request.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ServiceRequestService {
  // Base URL for the service request API
  static final String _baseRequestUrl =
      dotenv.env['REQUEST_SERVICE_URL'] ?? 'http://localhost:8086/api/requests';

  Future<List<ServiceRequest>> getServiceRequests(String token) async {
    developer.log('[UserService] Loading my requests from $_baseRequestUrl/my',
        name: 'UserService');

    try {
      final response = await http.get(
        Uri.parse('$_baseRequestUrl/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['requests'] is List) {
          return (decoded['requests'] as List)
              .map((json) => Request.fromJson(json))
              .map((request) => _convertRequestToServiceRequest(request))
              .toList();
        }
        throw Exception('Unexpected response format');
      } else {
        throw Exception('Failed to load my requests: ${response.body}');
      }
    } catch (e) {
      developer.log('Error loading my requests: $e', name: 'UserService');
      rethrow;
    }
  }

// Helper method to convert Request to ServiceRequest
  ServiceRequest _convertRequestToServiceRequest(Request request) {
    print("ClientLocation: ${request.clientLocation}");
    print("Location: ${request.location}");
    return ServiceRequest(
      id: request.id,
      clientId: request.clientId,
      clientName:
          request.clientName.isNotEmpty ? request.clientName : 'Unknown Client',
      vendorId: request.providerId,
      vendorName: request.providerName.isNotEmpty
          ? request.providerName
          : 'Unknown Provider',
      serviceId: request.serviceId,
      serviceTitle: request.title,
      serviceCategory: request.category,
      description: request.description,
      location: request.location.isNotEmpty
          ? request.location
          : request.clientLocation,
      budget: request.price, // Using price as budget
      servicePrice: request.price,
      status: _convertStateToRequestStatus(request.state),
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
      scheduledDate: null, // Request doesn't have scheduled date
      note: request.note,
      conversationId: request.chatId,
      clientLocation: request.clientLocation.isNotEmpty
          ? request.clientLocation
          : "", // Fallback to location if clientLocation is empty
    );
  }

// Helper method to convert state string to RequestStatus enum
  RequestStatus _convertStateToRequestStatus(String state) {
    switch (state.toLowerCase()) {
      case 'pending':
        return RequestStatus.pending;
      case 'accepted':
        return RequestStatus.accepted;
      case 'completed':
        return RequestStatus.completed;
      case 'rejected':
      case 'cancelled':
        return RequestStatus.rejected;
      default:
        return RequestStatus.pending;
    }
  }

  Future<Map<RequestStatus, int>> getRequestCounts(String clientId) async {
    developer.log('📊 Getting request counts for client: $clientId',
        name: 'ServiceRequestService');

    try {
      final response = await http.get(
        Uri.parse('$_baseRequestUrl/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $clientId' // Using clientId as token
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<ServiceRequest> requests = [];

        if (decoded['requests'] is List) {
          requests.addAll((decoded['requests'] as List)
              .map((json) => Request.fromJson(json))
              .map((request) => _convertRequestToServiceRequest(request))
              .toList());
        }

        final counts = <RequestStatus, int>{};
        for (final status in RequestStatus.values) {
          counts[status] = requests.where((req) => req.status == status).length;
        }

        developer.log('📊 Request counts: ${counts.toString()}',
            name: 'ServiceRequestService');
        return counts;
      } else {
        throw Exception('Failed to load requests: ${response.body}');
      }
    } catch (e) {
      developer.log('Error getting request counts: $e',
          name: 'ServiceRequestService');
      rethrow;
    }
  }

  Future<ServiceRequest> updateRequestStatus(
      String requestId, RequestStatus newStatus,
      {String? reason}) async {
    developer.log(
        '🔄 Updating request $requestId status to ${newStatus.toString().split('.').last}',
        name: 'ServiceRequestService');

    try {
      final requestData = {
        'state': _convertRequestStatusToState(newStatus),
        if (reason != null) 'rejectionReason': reason
      };

      final response = await http.put(
        Uri.parse('$_baseRequestUrl/$requestId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $requestId' // Using requestId as token for demo
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['request'] != null) {
          final request = Request.fromJson(decoded['request']);
          return _convertRequestToServiceRequest(request);
        }
        throw Exception('Unexpected response format');
      } else {
        throw Exception('Failed to update request: ${response.body}');
      }
    } catch (e) {
      developer.log('Error updating request status: $e',
          name: 'ServiceRequestService');
      rethrow;
    }
  }

  Future<void> cancelRequest(String requestId, String reason) async {
    await updateRequestStatus(requestId, RequestStatus.rejected,
        reason: reason);
  }

  // Helper method to convert RequestStatus enum to state string
  String _convertRequestStatusToState(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'pending';
      case RequestStatus.accepted:
        return 'accepted';
      case RequestStatus.completed:
        return 'completed';
      case RequestStatus.rejected:
        return 'rejected';
    }
  }
}
