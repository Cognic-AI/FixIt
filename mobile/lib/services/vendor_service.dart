import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import '../models/service.dart';
import '../models/service_request.dart';
import '../models/message.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VendorService extends ChangeNotifier {
  static final String _baseUrl =
      dotenv.env['VENDOR_SERVICE_URL'] ?? 'http://localhost:8084/api/services';

  List<Service> _myServices = [];
  List<ServiceRequest> _pendingRequests = [];
  List<ServiceRequest> _activeServices = [];
  List<ServiceRequest> _completedServices = [];
  List<Conversation> _conversations = [];
  bool _isLoading = false;

  List<Service> get myServices => _myServices;
  List<ServiceRequest> get pendingRequests => _pendingRequests;
  List<ServiceRequest> get activeServices => _activeServices;
  List<ServiceRequest> get completedServices => _completedServices;
  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;

  // String? token;
  // void setCurrentUserToken(String? token) {
  //   token = token;
  //   print('[VENDOR_SERVICE] token set to: $token');
  // }

  // String? currentUserId;
  // void setCurrentUserId(String? uid) {
  //   currentUserId = uid;
  //   print('[VENDOR_SERVICE] currentUserId set to: $currentUserId');
  // }

  Future<void> loadMyServices(String? token) async {
    if (token == null) {
      print('[VendorService] Token is null, cannot load services.');
      return;
    }
    _setLoading(true);
    try {
      print('[VendorService] Loading services from $_baseUrl');
      final response = await http.get(
        Uri.parse("$_baseUrl/my"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $token"
        },
      );
      developer.log('[VendorService] Response status: ${response.statusCode}',
          name: 'VendorService');
      if (response.statusCode == 200) {
        final decoded = (jsonDecode(response.body))["services"];
        if (decoded is List) {
          _myServices = decoded.map((json) => Service.fromJson(json)).toList();
          print(
              '[VendorService] Loaded ${_myServices.length} services successfully.');
          developer.log('[VendorService] Loaded ${_myServices.length} services',
              name: 'VendorService');
        } else {
          print('[VendorService] Unexpected response format: ${response.body}');
          developer.log(
              '[VendorService] Unexpected response format: ${response.body}',
              name: 'VendorService');
          _myServices = [];
        }
      } else {
        developer.log(
            '[VendorService] Error loading services: ${response.body}',
            name: 'VendorService');
      }
      notifyListeners();
    } catch (e) {
      print('[VendorService] Exception while loading services: $e');
      developer.log('Error loading services: $e', name: 'VendorService');
    } finally {
      _setLoading(false);
      print('[VendorService] Finished loading services');
    }
  }

  Future<bool> addService(
      Service service, String? token, String? currentUserId) async {
    if (currentUserId == null) {
      print('[VendorService] currentUserId is null, cannot add service.');
      return false;
    }
    try {
      final serviceData = service.toJson();
      serviceData['hostId'] = currentUserId;
      print('[VendorService] Adding service: $serviceData');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $token"
        },
        body: jsonEncode(serviceData),
      );
      print(
          '[VendorService] Add service response status: ${response.statusCode}');
      if (response.statusCode == 201) {
        print('[VendorService] Service added successfully.');
        await loadMyServices(token);
        return true;
      }
      print('[VendorService] Failed to add service: ${response.body}');
      return false;
    } catch (e) {
      print('[VendorService] Exception while adding service: $e');
      developer.log('Error adding service: $e', name: 'VendorService');
      return false;
    }
  }

  Future<bool> updateService(
      String serviceId, Map<String, dynamic> updates, String? token) async {
    try {
      print('[VendorService] Updating service $serviceId with $updates');
      final response = await http.put(
        Uri.parse('$_baseUrl/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $token"
        },
        body: jsonEncode(updates),
      );
      print(
          '[VendorService] Update service response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('[VendorService] Service updated successfully.');
        await loadMyServices(token);
        return true;
      }
      print('[VendorService] Failed to update service: ${response.body}');
      return false;
    } catch (e) {
      print('[VendorService] Exception while updating service: $e');
      developer.log('Error updating service: $e', name: 'VendorService');
      return false;
    }
  }

  Future<bool> deleteService(
    String serviceId,
    String? token,
  ) async {
    try {
      print('[VendorService] Deleting service $serviceId');
      final response = await http.delete(
        Uri.parse('$_baseUrl/services/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $token"
        },
      );
      print(
          '[VendorService] Delete service response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('[VendorService] Service deleted successfully.');
        await loadMyServices(token);
        return true;
      }
      print('[VendorService] Failed to delete service: ${response.body}');
      return false;
    } catch (e) {
      print('[VendorService] Exception while deleting service: $e');
      developer.log('Error deleting service: $e', name: 'VendorService');
      return false;
    }
  }

  Future<void> loadServiceRequests(String? token, String? currentUserId) async {
    if (currentUserId == null) return;
    _setLoading(true);
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/requests?vendorId=$currentUserId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $token"
        },
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final allRequests =
            data.map((json) => ServiceRequest.fromJson(json)).toList();
        _pendingRequests = allRequests.where((req) => req.isPending).toList();
        _activeServices = allRequests
            .where((req) => req.isAccepted || req.isInProgress)
            .toList();
        _completedServices =
            allRequests.where((req) => req.isCompleted).toList();
        developer.log('Loaded requests', name: 'VendorService');
      }
      notifyListeners();
    } catch (e) {
      developer.log('Error loading service requests: $e',
          name: 'VendorService');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> acceptServiceRequest(
      String requestId, String? token, String? currentUserId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/requests/$requestId/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $token"
        },
      );
      if (response.statusCode == 200) {
        await loadServiceRequests(
          token,
          currentUserId,
        );
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error accepting service request: $e',
          name: 'VendorService');
      return false;
    }
  }

  Future<bool> rejectServiceRequest(
    String requestId,
    String? token,
    String? currentUserId,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/requests/$requestId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $token"
        },
      );
      if (response.statusCode == 200) {
        await loadServiceRequests(
          token,
          currentUserId,
        );
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error rejecting service request: $e',
          name: 'VendorService');
      return false;
    }
  }

  Future<bool> updateServiceStatus(
    String requestId,
    ServiceRequestStatus status,
    String? token,
    String? currentUserId,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/requests/$requestId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $token"
        },
        body: jsonEncode({'status': status.toString().split('.').last}),
      );
      if (response.statusCode == 200) {
        await loadServiceRequests(
          token,
          currentUserId,
        );
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error updating service status: $e', name: 'VendorService');
      return false;
    }
  }

  Future<void> loadConversations(
    String? token,
    String? currentUserId,
  ) async {
    if (currentUserId == null) return;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/conversations?vendorId=$currentUserId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $token"
        },
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _conversations =
            data.map((json) => Conversation.fromJson(json)).toList();
        developer.log('Loaded conversations', name: 'VendorService');
      }
      notifyListeners();
    } catch (e) {
      developer.log('Error loading conversations: $e', name: 'VendorService');
    }
  }

  Future<bool> sendMessage(String conversationId, String content,
      MessageType type, String? token, String? currentUserId) async {
    if (currentUserId == null) return false;
    try {
      final messageData = {
        'conversationId': conversationId,
        'senderId': currentUserId,
        'senderType': 'vendor',
        'content': content,
        'type': type.toString().split('.').last,
      };
      final response = await http.post(
        Uri.parse('$_baseUrl/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(messageData),
      );
      if (response.statusCode == 201) {
        await loadConversations(
          token,
          currentUserId,
        );
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error sending message: $e', name: 'VendorService');
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> initialize(String userId, String token) async {
    // setCurrentUserId(userId);
    // setCurrentUserToken(token);
    // print(
    //     '[VENDOR_SERVICE] Initializing VendorService with userId: $userId and token: $token');
    await loadMyServices(token);
    await loadServiceRequests(token, userId);
  }
}
