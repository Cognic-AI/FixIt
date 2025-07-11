import 'dart:developer' as developer;

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderType; // 'client' or 'vendor'
  final String receiverId;
  final String receiverName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final String? attachmentUrl;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.receiverId,
    required this.receiverName,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.attachmentUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    developer.log('💬 Creating Message from JSON: ${json['id']}',
        name: 'Message');
    return Message(
      id: json['id'],
      conversationId: json['conversationId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderType: json['senderType'],
      receiverId: json['receiverId'],
      receiverName: json['receiverName'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      imageUrl: json['imageUrl'],
      attachmentUrl: json['attachmentUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'attachmentUrl': attachmentUrl,
    };
  }
}

enum MessageType { text, image, file, location, system }

class Conversation {
  final String id;
  final String serviceId;
  final String serviceTitle;
  final String clientId;
  final String clientName;
  final String vendorId;
  final String vendorName;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.clientId,
    required this.clientName,
    required this.vendorId,
    required this.vendorName,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    developer.log('💬 Creating Conversation from JSON: ${json['id']}',
        name: 'Conversation');
    return Conversation(
      id: json['id'],
      serviceId: json['serviceId'],
      serviceTitle: json['serviceTitle'],
      clientId: json['clientId'],
      clientName: json['clientName'],
      vendorId: json['vendorId'],
      vendorName: json['vendorName'],
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'clientId': clientId,
      'clientName': clientName,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
