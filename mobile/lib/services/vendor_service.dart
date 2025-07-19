import 'package:fixit/models/request.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import '../models/service.dart';
import '../models/message.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VendorService extends ChangeNotifier {
  static final String _baseUrl =
      dotenv.env['VENDOR_SERVICE_URL'] ?? 'http://localhost:8084/api/services';
  static final String _baseRequestUrl =
      dotenv.env['REQUEST_SERVICE_URL'] ?? 'http://localhost:8086/api/requests';
  List<Service> _myServices = [];
  List<Request> _pendingRequests = [];
  List<Request> _activeServices = [];
  List<Request> _completedServices = [];
  List<Conversation> _conversations = [];
  List<Request> _rejectedServices = [];
  bool _isLoading = false;

  List<Service> get myServices => _myServices;
  List<Request> get pendingRequests => _pendingRequests;
  List<Request> get activeServices => _activeServices;
  List<Request> get completedServices => _completedServices;
  List<Request> get rejectedServices => _rejectedServices;
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

  Future<void> loadServiceRequests(String? token) async {
    _setLoading(true);
    try {
      print(
          '[VendorService] Loading service requests from $_baseRequestUrl/my');
      final response = await http.get(
        Uri.parse("$_baseRequestUrl/my"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $token"
        },
      );
      print('[VendorService] Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)["requests"];
        print(
            '[VendorService] Loaded ${data.length} service requests successfully.');
        print('[VendorService] Parsing service requests...');
        final allRequests =
            data.map((json) => Request.fromJson(json)).cast<Request>().toList();
        print('[VendorService] Total requests loaded: ${allRequests.length}');
        _pendingRequests = allRequests.where((req) => req.isPending).toList();
        print('[VendorService] Pending requests: ${_pendingRequests.length}');
        _activeServices = allRequests
            .where((req) => req.isAccepted || req.isAccepted)
            .toList();
        print('[VendorService] Active services: ${_activeServices.length}');
        _completedServices =
            allRequests.where((req) => req.isCompleted).toList();
        print(
            '[VendorService] Completed services: ${_completedServices.length}');
        _rejectedServices =
            allRequests.where((req) => req.isCancelled).toList();
        print('[VendorService] Rejected services: ${_rejectedServices.length}');
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
      print('[VendorService] Accepting service request: $requestId');
      final response = await http.put(
        Uri.parse('$_baseRequestUrl/$requestId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $token"
        },
        body: jsonEncode({
          "state": "accepted",
        }),
      );
      print(
          '[VendorService] Accept service request response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('[VendorService] Service request accepted successfully.');
        await loadServiceRequests(token);
        return true;
      }
      print(
          '[VendorService] Failed to accept service request: ${response.body}');
      return false;
    } catch (e) {
      print('[VendorService] Exception while accepting service request: $e');
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
        Uri.parse('$_baseRequestUrl/$requestId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $token"
        },
        body: jsonEncode({
          "state": "rejected",
        }),
      );
      if (response.statusCode == 200) {
        await loadServiceRequests(
          token,
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

  Future<bool> completeServiceRequest(
    String requestId,
    String? token,
    String? currentUserId,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseRequestUrl/$requestId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $token"
        },
        body: jsonEncode({
          "state": "completed",
        }),
      );
      if (response.statusCode == 200) {
        await loadServiceRequests(
          token,
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
    await loadServiceRequests(
      token,
    );
  }
}
