import 'dart:developer' as developer;
import '../models/message.dart';

class MessagingService {
  // Mock data for conversations - in a real app, this would come from a backend API
  static List<Conversation> _mockConversations = [
    Conversation(
      id: 'conv_1',
      serviceId: 'service_1',
      serviceTitle: 'House Cleaning Service',
      clientId: 'client_1',
      clientName: 'John Doe',
      vendorId: 'vendor_1',
      vendorName: 'CleanPro Services',
      lastMessage: Message(
        id: 'msg_1',
        conversationId: 'conv_1',
        senderId: 'vendor_1',
        senderName: 'CleanPro Services',
        senderType: 'vendor',
        receiverId: 'client_1',
        receiverName: 'John Doe',
        content: 'Hi! I can start the cleaning service tomorrow at 10 AM. Does that work for you?',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
      unreadCount: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    Conversation(
      id: 'conv_2',
      serviceId: 'service_2',
      serviceTitle: 'Plumbing Repair',
      clientId: 'client_1',
      clientName: 'John Doe',
      vendorId: 'vendor_2',
      vendorName: 'Fix-It Plumbing',
      lastMessage: Message(
        id: 'msg_2',
        conversationId: 'conv_2',
        senderId: 'client_1',
        senderName: 'John Doe',
        senderType: 'client',
        receiverId: 'vendor_2',
        receiverName: 'Fix-It Plumbing',
        content: 'Thank you for the quick service! The leak is fixed perfectly.',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      unreadCount: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Conversation(
      id: 'conv_3',
      serviceId: 'service_3',
      serviceTitle: 'Electrical Installation',
      clientId: 'client_1',
      clientName: 'John Doe',
      vendorId: 'vendor_3',
      vendorName: 'PowerUp Electric',
      lastMessage: Message(
        id: 'msg_3',
        conversationId: 'conv_3',
        senderId: 'vendor_3',
        senderName: 'PowerUp Electric',
        senderType: 'vendor',
        receiverId: 'client_1',
        receiverName: 'John Doe',
        content: 'I\'ll need to check the electrical panel first. Can I schedule a visit?',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
      unreadCount: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static List<Message> _mockMessages = [
    // Messages for conversation 1 (House Cleaning)
    Message(
      id: 'msg_1_1',
      conversationId: 'conv_1',
      senderId: 'client_1',
      senderName: 'John Doe',
      senderType: 'client',
      receiverId: 'vendor_1',
      receiverName: 'CleanPro Services',
      content: 'Hi, I need a house cleaning service for my 3-bedroom apartment.',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      isRead: true,
    ),
    Message(
      id: 'msg_1_2',
      conversationId: 'conv_1',
      senderId: 'vendor_1',
      senderName: 'CleanPro Services',
      senderType: 'vendor',
      receiverId: 'client_1',
      receiverName: 'John Doe',
      content: 'Hello! I\'d be happy to help with your house cleaning. What specific areas would you like us to focus on?',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      isRead: true,
    ),
    Message(
      id: 'msg_1_3',
      conversationId: 'conv_1',
      senderId: 'client_1',
      senderName: 'John Doe',
      senderType: 'client',
      receiverId: 'vendor_1',
      receiverName: 'CleanPro Services',
      content: 'I need deep cleaning for the kitchen, bathrooms, and living room. Also, can you do the windows?',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(days: 1, minutes: 45)),
      isRead: true,
    ),
    Message(
      id: 'msg_1_4',
      conversationId: 'conv_1',
      senderId: 'vendor_1',
      senderName: 'CleanPro Services',
      senderType: 'vendor',
      receiverId: 'client_1',
      receiverName: 'John Doe',
      content: 'Absolutely! We can do all of that. The service will take about 4-5 hours and cost €120.',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(days: 1, minutes: 30)),
      isRead: true,
    ),
    Message(
      id: 'msg_1_5',
      conversationId: 'conv_1',
      senderId: 'vendor_1',
      senderName: 'CleanPro Services',
      senderType: 'vendor',
      receiverId: 'client_1',
      receiverName: 'John Doe',
      content: 'Hi! I can start the cleaning service tomorrow at 10 AM. Does that work for you?',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
    ),
    
    // Messages for conversation 2 (Plumbing)
    Message(
      id: 'msg_2_1',
      conversationId: 'conv_2',
      senderId: 'client_1',
      senderName: 'John Doe',
      senderType: 'client',
      receiverId: 'vendor_2',
      receiverName: 'Fix-It Plumbing',
      content: 'I have a leak under my kitchen sink. Can you help?',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
    Message(
      id: 'msg_2_2',
      conversationId: 'conv_2',
      senderId: 'vendor_2',
      senderName: 'Fix-It Plumbing',
      senderType: 'vendor',
      receiverId: 'client_1',
      receiverName: 'John Doe',
      content: 'I can come by today afternoon to fix it. It should take about an hour.',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(days: 3, hours: -2)),
      isRead: true,
    ),
    Message(
      id: 'msg_2_3',
      conversationId: 'conv_2',
      senderId: 'client_1',
      senderName: 'John Doe',
      senderType: 'client',
      receiverId: 'vendor_2',
      receiverName: 'Fix-It Plumbing',
      content: 'Thank you for the quick service! The leak is fixed perfectly.',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
    ),
  ];

  Future<List<Conversation>> getConversations(String userId) async {
    developer.log('📱 Getting conversations for user: $userId', name: 'MessagingService');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Filter conversations for the current user
    final userConversations = _mockConversations
        .where((conv) => conv.clientId == userId || conv.vendorId == userId)
        .toList();
    
    // Sort by updated date (most recent first)
    userConversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    developer.log('📱 Found ${userConversations.length} conversations', name: 'MessagingService');
    return userConversations;
  }

  Future<List<Message>> getMessages(String conversationId) async {
    developer.log('💬 Getting messages for conversation: $conversationId', name: 'MessagingService');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    final messages = _mockMessages
        .where((msg) => msg.conversationId == conversationId)
        .toList();
    
    // Sort by timestamp (oldest first for chat display)
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    developer.log('💬 Found ${messages.length} messages', name: 'MessagingService');
    return messages;
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String receiverId,
    required String receiverName,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    developer.log('📤 Sending message from $senderId to $receiverId', name: 'MessagingService');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final message = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderType: senderType,
      receiverId: receiverId,
      receiverName: receiverName,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
    );
    
    // Add to mock messages
    _mockMessages.add(message);
    
    // Update the conversation's last message and timestamp
    final conversationIndex = _mockConversations.indexWhere((conv) => conv.id == conversationId);
    if (conversationIndex != -1) {
      _mockConversations[conversationIndex] = Conversation(
        id: _mockConversations[conversationIndex].id,
        serviceId: _mockConversations[conversationIndex].serviceId,
        serviceTitle: _mockConversations[conversationIndex].serviceTitle,
        clientId: _mockConversations[conversationIndex].clientId,
        clientName: _mockConversations[conversationIndex].clientName,
        vendorId: _mockConversations[conversationIndex].vendorId,
        vendorName: _mockConversations[conversationIndex].vendorName,
        lastMessage: message,
        unreadCount: senderType == 'client' ? 0 : _mockConversations[conversationIndex].unreadCount + 1,
        createdAt: _mockConversations[conversationIndex].createdAt,
        updatedAt: DateTime.now(),
      );
    }
    
    developer.log('📤 Message sent successfully: ${message.id}', name: 'MessagingService');
    return message;
  }

  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    developer.log('✅ Marking messages as read for conversation: $conversationId', name: 'MessagingService');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Mark messages as read
    for (int i = 0; i < _mockMessages.length; i++) {
      if (_mockMessages[i].conversationId == conversationId && 
          _mockMessages[i].receiverId == userId) {
        _mockMessages[i] = Message(
          id: _mockMessages[i].id,
          conversationId: _mockMessages[i].conversationId,
          senderId: _mockMessages[i].senderId,
          senderName: _mockMessages[i].senderName,
          senderType: _mockMessages[i].senderType,
          receiverId: _mockMessages[i].receiverId,
          receiverName: _mockMessages[i].receiverName,
          content: _mockMessages[i].content,
          type: _mockMessages[i].type,
          timestamp: _mockMessages[i].timestamp,
          isRead: true,
          imageUrl: _mockMessages[i].imageUrl,
          attachmentUrl: _mockMessages[i].attachmentUrl,
        );
      }
    }
    
    // Update conversation unread count
    final conversationIndex = _mockConversations.indexWhere((conv) => conv.id == conversationId);
    if (conversationIndex != -1) {
      _mockConversations[conversationIndex] = Conversation(
        id: _mockConversations[conversationIndex].id,
        serviceId: _mockConversations[conversationIndex].serviceId,
        serviceTitle: _mockConversations[conversationIndex].serviceTitle,
        clientId: _mockConversations[conversationIndex].clientId,
        clientName: _mockConversations[conversationIndex].clientName,
        vendorId: _mockConversations[conversationIndex].vendorId,
        vendorName: _mockConversations[conversationIndex].vendorName,
        lastMessage: _mockConversations[conversationIndex].lastMessage,
        unreadCount: 0,
        createdAt: _mockConversations[conversationIndex].createdAt,
        updatedAt: _mockConversations[conversationIndex].updatedAt,
      );
    }
    
    developer.log('✅ Messages marked as read', name: 'MessagingService');
  }

  int getTotalUnreadCount(String userId) {
    return _mockConversations
        .where((conv) => conv.clientId == userId || conv.vendorId == userId)
        .fold(0, (sum, conv) => sum + conv.unreadCount);
  }
}
