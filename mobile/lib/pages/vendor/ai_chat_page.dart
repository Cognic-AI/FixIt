import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:developer' as developer;
import '../../models/message.dart';
import '../../services/messaging_service.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key, required this.userId, required this.token});

  final String userId;
  final String token;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> with TickerProviderStateMixin {
  final MessagingService _messagingService = MessagingService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;

  late AnimationController _typingAnimationController;
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScale;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _sendButtonScale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _sendButtonController,
      curve: Curves.easeInOut,
    ));

    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Smooth loading
      final result = await _messagingService.getAiConversation(
          widget.userId, widget.token);

      setState(() {
        _messages = result;
        _isLoading = false;
      });

      _scrollToBottom();
      developer.log('Loaded ${_messages.length} messages', name: 'ChatPage');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      developer.log('Error loading messages: $e', name: 'ChatPage');
      if (mounted) {
        _showErrorSnackBar('Failed to load messages: $e');
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    // Animate send button
    _sendButtonController.forward().then((_) {
      _sendButtonController.reverse();
    });

    setState(() {
      _isSending = true;
      _isTyping = true;
    });

    final tempMessage = content;
    _messageController.clear();

    try {
      // Add user message immediately
      final userMessage = Message(
        id: "${DateTime.now().millisecondsSinceEpoch}-${widget.userId}",
        senderId: widget.userId,
        senderName: 'Me',
        content: tempMessage,
        timestamp: DateTime.now(),
        isRead: true,
        conversationId: widget.userId,
        receiverId: 'ai',
        receiverName: 'AI Assistant',
        senderType: 'vendor',
        type: MessageType.text,
      );

      setState(() {
        _messages.add(userMessage);
      });

      _scrollToBottom();

      // Simulate AI thinking time
      await Future.delayed(const Duration(milliseconds: 800));

      final aiMessage = await _messagingService.sendAiMessage(
        content: tempMessage,
        conversationId: widget.userId,
        token: widget.token,
      );

      setState(() {
        _messages.add(aiMessage);
        _isSending = false;
        _isTyping = false;
      });

      _scrollToBottom();
      developer.log('Message sent successfully', name: 'ChatPage');
    } catch (e) {
      setState(() {
        _isSending = false;
        _isTyping = false;
      });
      _messageController.text = tempMessage;
      developer.log('Error sending message: $e', name: 'ChatPage');
      if (mounted) {
        _showErrorSnackBar('Failed to send message: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
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

  String _formatMessageTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatMessageDate(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  bool _containsMarkdown(String text) {
    final markdownPatterns = [
      RegExp(r'\*\*.*?\*\*'),
      RegExp(r'\*.*?\*'),
      RegExp(r'`.*?`'),
      RegExp(r'```[\s\S]*?```'),
      RegExp(r'^#{1,6}\s'),
      RegExp(r'^\s*[-\*\+]\s'),
      RegExp(r'^\s*\d+\.\s'),
      RegExp(r'\[.*?\]$$.*?$$'),
    ];
    return markdownPatterns.any((pattern) => pattern.hasMatch(text));
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                _buildShimmerCircle(32),
                const SizedBox(width: 8),
              ],
              _buildShimmerContainer(
                width: MediaQuery.of(context).size.width * 0.6,
                height: 60 + (index % 3) * 20,
              ),
              if (isMe) ...[
                const SizedBox(width: 8),
                _buildShimmerCircle(32),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerContainer(
      {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: const Alignment(-1.0, 0.0),
          end: const Alignment(1.0, 0.0),
        ),
      ),
    );
  }

  Widget _buildShimmerCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: const Alignment(-1.0, 0.0),
          end: const Alignment(1.0, 0.0),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(
              Icons.smart_toy,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final animationValue =
            (_typingAnimationController.value + index * 0.2) % 1.0;
        final opacity = (animationValue < 0.5)
            ? (animationValue * 2)
            : (2 - animationValue * 2);

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3 + opacity * 0.7),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey.shade300,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _formatMessageDate(date),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey.shade300,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Row(
                mainAxisAlignment:
                    isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isMe) ...[
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isMe
                            ? const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isMe ? null : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isMe ? 20 : 6),
                          bottomRight: Radius.circular(isMe ? 6 : 20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isMe
                                ? const Color(0xFF2563EB).withOpacity(0.3)
                                : Colors.grey.withOpacity(0.15),
                            spreadRadius: 0,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _containsMarkdown(message.content)
                              ? MarkdownBody(
                                  data: message.content,
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(
                                      fontSize: 16,
                                      color: isMe
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                      height: 1.4,
                                    ),
                                    h1: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isMe
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                    ),
                                    h2: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isMe
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                    ),
                                    h3: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isMe
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                    ),
                                    strong: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isMe
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                    ),
                                    em: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: isMe
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                    ),
                                    code: TextStyle(
                                      backgroundColor: isMe
                                          ? Colors.white.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.2),
                                      color: isMe
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                      fontFamily: 'monospace',
                                    ),
                                    codeblockDecoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    listBullet: TextStyle(
                                      color: isMe
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                    ),
                                    a: TextStyle(
                                      color: isMe ? Colors.white : Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  selectable: true,
                                )
                              : Text(
                                  message.content,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isMe
                                        ? Colors.white
                                        : const Color(0xFF1F2937),
                                    height: 1.4,
                                  ),
                                ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatMessageTime(message.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isMe
                                      ? Colors.white.withOpacity(0.8)
                                      : Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.done_all,
                                  size: 16,
                                  color: message.isRead
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
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2563EB).withOpacity(0.1),
                        const Color(0xFF6366F1).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    size: 50,
                    color: Color(0xFF2563EB),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Start the conversation',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ask me anything! I\'m here to help you with\ninformation, advice, and creative tasks.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSuggestionChip('How can you help me?'),
              _buildSuggestionChip('Tell me a joke'),
              _buildSuggestionChip('Explain AI'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF2563EB).withOpacity(0.3),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
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

      if (currentDate == null || !messageDate.isAtSameMomentAs(currentDate)) {
        messageWidgets.add(_buildDateSeparator(message.timestamp));
        currentDate = messageDate;
      }

      final isMe = message.senderId == widget.userId;
      messageWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _buildMessageBubble(message, isMe),
        ),
      );
    }

    if (_isTyping) {
      messageWidgets.add(_buildTypingIndicator());
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        shadowColor: Colors.grey.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI Assistant",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  "Powered by Gemini AI",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading ? _buildShimmerLoading() : _buildMessagesList(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: _focusNode.hasFocus
                              ? const Color(0xFF2563EB).withOpacity(0.3)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          hintText: 'Ask me anything...',
                          hintStyle: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ScaleTransition(
                    scale: _sendButtonScale,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.4),
                            spreadRadius: 0,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(25),
                          onTap: _isSending ? null : _sendMessage,
                          child: _isSending
                              ? const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
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
    _focusNode.dispose();
    _typingAnimationController.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }
}
