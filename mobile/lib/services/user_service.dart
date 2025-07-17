import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import '../models/service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserService {
  static final String _baseUrl =
      dotenv.env['USER_SERVICE_URL'] ?? 'http://localhost:8084/api/services';

  Future<List<Service>> loadServices(String token) async {
    developer.log('[UserService] Loading services from $_baseUrl',
        name: 'UserService');

    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
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
}
