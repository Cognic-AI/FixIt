import 'package:fixit/pages/client/chat_page.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../models/service_request.dart';
import '../../models/message.dart';
import '../../services/service_request_service.dart';

class ServiceHistoryPage extends StatefulWidget {
  const ServiceHistoryPage({
    super.key,
    required this.clientId,
    required this.token,
  });

  final String clientId;
  final String token;

  @override
  State<ServiceHistoryPage> createState() => _ServiceHistoryPageState();
}

class _ServiceHistoryPageState extends State<ServiceHistoryPage>
    with SingleTickerProviderStateMixin {
  final ServiceRequestService _requestService = ServiceRequestService();
  late TabController _tabController;

  List<ServiceRequest> _allRequests = [];
  Map<RequestHistoryStatus, int> _statusCounts = {};
  bool _isLoading = true;
  Conversation? _currentConversation;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequestData();
  }

  Future<void> _loadRequestData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final requests = await _requestService.getServiceRequests(widget.token);
      final counts = await _requestService.getRequestCounts(widget.token);

      setState(() {
        _allRequests = requests;
        _statusCounts = {
          RequestHistoryStatus.completed:
              counts[RequestHistoryStatus.completed] ?? 0,
          RequestHistoryStatus.rejected:
              counts[RequestHistoryStatus.rejected] ?? 0,
        };
        _isLoading = false;
      });

      developer.log('📋 Loaded ${requests.length} requests',
          name: 'RequestedServicesPage');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      developer.log('Error loading requests: $e',
          name: 'RequestedServicesPage');
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

  void _loadChatData(
      String conversationId, ServiceRequest serviceRequest) async {
    try {
      final conversation = Conversation(
        id: conversationId,
        serviceId: serviceRequest.serviceId,
        serviceTitle: serviceRequest.serviceTitle,
        clientId: serviceRequest.clientId,
        clientName: serviceRequest.clientName,
        vendorId: serviceRequest.vendorId,
        vendorName: serviceRequest.vendorName,
        createdAt: serviceRequest.createdAt,
        updatedAt: serviceRequest.updatedAt,
        lastMessage: null,
        unreadCount: 0,
      );
      setState(() {
        _currentConversation = conversation;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      developer.log('Error loading chat data: $e',
          name: 'RequestedServicesPage');
      print('Error loading chat data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load chat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ServiceRequest> _getRequestsByStatus(RequestHistoryStatus status) {
    return _allRequests.where((request) => request.status == status).toList();
  }

  Color _getStatusColor(RequestHistoryStatus status) {
    switch (status) {
      case RequestHistoryStatus.completed:
        return const Color(0xFF10B981);
      case RequestHistoryStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(RequestHistoryStatus status) {
    switch (status) {
      case RequestHistoryStatus.completed:
        return Icons.check_circle;
      case RequestHistoryStatus.rejected:
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

  void _openChatPage(ServiceRequest request) {
    try {
      // loads chats for the request
      _loadChatData(request.conversationId, request);

      // Find the conversation for this request if it exists

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            token: widget.token,
            conversation: _currentConversation!,
            currentUserId: widget.clientId,
            request: request, // Pass the service request for details
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildRequestCard(ServiceRequest request) {
    final statusColor = _getStatusColor(request.status as RequestHistoryStatus);

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
          onTap: () => _openChatPage(request),
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
                                _getStatusIcon(
                                    request.status as RequestHistoryStatus),
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

                // Rejection Reason for Rejected requests
                if (request.status == RequestHistoryStatus.rejected &&
                    request.rejectionReason != null) ...[
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

  Widget _buildEmptyState(RequestHistoryStatus status) {
    String title, message;
    IconData icon;

    switch (status) {
      case RequestHistoryStatus.completed:
        title = 'No Completed Services';
        message = 'You haven\'t completed any services yet.';
        icon = Icons.check_circle;
        break;
      case RequestHistoryStatus.rejected:
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Service History',
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
              text: 'Completed',
              icon: Badge(
                isLabelVisible:
                    (_statusCounts[RequestHistoryStatus.completed] ?? 0) > 0,
                label: Text(
                    '${_statusCounts[RequestHistoryStatus.completed] ?? 0}'),
                child: const Icon(Icons.check_circle),
              ),
            ),
            Tab(
              text: 'Rejected',
              icon: Badge(
                isLabelVisible:
                    (_statusCounts[RequestHistoryStatus.rejected] ?? 0) > 0,
                label: Text(
                    '${_statusCounts[RequestHistoryStatus.rejected] ?? 0}'),
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
              children: RequestHistoryStatus.values.map((status) {
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
