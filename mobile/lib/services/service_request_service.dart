import 'dart:developer' as developer;
import '../models/service_request.dart';

class ServiceRequestService {
  // Mock data for service requests - in a real app, this would come from a backend API
  static List<ServiceRequest> _mockRequests = [
    ServiceRequest(
      id: 'req_1',
      clientId: 'client_1',
      clientName: 'John Doe',
      vendorId: 'vendor_1',
      vendorName: 'CleanPro Services',
      serviceId: 'service_1',
      serviceTitle: 'House Cleaning Service',
      serviceCategory: 'cleaning',
      description: 'Deep cleaning for 3-bedroom apartment including kitchen, bathrooms, and living room',
      location: 'Downtown Apartment, 123 Main St',
      budget: 120.0,
      servicePrice: 100.0,
      status: RequestStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      notes: 'Please focus on kitchen and bathrooms',
    ),
    ServiceRequest(
      id: 'req_2',
      clientId: 'client_1',
      clientName: 'John Doe',
      vendorId: 'vendor_2',
      vendorName: 'Fix-It Plumbing',
      serviceId: 'service_2',
      serviceTitle: 'Plumbing Repair',
      serviceCategory: 'plumbing',
      description: 'Fix leaking kitchen sink and check bathroom faucets',
      location: 'Home Address, 456 Oak Avenue',
      budget: 80.0,
      servicePrice: 75.0,
      status: RequestStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      scheduledDate: DateTime.now().add(const Duration(days: 1)),
      notes: 'Available weekdays after 2 PM',
    ),
    ServiceRequest(
      id: 'req_3',
      clientId: 'client_1',
      clientName: 'John Doe',
      vendorId: 'vendor_3',
      vendorName: 'PowerUp Electric',
      serviceId: 'service_3',
      serviceTitle: 'Electrical Installation',
      serviceCategory: 'electrical',
      description: 'Install new ceiling fan in bedroom and fix hallway light switch',
      location: 'Home Address, 456 Oak Avenue',
      budget: 150.0,
      servicePrice: 140.0,
      status: RequestStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      scheduledDate: DateTime.now().subtract(const Duration(days: 3)),
      notes: 'Excellent work, very professional',
    ),
    ServiceRequest(
      id: 'req_4',
      clientId: 'client_1',
      clientName: 'John Doe',
      vendorId: 'vendor_4',
      vendorName: 'GreenThumb Gardening',
      serviceId: 'service_4',
      serviceTitle: 'Garden Maintenance',
      serviceCategory: 'gardening',
      description: 'Weekly garden maintenance and lawn mowing',
      location: 'Home Address, 456 Oak Avenue',
      budget: 60.0,
      servicePrice: 80.0,
      status: RequestStatus.rejected,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      rejectionReason: 'Price too high for the requested service',
      notes: 'Looking for more budget-friendly option',
    ),
    ServiceRequest(
      id: 'req_5',
      clientId: 'client_1',
      clientName: 'John Doe',
      vendorId: 'vendor_5',
      vendorName: 'Handy Helper',
      serviceId: 'service_5',
      serviceTitle: 'Furniture Assembly',
      serviceCategory: 'handyman',
      description: 'Assemble IKEA wardrobe and bookshelf',
      location: 'Downtown Apartment, 123 Main St',
      budget: 100.0,
      servicePrice: 90.0,
      status: RequestStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      scheduledDate: DateTime.now().add(const Duration(days: 2)),
      notes: 'Have all tools ready',
    ),
    ServiceRequest(
      id: 'req_6',
      clientId: 'client_1',
      clientName: 'John Doe',
      vendorId: 'vendor_6',
      vendorName: 'Perfect Paint Pro',
      serviceId: 'service_6',
      serviceTitle: 'Room Painting',
      serviceCategory: 'painting',
      description: 'Paint bedroom walls - light blue color',
      location: 'Home Address, 456 Oak Avenue',
      budget: 200.0,
      servicePrice: 180.0,
      status: RequestStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      scheduledDate: DateTime.now().subtract(const Duration(days: 10)),
      notes: 'Beautiful work, highly recommended!',
    ),
  ];

  Future<List<ServiceRequest>> getServiceRequests(String clientId, {RequestStatus? status}) async {
    developer.log('📋 Getting service requests for client: $clientId', name: 'ServiceRequestService');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Filter requests for the current client
    var requests = _mockRequests.where((req) => req.clientId == clientId).toList();
    
    // Filter by status if provided
    if (status != null) {
      requests = requests.where((req) => req.status == status).toList();
    }
    
    // Sort by updated date (most recent first)
    requests.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    developer.log('📋 Found ${requests.length} requests${status != null ? " with status ${status.toString().split('.').last}" : ""}', 
        name: 'ServiceRequestService');
    return requests;
  }

  Future<Map<RequestStatus, int>> getRequestCounts(String clientId) async {
    developer.log('📊 Getting request counts for client: $clientId', name: 'ServiceRequestService');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    final requests = _mockRequests.where((req) => req.clientId == clientId).toList();
    
    final counts = <RequestStatus, int>{};
    for (final status in RequestStatus.values) {
      counts[status] = requests.where((req) => req.status == status).length;
    }
    
    developer.log('📊 Request counts: ${counts.toString()}', name: 'ServiceRequestService');
    return counts;
  }

  Future<ServiceRequest> updateRequestStatus(String requestId, RequestStatus newStatus, {String? reason}) async {
    developer.log('🔄 Updating request $requestId status to ${newStatus.toString().split('.').last}', 
        name: 'ServiceRequestService');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final index = _mockRequests.indexWhere((req) => req.id == requestId);
    if (index == -1) {
      throw Exception('Service request not found');
    }
    
    final oldRequest = _mockRequests[index];
    final updatedRequest = ServiceRequest(
      id: oldRequest.id,
      clientId: oldRequest.clientId,
      clientName: oldRequest.clientName,
      vendorId: oldRequest.vendorId,
      vendorName: oldRequest.vendorName,
      serviceId: oldRequest.serviceId,
      serviceTitle: oldRequest.serviceTitle,
      serviceCategory: oldRequest.serviceCategory,
      description: oldRequest.description,
      location: oldRequest.location,
      budget: oldRequest.budget,
      servicePrice: oldRequest.servicePrice,
      status: newStatus,
      createdAt: oldRequest.createdAt,
      updatedAt: DateTime.now(),
      rejectionReason: newStatus == RequestStatus.rejected ? reason : oldRequest.rejectionReason,
      scheduledDate: oldRequest.scheduledDate,
      notes: oldRequest.notes,
    );
    
    _mockRequests[index] = updatedRequest;
    
    developer.log('🔄 Request status updated successfully', name: 'ServiceRequestService');
    return updatedRequest;
  }

  Future<void> cancelRequest(String requestId, String reason) async {
    await updateRequestStatus(requestId, RequestStatus.rejected, reason: reason);
  }
}
