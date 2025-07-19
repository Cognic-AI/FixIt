import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../models/service_request.dart';
import '../../services/service_request_service.dart';

class RequestedServicesPage extends StatefulWidget {
  const RequestedServicesPage({
    super.key,
    required this.clientId,
    required this.token,
  });

  final String clientId;
  final String token;

  @override
  State<RequestedServicesPage> createState() => _RequestedServicesPageState();
}

class _RequestedServicesPageState extends State<RequestedServicesPage>
    with SingleTickerProviderStateMixin {
  final ServiceRequestService _requestService = ServiceRequestService();
  late TabController _tabController;
  
  List<ServiceRequest> _allRequests = [];
  Map<RequestStatus, int> _statusCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRequestData();
  }

  Future<void> _loadRequestData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final requests = await _requestService.getServiceRequests(widget.clientId);
      final counts = await _requestService.getRequestCounts(widget.clientId);
      
      setState(() {
        _allRequests = requests;
        _statusCounts = counts;
        _isLoading = false;
      });
      
      developer.log('📋 Loaded ${requests.length} requests', name: 'RequestedServicesPage');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      developer.log('Error loading requests: $e', name: 'RequestedServicesPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ServiceRequest> _getRequestsByStatus(RequestStatus status) {
    return _allRequests.where((request) => request.status == status).toList();
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.active:
        return const Color(0xFF2563EB);
      case RequestStatus.completed:
        return const Color(0xFF10B981);
      case RequestStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Icons.schedule;
      case RequestStatus.active:
        return Icons.work;
      case RequestStatus.completed:
        return Icons.check_circle;
      case RequestStatus.rejected:
        return Icons.cancel;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cleaning':
        return Icons.cleaning_services;
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'painting':
        return Icons.format_paint;
      case 'gardening':
        return Icons.grass;
      case 'handyman':
        return Icons.build;
      case 'moving':
        return Icons.moving;
      default:
        return Icons.handyman;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return 'Today $displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } else {
      // Older - show date
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildRequestCard(ServiceRequest request) {
    final statusColor = _getStatusColor(request.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showRequestDetails(request),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(request.serviceCategory),
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.serviceTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.vendorName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(request.status),
                                size: 14,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                request.statusDisplayName,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '€${request.servicePrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  request.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Location and Date Row
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        request.location,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(request.updatedAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                // Scheduled Date for Active requests
                if (request.status == RequestStatus.active && request.scheduledDate != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Scheduled: ${_formatDate(request.scheduledDate!)}',
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Rejection Reason for Rejected requests
                if (request.status == RequestStatus.rejected && request.rejectionReason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request.rejectionReason!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(RequestStatus status) {
    String title, message;
    IconData icon;
    
    switch (status) {
      case RequestStatus.pending:
        title = 'No Pending Requests';
        message = 'You don\'t have any pending service requests.';
        icon = Icons.schedule;
        break;
      case RequestStatus.active:
        title = 'No Active Services';
        message = 'You don\'t have any active services at the moment.';
        icon = Icons.work;
        break;
      case RequestStatus.completed:
        title = 'No Completed Services';
        message = 'You haven\'t completed any services yet.';
        icon = Icons.check_circle;
        break;
      case RequestStatus.rejected:
        title = 'No Rejected Requests';
        message = 'You don\'t have any rejected requests.';
        icon = Icons.cancel;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              icon,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showRequestDetails(ServiceRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(request.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(request.serviceCategory),
                      color: _getStatusColor(request.status),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.serviceTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          request.vendorName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getStatusColor(request.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(request.status),
                            color: _getStatusColor(request.status),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.statusDisplayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(request.status),
                                ),
                              ),
                              Text(
                                request.statusDescription,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      request.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Details
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildDetailRow(Icons.location_on, 'Location', request.location),
                    _buildDetailRow(Icons.euro, 'Price', '€${request.servicePrice.toStringAsFixed(2)}'),
                    _buildDetailRow(Icons.account_balance_wallet, 'Your Budget', '€${request.budget.toStringAsFixed(2)}'),
                    _buildDetailRow(Icons.access_time, 'Requested', _formatDate(request.createdAt)),
                    
                    if (request.scheduledDate != null)
                      _buildDetailRow(Icons.event, 'Scheduled', _formatDate(request.scheduledDate!)),
                    
                    if (request.notes != null && request.notes!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request.notes!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'My Requests',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              text: 'Pending',
              icon: Badge(
                isLabelVisible: (_statusCounts[RequestStatus.pending] ?? 0) > 0,
                label: Text('${_statusCounts[RequestStatus.pending] ?? 0}'),
                child: const Icon(Icons.schedule),
              ),
            ),
            Tab(
              text: 'Active',
              icon: Badge(
                isLabelVisible: (_statusCounts[RequestStatus.active] ?? 0) > 0,
                label: Text('${_statusCounts[RequestStatus.active] ?? 0}'),
                child: const Icon(Icons.work),
              ),
            ),
            Tab(
              text: 'Completed',
              icon: Badge(
                isLabelVisible: (_statusCounts[RequestStatus.completed] ?? 0) > 0,
                label: Text('${_statusCounts[RequestStatus.completed] ?? 0}'),
                child: const Icon(Icons.check_circle),
              ),
            ),
            Tab(
              text: 'Rejected',
              icon: Badge(
                isLabelVisible: (_statusCounts[RequestStatus.rejected] ?? 0) > 0,
                label: Text('${_statusCounts[RequestStatus.rejected] ?? 0}'),
                child: const Icon(Icons.cancel),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF2563EB),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading your requests...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: RequestStatus.values.map((status) {
                final requests = _getRequestsByStatus(status);
                return requests.isEmpty
                    ? _buildEmptyState(status)
                    : RefreshIndicator(
                        onRefresh: _loadRequestData,
                        color: const Color(0xFF2563EB),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 16, bottom: 24),
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            return _buildRequestCard(requests[index]);
                          },
                        ),
                      );
              }).toList(),
            ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
