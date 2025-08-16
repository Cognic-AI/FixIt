import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/message.dart';
import '../models/service_request.dart';
import '../models/sub_service.dart';

class MessagingService {
  final String _baseUrl = dotenv.env['MESSAGING_SERVICE_URL'] ??
      'http://192.168.1.2:8087/api/chats';
  final String _aiUrl = dotenv.env['AI_URL'] ?? 'http://localhost:8082/api/ai';

  Future<Map<String, dynamic>> getConversation(
    String conversationId,
    ServiceRequest serviceRequest,
    String currentUserId,
    String token,
  ) async {
    developer.log('📱 Getting conversation and messages for: $conversationId',
        name: 'MessagingService');
    print('Getting conversation and messages for: $conversationId');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'conversationId': conversationId}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Error getting conversation: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      print('Response data: ${data.toString()}');

      if (!data['success']) {
        print('Error getting conversation: ${data['message']}');
        throw Exception('API error: ${data['message']}');
      }

      // Extract messages list from API
      final List<dynamic> messagesJson = data['messages'] ?? [];
      print('Messages JSON: $messagesJson');

      final messages =
          messagesJson.map((json) => Message.fromJson(json)).toList();

      // Sort messages by timestamp (oldest first for chat display)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Create conversation object using ServiceRequest data
      final conversation = Conversation(
        id: conversationId,
        serviceId: serviceRequest.serviceId,
        serviceTitle: serviceRequest.serviceTitle,
        clientId: serviceRequest.clientId,
        clientName: serviceRequest.clientName,
        vendorId: serviceRequest.vendorId,
        vendorName: serviceRequest.vendorName,
        lastMessage: messages.isNotEmpty ? messages.last : null,
        unreadCount: messages
            .where((msg) => !msg.isRead && msg.senderId != currentUserId)
            .length,
        createdAt: serviceRequest.createdAt,
        updatedAt: serviceRequest.updatedAt,
      );

      developer.log('Found conversation with ${messages.length} messages',
          name: 'MessagingService');
      print(
          '📱 Found conversation with ${messages.length} messages for $conversationId');

      return {
        'conversation': conversation,
        'messages': messages,
      };
    } catch (e) {
      developer.log('Error getting conversation and messages: $e',
          name: 'MessagingService', error: e);
      print('📱 Error getting conversation and messages: $e');
      rethrow;
    }
  }

  Future<List<Message>> getAiConversation(
      String conversationId, String token) async {
    developer.log('Getting conversation and messages for: $conversationId',
        name: 'MessagingService');
    print('Getting conversation and messages for: $conversationId');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'conversationId': conversationId}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Error getting conversation: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      print('Response data: ${data.toString()}');

      if (!data['success']) {
        print('Error getting conversation: ${data['message']}');
        throw Exception('API error: ${data['message']}');
      }

      // Extract messages list from API
      final List<dynamic> messagesJson = data['messages'] ?? [];
      print('Messages JSON: $messagesJson');

      final messages =
          messagesJson.map((json) => Message.fromJson(json)).toList();

      // Sort messages by timestamp (oldest first for chat display)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return messages;
    } catch (e) {
      developer.log('Error getting conversation and messages: $e',
          name: 'MessagingService', error: e);
      print('Error getting conversation and messages: $e');
      rethrow;
    }
  }

  Future<List<Conversation>> getConversations(
      String userId, String token) async {
    developer.log('Getting conversations for user: $userId',
        name: 'MessagingService');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (!data['success']) {
        throw Exception('API error: ${data['message']}');
      }

      // Extract conversations list from API
      final List<dynamic> conversationsJson = data['conversations'] ?? [];
      final conversations =
          conversationsJson.map((json) => Conversation.fromJson(json)).toList();

      developer.log('Found ${conversations.length} conversations',
          name: 'MessagingService');

      return conversations;
    } catch (e) {
      developer.log('Error getting conversations: $e',
          name: 'MessagingService', error: e);
      rethrow;
    }
  }

  Future<List<Message>> getMessages(String conversationId, String token) async {
    developer.log('Getting messages for conversation: $conversationId',
        name: 'MessagingService');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'conversationId': conversationId}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Error getting messages: ${response.statusCode}');
        throw Exception('Failed to load messages: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (!data['success']) {
        print('Error getting messages: ${data['message']}');
        throw Exception('API error: ${data['message']}');
      }

      final List<dynamic> messagesJson = data['messages'];
      final messages =
          messagesJson.map((json) => Message.fromJson(json)).toList();

      // Sort by timestamp (oldest first for chat display)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      developer.log('Found ${messages.length} messages',
          name: 'MessagingService');
      return messages;
    } catch (e) {
      developer.log('Error getting messages: $e',
          name: 'MessagingService', error: e);
      print('Error getting messages: $e');
      rethrow;
    }
  }

  Future<Message> getLastMessage(String conversationId, String token) async {
    developer.log('Getting last message for conversation: $conversationId',
        name: 'MessagingService');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/conversation/last'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'conversationId': conversationId}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Error getting messages: ${response.statusCode}');
        throw Exception('Failed to load messages: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (!data['success']) {
        print('Error getting messages: ${data['message']}');
        throw Exception('API error: ${data['message']}');
      }

      final List<dynamic> messagesJson = data['messages'];
      final messages =
          messagesJson.map((json) => Message.fromJson(json)).toList();

      developer.log('Found ${messages.length} messages',
          name: 'MessagingService');

      // Check if messages list is empty to prevent RangeError
      if (messages.isEmpty) {
        throw Exception('No messages found for conversation: $conversationId');
      }

      return messages[0];
    } catch (e) {
      developer.log('Error getting messages: $e',
          name: 'MessagingService', error: e);
      print('Error getting messages: $e');
      rethrow;
    }
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
    required String token,
  }) async {
    developer.log('Sending message from $senderId to $receiverId',
        name: 'MessagingService');

    try {
      final payload = {
        'senderId': senderId,
        'content': content,
        'messageType': type.toString().split('.').last,
        // Additional fields as needed
        'receiverId': receiverId,
        'conversationId': conversationId,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to send message: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (!data['success']) {
        throw Exception('API error: ${data['message']}');
      }

      final messageJson = data['message'];
      final message = Message.fromJson(messageJson);

      developer.log('Message sent successfully: ${message.id}',
          name: 'MessagingService');
      return message;
    } catch (e) {
      developer.log('Error sending message: $e',
          name: 'MessagingService', error: e);
      rethrow;
    }
  }

  Future<Message> sendAiMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    required String token,
  }) async {
    developer.log('Sending AI message', name: 'MessagingService');

    try {
      final payload = {
        'message': content,
        'messageType': 'text',
        'conversationId': conversationId,
      };

      final response = await http.post(
        Uri.parse('$_aiUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to send message: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (!data['success']) {
        throw Exception('API error: ${data['message']}');
      }

      final messageData = data['response'];
      final message = Message(
        id: DateTime.now().toIso8601String(),
        conversationId: conversationId,
        senderId: "ai",
        senderName: "AI Assistant",
        senderType: "ai",
        receiverId: conversationId,
        receiverName: "Me",
        content: messageData,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      developer.log('Message sent successfully: ${message.id}',
          name: 'MessagingService');
      return message;
    } catch (e) {
      developer.log('Error sending message: $e',
          name: 'MessagingService', error: e);
      rethrow;
    }
  }

  // Future<void> markMessagesAsRead(String conversationId, String userId) async {
  //   developer.log(
  //       'Marking messages as read for conversation: $conversationId',
  //       name: 'MessagingService');

  //   try {
  //     final response = await http.put(
  //       Uri.parse('$_baseUrl/conversations/$conversationId/read'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({'userId': userId}),
  //     );

  //     if (response.statusCode != 200) {
  //       throw Exception(
  //           'Failed to mark messages as read: ${response.statusCode}');
  //     }

  //     final data = jsonDecode(response.body);
  //     if (!data['success']) {
  //       throw Exception('API error: ${data['message']}');
  //     }

  //     developer.log('Messages marked as read', name: 'MessagingService');
  //   } catch (e) {
  //     developer.log('Error marking messages as read: $e',
  //         name: 'MessagingService', error: e);
  //     rethrow;
  //   }
  // }

  Future<int> getTotalUnreadCount(String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/unreadCount'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get unread count: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (!data['success']) {
        throw Exception('API error: ${data['message']}');
      }
      print(data);
      return data['unreadCount'] as int;
    } catch (e) {
      developer.log('Error getting unread count: $e',
          name: 'MessagingService', error: e);
      return 0;
    }
  }

  Future<Message> sendQuotation({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String receiverId,
    required String receiverName,
    required String serviceTitle,
    required String clientName,
    required List<SubService> subServices,
    required String notes,
    required String token,
  }) async {
    developer.log('Sending quotation from $senderId to $receiverId',
        name: 'MessagingService');

    // Calculate total price
    double totalPrice =
        subServices.fold(0.0, (sum, service) => sum + service.price);

    // Create formatted quotation content
    String subServicesContent = '';
    for (int i = 0; i < subServices.length; i++) {
      final service = subServices[i];
      subServicesContent +=
          '${i + 1}. ${service.description} - LKR ${service.price.toStringAsFixed(2)}\n';
    }

    final quotationContent = '''
📋 QUOTATION

Service: $serviceTitle
Client: $clientName

Sub Services:
$subServicesContent
💰 Total Price: LKR ${totalPrice.toStringAsFixed(2)}

${notes.isNotEmpty ? 'Notes: $notes' : ''}

---
*This is a quotation for the requested service. Please review and respond.*
''';

    return sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderType: senderType,
      receiverId: receiverId,
      receiverName: receiverName,
      content: quotationContent,
      type: MessageType.quotation,
      token: token,
    );
  }

  Future<Message> sendBill({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String receiverId,
    required String receiverName,
    required String serviceTitle,
    required String clientName,
    required String serviceDetails,
    required double finalAmount,
    required String paymentNotes,
    required String token,
  }) async {
    developer.log('📤 Sending bill from $senderId to $receiverId',
        name: 'MessagingService');

    // Create formatted bill content
    final billContent = '''
🧾 FINAL BILL

Service: $serviceTitle
Client: $clientName
Work Completed: $serviceDetails

💳 Final Amount: LKR ${finalAmount.toStringAsFixed(2)}

${paymentNotes.isNotEmpty ? 'Payment Notes: $paymentNotes' : ''}

---
*Service completed. Please proceed with payment.*
''';

    return sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderType: senderType,
      receiverId: receiverId,
      receiverName: receiverName,
      content: billContent,
      type: MessageType.bill,
      token: token,
    );
  }

  Future<Map<String, int>> getTotalUnreadCountV2(
      String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/unreadCountConversation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get unread count: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (!data['success']) {
        throw Exception('API error: ${data['message']}');
      }
      developer.log('📱 Unread counts: ${data['counts']}',
          name: 'MessagingService');
      Map<String, int> counts = {};
      if (data['counts'] is List) {
        for (var entry in data['counts']) {
          counts[entry['conversationId']] = entry['count'];
        }
      } else if (data['counts'] is Map) {
        final countsMap = data['counts'] as Map;
        countsMap.forEach((conversationId, count) {
          counts[conversationId] = count as int;
        });
      }
      return counts;
    } catch (e) {
      developer.log('Error getting unread count: $e',
          name: 'MessagingService', error: e);
      print("📱 Error getting unread count: $e");
      return {};
    }
  }
}
