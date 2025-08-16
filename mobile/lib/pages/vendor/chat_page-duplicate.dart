import 'package:fixit/models/service_request.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:developer' as developer;
import '../../models/message.dart';
import '../../services/messaging_service.dart';
import '../../widgets/quotation_form.dart';
import '../../widgets/bill_form.dart';
import '../../models/sub_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage(
      {super.key,
      required this.conversation,
      required this.currentUserId,
      required this.token,
      required this.request});

  final Conversation conversation;
  final String currentUserId;
  final String token;
  final ServiceRequest request; // Optional request for service details

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final MessagingService _messagingService = MessagingService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markMessagesAsRead();
    print(widget.request.toJson());
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _messagingService.getConversation(
          widget.request.conversationId,
          widget.request,
          widget.currentUserId,
          widget.token);

      // Safety check for result
      if (result.containsKey('messages')) {
        final messages = result['messages'] as List<Message>? ?? [];
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
        developer.log('Loaded ${messages.length} messages',
            name: 'ChatPage');
      } else {
        setState(() {
          _messages = [];
          _isLoading = false;
        });
        developer.log('No messages found in result', name: 'ChatPage');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      developer.log('Error loading messages: $e', name: 'ChatPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    // try {
    //   await _messagingService.markMessagesAsRead(
    //       widget.conversation.id, widget.currentUserId);
    // } catch (e) {
    //   developer.log('Error marking messages as read: $e', name: 'ChatPage');
    // }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    final tempMessage = content;
    _messageController.clear();

    try {
      final message = await _messagingService.sendMessage(
        conversationId: widget.conversation.id,
        senderId: widget.currentUserId,
        senderName:
            widget.conversation.clientName, // Assuming current user is client
        senderType: 'client',
        receiverId: widget.conversation.vendorId,
        receiverName: widget.conversation.vendorName,
        content: tempMessage,
        token: widget.token,
      );

      setState(() {
        _messages.add(message);
        _isSending = false;
      });
      _scrollToBottom();
      developer.log('Message sent successfully', name: 'ChatPage');
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      _messageController.text = tempMessage; // Restore message on error
      developer.log('Error sending message: $e', name: 'ChatPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentOptions() {
    // Hide bill option if status is pending
    final showBill = widget.request.status != RequestStatus.pending;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Choose Action',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),

            // Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Quotation Option
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    title: const Text(
                      'Send Quotation',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    subtitle: const Text(
                      'Provide pricing for the service',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showQuotationForm();
                    },
                  ),

                  if (showBill) ...[
                    const Divider(),
                    // Bill Option
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.receipt,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      title: const Text(
                        'Send Bill',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      subtitle: const Text(
                        'Final bill for completed service',
                        style: TextStyle(color: Colors.grey),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showBillForm();
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showQuotationForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuotationForm(
        request: widget.request,
        onSubmit: (subServices, notes) {
          _sendQuotation(subServices, notes);
        },
      ),
    );
  }

  void _showBillForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BillForm(
        request: widget.request,
        onSubmit: (serviceDetails, finalAmount, paymentNotes) {
          _sendBill(serviceDetails, finalAmount, paymentNotes);
        },
      ),
    );
  }

  Future<void> _sendQuotation(
      List<SubService> subServices, String notes) async {
    setState(() {
      _isSending = true;
    });

    try {
      final message = await _messagingService.sendQuotation(
        conversationId: widget.conversation.id,
        senderId: widget.currentUserId,
        senderName: widget.conversation.vendorName,
        senderType: 'vendor',
        receiverId: widget.conversation.clientId,
        receiverName: widget.conversation.clientName,
        serviceTitle: widget.request.serviceTitle,
        clientName: widget.request.clientName,
        subServices: subServices,
        notes: notes,
        token: widget.token,
      );

      setState(() {
        _messages.add(message);
        _isSending = false;
      });
      _scrollToBottom();
      developer.log('Quotation sent successfully', name: 'ChatPage');
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      developer.log('Error sending quotation: $e', name: 'ChatPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send quotation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendBill(
      String serviceDetails, double finalAmount, String paymentNotes) async {
    setState(() {
      _isSending = true;
    });

    try {
      final message = await _messagingService.sendBill(
        conversationId: widget.conversation.id,
        senderId: widget.currentUserId,
        senderName: widget.conversation.vendorName,
        senderType: 'vendor',
        receiverId: widget.conversation.clientId,
        receiverName: widget.conversation.clientName,
        serviceTitle: widget.request.serviceTitle,
        clientName: widget.request.clientName,
        serviceDetails: serviceDetails,
        finalAmount: finalAmount,
        paymentNotes: paymentNotes,
        token: widget.token,
      );

      setState(() {
        _messages.add(message);
        _isSending = false;
      });
      _scrollToBottom();
      developer.log('📤 Bill sent successfully', name: 'ChatPage');
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      developer.log('Error sending bill: $e', name: 'ChatPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send bill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatMessageDate(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);
    final difference = today.difference(messageDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
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

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.accepted:
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
      case RequestStatus.accepted:
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
                          request.clientName,
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

                    // _buildDetailRow(
                    //     Icons.location_on, 'Location', request.location),
                    GestureDetector(
                      onTap: () =>
                          _showLocationOnMap(widget.request.clientLocation),
                      child: _buildDetailRow(
                          Icons.location_on,
                          'Client Location',
                          "${widget.request.clientLocation} (Tap to view on map)"),
                    ),
                    _buildDetailRow(Icons.euro, 'Price',
                        '€${request.servicePrice.toStringAsFixed(2)}'),
                    _buildDetailRow(Icons.account_balance_wallet, 'Your Budget',
                        '€${request.budget}'),
                    _buildDetailRow(Icons.access_time, 'Requested',
                        _formatDate(request.createdAt)),

                    if (request.scheduledDate != null)
                      _buildDetailRow(Icons.event, 'Scheduled',
                          _formatDate(request.scheduledDate!)),

                    if (request.note != null && request.note!.isNotEmpty) ...[
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
                        request.note!,
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

  void _showLocationOnMap(String location) async {
    try {
      // Parse the location string (assuming format "latitude, longitude")
      final parts = location.split(',');
      if (parts.length != 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid location format')),
        );
        return;
      }

      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());

      if (lat == null || lng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid location coordinates')),
        );
        return;
      }

      final locationPoint = LatLng(lat, lng);

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: locationPoint,
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('location'),
                  position: locationPoint,
                ),
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error showing location: $e')),
      );
    }
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

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatMessageDate(date),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    // Check if it's a special message type
    final isQuotation = message.type == MessageType.quotation;
    final isBill = message.type == MessageType.bill;
    final isSpecialMessage = isQuotation || isBill;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                widget.request.clientId == message.senderId
                    ? widget.conversation.clientName[0].toUpperCase()
                    : widget.conversation.vendorName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe && !isSpecialMessage
                    ? const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                      )
                    : null,
                color: isMe && !isSpecialMessage
                    ? null
                    : isSpecialMessage
                        ? (isQuotation
                            ? const Color(0xFF2563EB).withOpacity(0.1)
                            : const Color(0xFF10B981).withOpacity(0.1))
                        : Colors.grey.shade100,
                border: isSpecialMessage
                    ? Border.all(
                        color: isQuotation
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF10B981),
                        width: 1.5,
                      )
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 0,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Special header for quotation/bill
                  if (isSpecialMessage) ...[
                    Row(
                      children: [
                        Icon(
                          isQuotation ? Icons.receipt_long : Icons.receipt,
                          color: isQuotation
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF10B981),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isQuotation ? 'QUOTATION' : 'FINAL BILL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isQuotation
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Message content
                  _buildMessageContent(message, isMe, isSpecialMessage),

                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe && !isSpecialMessage
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey[500],
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: isSpecialMessage
                              ? Colors.grey[500]
                              : message.isRead
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2563EB),
              child: Text(
                widget.request.clientId == message.senderId
                    ? widget.conversation.clientName[0].toUpperCase()
                    : widget.conversation.vendorName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(
      Message message, bool isMe, bool isSpecialMessage) {
    if (isSpecialMessage) {
      // Parse and format special message content
      return _buildFormattedContent(message.content);
    } else {
      // Regular text message
      return Text(
        message.content,
        style: TextStyle(
          fontSize: 16,
          color: isMe ? Colors.white : const Color(0xFF1F2937),
          height: 1.3,
        ),
      );
    }
  }

  Widget _buildFormattedContent(String content) {
    try {
      // Safety check for null or empty content
      if (content.isEmpty) {
        return const SizedBox.shrink();
      }

      final lines = content.split('\n');
      List<Widget> widgets = [];

      for (String line in lines) {
        final trimmedLine = line.trim();

        if (trimmedLine.isEmpty) {
          widgets.add(const SizedBox(height: 4));
          continue;
        }

        // Handle headers like **📋 QUOTATION** or **🧾 FINAL BILL**
        if (trimmedLine.startsWith('**') &&
            trimmedLine.endsWith('**') &&
            !trimmedLine.contains(':')) {
          final headerText = trimmedLine.replaceAll('**', '');
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                headerText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
          continue;
        }

        // Handle bold key-value pairs like **Service:** Service Name
        if (trimmedLine.startsWith('**') && trimmedLine.contains(':')) {
          final colonIndex = trimmedLine.indexOf(':');
          if (colonIndex >= 0 && colonIndex < trimmedLine.length - 1) {
            final keyPart =
                trimmedLine.substring(0, colonIndex + 1).replaceAll('**', '');
            final valuePart = trimmedLine.substring(colonIndex + 1).trim();

            widgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      keyPart,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        valuePart,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
            continue;
          }
        }

        // Handle dividers
        if (trimmedLine.startsWith('---')) {
          widgets.add(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(thickness: 1, color: Colors.grey),
            ),
          );
          continue;
        }

        // Handle italic text at the end
        if (trimmedLine.startsWith('*') &&
            trimmedLine.endsWith('*') &&
            !trimmedLine.startsWith('**')) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                trimmedLine.replaceAll('*', ''),
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
          continue;
        }

        // Handle numbered lists for sub-services
        try {
          if (RegExp(r'^\d+\.').hasMatch(trimmedLine)) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(
                  trimmedLine,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            );
            continue;
          }
        } catch (regexError) {
          // If regex fails, treat as regular text
          developer.log('RegExp error: $regexError', name: 'ChatPage');
        }

        // Regular text
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              trimmedLine,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      );
    } catch (e) {
      // If there's any error in formatting, fall back to plain text display
      developer.log('Error formatting message content: $e', name: 'ChatPage');
      return Text(
        content,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1F2937),
        ),
      );
    }
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
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
                Icons.chat_bubble_outline,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Start the conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to ${widget.conversation.vendorName}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    List<Widget> messageWidgets = [];
    DateTime? currentDate;

    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      final messageDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );

      // Add date separator if needed
      if (currentDate == null || !messageDate.isAtSameMomentAs(currentDate)) {
        messageWidgets.add(_buildDateSeparator(message.timestamp));
        currentDate = messageDate;
      }

      // Add message bubble
      final isMe = message.senderId == widget.currentUserId;
      messageWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _buildMessageBubble(message, isMe),
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: messageWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.conversation.serviceTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              widget.conversation.clientName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              // Handle phone call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Handle more options
              // add "info" option

              _showRequestDetails(widget.request);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages Area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2563EB),
                    ),
                  )
                : _buildMessagesList(),
          ),

          // Message Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 0,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Attachment btn
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _showAttachmentOptions,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.attachment,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Message Input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Send Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _isSending ? null : _sendMessage,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: _isSending
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
