import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../models/service.dart';
import '../models/service_request.dart';
import '../models/message.dart';

class VendorService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  String? get currentUserId => _auth.currentUser?.uid;

  // Load vendor's services
  Future<void> loadMyServices() async {
    if (currentUserId == null) return;

    _setLoading(true);
    try {
      developer.log('📊 Loading vendor services', name: 'VendorService');
      print('Loading services for user: $currentUserId');

      final querySnapshot = await _firestore
          .collection('services')
          .where('hostId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      _myServices = querySnapshot.docs
          .map((doc) => Service.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      developer.log('✅ Loaded ${_myServices.length} services',
          name: 'VendorService');
      print('Loaded ${_myServices.length} services for user: $currentUserId');
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      developer.log('❌ Error loading services: $e', name: 'VendorService');
    } finally {
      _setLoading(false);
    }
  }

  // Add new service
  Future<bool> addService(Service service) async {
    if (currentUserId == null) return false;

    try {
      developer.log('➕ Adding new service: ${service.title}',
          name: 'VendorService');

      final serviceData = service.toJson();
      serviceData['hostId'] = currentUserId;
      serviceData['createdAt'] = FieldValue.serverTimestamp();
      serviceData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('services').add(serviceData);

      await loadMyServices(); // Refresh the list
      developer.log('✅ Service added successfully', name: 'VendorService');
      return true;
    } catch (e) {
      developer.log('❌ Error adding service: $e', name: 'VendorService');
      return false;
    }
  }

  // Update service
  Future<bool> updateService(
      String serviceId, Map<String, dynamic> updates) async {
    try {
      developer.log('🔄 Updating service: $serviceId', name: 'VendorService');

      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('services').doc(serviceId).update(updates);

      await loadMyServices(); // Refresh the list
      developer.log('✅ Service updated successfully', name: 'VendorService');
      return true;
    } catch (e) {
      developer.log('❌ Error updating service: $e', name: 'VendorService');
      return false;
    }
  }

  // Delete service
  Future<bool> deleteService(String serviceId) async {
    try {
      developer.log('🗑️ Deleting service: $serviceId', name: 'VendorService');

      await _firestore.collection('services').doc(serviceId).delete();

      await loadMyServices(); // Refresh the list
      developer.log('✅ Service deleted successfully', name: 'VendorService');
      return true;
    } catch (e) {
      developer.log('❌ Error deleting service: $e', name: 'VendorService');
      return false;
    }
  }

  // Load service requests
  Future<void> loadServiceRequests() async {
    if (currentUserId == null) return;

    _setLoading(true);
    try {
      developer.log('📊 Loading service requests', name: 'VendorService');

      final querySnapshot = await _firestore
          .collection('serviceRequests')
          .where('vendorId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      final allRequests = querySnapshot.docs
          .map((doc) => ServiceRequest.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      _pendingRequests = allRequests.where((req) => req.isPending).toList();
      _activeServices = allRequests
          .where((req) => req.isAccepted || req.isInProgress)
          .toList();
      _completedServices = allRequests.where((req) => req.isCompleted).toList();

      developer.log(
          '✅ Loaded requests - Pending: ${_pendingRequests.length}, Active: ${_activeServices.length}, Completed: ${_completedServices.length}',
          name: 'VendorService');
      notifyListeners();
    } catch (e) {
      developer.log('❌ Error loading service requests: $e',
          name: 'VendorService');
    } finally {
      _setLoading(false);
    }
  }

  // Accept service request
  Future<bool> acceptServiceRequest(String requestId) async {
    try {
      developer.log('✅ Accepting service request: $requestId',
          name: 'VendorService');

      await _firestore.collection('serviceRequests').doc(requestId).update({
        'status': 'accepted',
        'acceptedDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadServiceRequests(); // Refresh the list
      developer.log('✅ Service request accepted successfully',
          name: 'VendorService');
      return true;
    } catch (e) {
      developer.log('❌ Error accepting service request: $e',
          name: 'VendorService');
      return false;
    }
  }

  // Reject service request
  Future<bool> rejectServiceRequest(String requestId) async {
    try {
      developer.log('❌ Rejecting service request: $requestId',
          name: 'VendorService');

      await _firestore.collection('serviceRequests').doc(requestId).update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadServiceRequests(); // Refresh the list
      developer.log('✅ Service request rejected successfully',
          name: 'VendorService');
      return true;
    } catch (e) {
      developer.log('❌ Error rejecting service request: $e',
          name: 'VendorService');
      return false;
    }
  }

  // Update service status
  Future<bool> updateServiceStatus(
      String requestId, ServiceRequestStatus status) async {
    try {
      developer.log('🔄 Updating service status: $requestId to $status',
          name: 'VendorService');

      Map<String, dynamic> updates = {
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == ServiceRequestStatus.completed) {
        updates['completedDate'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('serviceRequests')
          .doc(requestId)
          .update(updates);

      await loadServiceRequests(); // Refresh the list
      developer.log('✅ Service status updated successfully',
          name: 'VendorService');
      return true;
    } catch (e) {
      developer.log('❌ Error updating service status: $e',
          name: 'VendorService');
      return false;
    }
  }

  // Load conversations
  Future<void> loadConversations() async {
    if (currentUserId == null) return;

    try {
      developer.log('💬 Loading conversations', name: 'VendorService');

      final querySnapshot = await _firestore
          .collection('conversations')
          .where('vendorId', isEqualTo: currentUserId)
          .orderBy('updatedAt', descending: true)
          .get();

      _conversations = querySnapshot.docs
          .map((doc) => Conversation.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      developer.log('✅ Loaded ${_conversations.length} conversations',
          name: 'VendorService');
      notifyListeners();
    } catch (e) {
      developer.log('❌ Error loading conversations: $e', name: 'VendorService');
    }
  }

  // Send message
  Future<bool> sendMessage(
      String conversationId, String content, MessageType type) async {
    if (currentUserId == null) return false;

    try {
      developer.log('💬 Sending message to conversation: $conversationId',
          name: 'VendorService');

      final messageData = {
        'conversationId': conversationId,
        'senderId': currentUserId,
        'senderType': 'vendor',
        'content': content,
        'type': type.toString().split('.').last,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      await _firestore.collection('messages').add(messageData);

      // Update conversation last message
      await _firestore.collection('conversations').doc(conversationId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log('✅ Message sent successfully', name: 'VendorService');
      return true;
    } catch (e) {
      developer.log('❌ Error sending message: $e', name: 'VendorService');
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Initialize vendor data
  Future<void> initialize() async {
    developer.log('🚀 Initializing VendorService', name: 'VendorService');
    await Future.wait([
      loadMyServices(),
      loadServiceRequests(),
      loadConversations(),
    ]);
    developer.log('✅ VendorService initialized', name: 'VendorService');
  }
}
