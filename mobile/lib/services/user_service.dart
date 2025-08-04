import 'package:fixit/models/subscription.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import '../models/service.dart';
import '../models/request.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserService {
  static final String _baseServiceUrl =
      dotenv.env['VENDOR_SERVICE_URL'] ?? 'http://localhost:8084/api/services';
  static final String _baseRequestUrl =
      dotenv.env['REQUEST_SERVICE_URL'] ?? 'http://localhost:8086/api/requests';
  static final String _baseSubscriptionUrl =
      dotenv.env['SUBSCRIPTION_SERVICE_URL'] ??
          'http://localhost:8088/api/subscriptions';

  Future<List<Service>> loadServices(String token) async {
    developer.log('[UserService] Loading services from $_baseServiceUrl',
        name: 'UserService');
    print("[UserService] Loading services from $_baseServiceUrl");

    try {
      final response = await http.get(
        Uri.parse(_baseServiceUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      developer.log('[UserService] Response status: ${response.statusCode}',
          name: 'UserService');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['services'] is List) {
          final services = (decoded['services'] as List)
              .map((json) => Service.fromJson(json))
              .toList();
          developer.log('[UserService] Loaded ${services.length} services',
              name: 'UserService');
          return services;
        } else {
          developer.log('[UserService] Unexpected response format',
              name: 'UserService');
          return [];
        }
      } else {
        developer.log('[UserService] Error loading services: ${response.body}',
            name: 'UserService');
        throw Exception('Failed to load services');
      }
    } catch (e) {
      developer.log('Error loading services: $e', name: 'UserService');
      rethrow;
    }
  }

  // Get all public requests (available to all users)
  Future<List<Request>> getPublicRequests({String? token}) async {
    developer.log('[UserService] Loading public requests from $_baseRequestUrl',
        name: 'UserService');

    try {
      final headers = {
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse(_baseRequestUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['requests'] is List) {
          return (decoded['requests'] as List)
              .map((json) => Request.fromJson(json))
              .toList();
        }
        throw Exception('Unexpected response format');
      } else {
        throw Exception('Failed to load requests: ${response.body}');
      }
    } catch (e) {
      developer.log('Error loading public requests: $e', name: 'UserService');
      rethrow;
    }
  }

  // Get requests for the current provider (vendor)
  Future<List<Request>> getMyRequests(String token) async {
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

  Future<List<Subscription>> getMySubscriptions(String token) async {
    developer.log(
        '[UserService] Loading my subscriptions from $_baseSubscriptionUrl',
        name: 'UserService');

    try {
      final response = await http.get(
        Uri.parse(_baseSubscriptionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['subscriptions'] is List) {
          return (decoded['subscriptions'] as List)
              .map((json) => Subscription.fromJson(json))
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

  // Create a new request (vendor only)
  Future<Request> createRequest({
    required String token,
    required String serviceId,
    required String clientId,
    required String providerId,
    required String location,
  }) async {
    developer.log('[UserService] Creating new request at $_baseRequestUrl',
        name: 'UserService');

    try {
      final response = await http.post(
        Uri.parse(_baseRequestUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'serviceId': serviceId,
          'clientId': clientId,
          'providerId': providerId,
          'location': location,
        }),
      );

      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return Request.fromJson(decoded['request']);
      } else {
        throw Exception('Failed to create request: ${response.body}');
      }
    } catch (e) {
      developer.log('Error creating request: $e', name: 'UserService');
      rethrow;
    }
  }

  Future<void> makeSubscription({
    required String token,
    required String serviceId,
  }) async {
    developer.log(
        '[UserService] Creating new subscription at $_baseSubscriptionUrl',
        name: 'UserService');

    try {
      final response = await http.post(
        Uri.parse(_baseSubscriptionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'serviceId': serviceId,
        }),
      );

      if (response.statusCode == 201) {
        return;
      } else {
        throw Exception('Failed to create request: ${response.body}');
      }
    } catch (e) {
      developer.log('Error creating request: $e', name: 'UserService');
      rethrow;
    }
  }

  // Update a request (vendor only)
  Future<Request> updateRequest({
    required String token,
    required String requestId,
    String? serviceId,
    String? clientId,
    String? state,
    String? chatId,
  }) async {
    developer.log(
        '[UserService] Updating request $requestId at $_baseRequestUrl',
        name: 'UserService');

    try {
      final payload = <String, dynamic>{};
      if (serviceId != null) payload['serviceId'] = serviceId;
      if (clientId != null) payload['clientId'] = clientId;
      if (state != null) payload['state'] = state;
      if (chatId != null) payload['chatId'] = chatId;

      final response = await http.put(
        Uri.parse('$_baseRequestUrl/$requestId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return Request.fromJson(decoded['request']);
      } else {
        throw Exception('Failed to update request: ${response.body}');
      }
    } catch (e) {
      developer.log('Error updating request: $e', name: 'UserService');
      rethrow;
    }
  }

  // Delete a request (vendor only)
  Future<void> deleteRequest({
    required String token,
    required String requestId,
  }) async {
    developer.log(
        '[UserService] Deleting request $requestId at $_baseRequestUrl',
        name: 'UserService');

    try {
      final response = await http.delete(
        Uri.parse('$_baseRequestUrl/$requestId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete request: ${response.body}');
      }
    } catch (e) {
      developer.log('Error deleting request: $e', name: 'UserService');
      rethrow;
    }
  }

  Future<void> removeSubscription({
    required String token,
    required String serviceId,
    required String subscriptionId,
  }) async {
    developer.log(
        '[UserService] Deleting subscription $serviceId at $_baseSubscriptionUrl',
        name: 'UserService');

    try {
      final response = await http.delete(
        Uri.parse(_baseSubscriptionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({'serviceId': serviceId, 'id': subscriptionId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete subscription: ${response.body}');
      }
    } catch (e) {
      developer.log('Error deleting subscription: $e', name: 'UserService');
      rethrow;
    }
  }
}
