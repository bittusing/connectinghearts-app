import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/chat_models.dart';
import '../../services/chat_service.dart';
import '../../services/socket_service.dart';
import '../../services/storage_service.dart';
import '../../theme/colors.dart';
import '../../widgets/chat/chat_header.dart';
import '../../widgets/chat/chat_message_widget.dart';
import '../../widgets/chat/chat_input.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String? userName;

  const ChatScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final SocketService _socketService = SocketService();
  final StorageService _storageService = StorageService();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  bool _isOnline = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _socketService.disconnect();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    // Get current user ID
    _currentUserId = await _storageService.getUserId();
    
    // Load chat history
    await _loadChatHistory();
    
    // Initialize socket connection
    await _initializeSocket();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await _chatService.getChatHistory(widget.userId);
      if (history != null) {
        setState(() {
          _messages = history.messages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  Future<void> _initializeSocket() async {
    await _socketService.connect();
    
    // Set up socket event listeners
    _socketService.setMessageReceivedCallback(_onMessageReceived);
    _socketService.setMessageSentCallback(_onMessageSent);
    _socketService.setTypingCallback(_onTypingReceived);
    _socketService.setUserOnlineCallback(_onUserOnline);
    _socketService.setUserOfflineCallback(_onUserOffline);
    
    // Mark messages as read
    _socketService.markAsRead(widget.userId);
  }

  void _onMessageReceived(ChatMessage message) {
    // Only add if it's from the other user (not from me)
    if (message.senderId != _currentUserId) {
      setState(() {
        // Check for duplicates
        final exists = _messages.any((msg) => msg.id == message.id);
        if (!exists) {
          _messages.add(message);
        }
      });
      _scrollToBottom();
      
      // Mark as read
      _socketService.markAsRead(widget.userId);
    }
  }

  void _onMessageSent(MessageSentEvent event) {
    if (event.creditDeducted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('1 credit used for chat initiation'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
    
    // Update the temporary message with real ID from server
    setState(() {
      _messages = _messages.map((msg) {
        if (msg.tempId != null && msg.tempId == event.tempId) {
          return msg.copyWith(id: event.id, tempId: null);
        }
        return msg;
      }).toList();
    });
  }

  void _onTypingReceived(TypingEvent event) {
    if (event.userId == widget.userId) {
      setState(() {
        _isTyping = event.isTyping;
      });
    }
  }

  void _onUserOnline(UserStatusEvent event) {
    if (event.userId == widget.userId) {
      setState(() {
        _isOnline = true;
      });
    }
  }

  void _onUserOffline(UserStatusEvent event) {
    if (event.userId == widget.userId) {
      setState(() {
        _isOnline = false;
      });
    }
  }

  Future<void> _handleSendMessage(String message) async {
    if (_currentUserId == null) {
      print('Cannot send message: current user ID is null');
      return;
    }

    // Ensure socket is connected (webapp sends messages via socket)
    if (!_socketService.isConnected) {
      await _socketService.connect();
    }

    // Create temporary message for optimistic UI update
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final tempMessage = ChatMessage(
      id: tempId,
      tempId: tempId,
      senderId: _currentUserId!,
      receiverId: widget.userId,
      message: message,
      messageType: 'text',
      isRead: false,
      createdAt: DateTime.now().toIso8601String(),
    );

    // Add to UI immediately (optimistic update)
    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    if (!_socketService.isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reconnecting… try again in a moment.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Send via socket (matches webapp behavior)
    final request = SendMessageRequest(
      receiverId: widget.userId,
      message: message,
      messageType: 'text',
      tempId: tempId,
    );
    _socketService.sendMessage(request);
  }

  void _handleTyping(bool isTyping) {
    if (_socketService.isConnected) {
      _socketService.sendTyping(widget.userId, isTyping);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Simple header for loading state
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text(
                      widget.userName ?? 'Chat',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Chat Header
            ChatHeader(
              userName: widget.userName ?? 'User',
              isOnline: _isOnline,
              isTyping: _isTyping,
              onBack: () => context.pop(),
            ),
            
            // Connection Status Indicator
            if (!_socketService.isConnected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.yellow[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.refresh,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reconnecting to server...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),
            
            // Messages
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet. Start the conversation!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isOwnMessage = message.senderId == _currentUserId;
                        
                        return ChatMessageWidget(
                          message: message,
                          isOwnMessage: isOwnMessage,
                        );
                      },
                    ),
            ),
            
            // Chat Input
            ChatInput(
              onSend: _handleSendMessage,
              onTyping: _handleTyping,
              // Keep input usable even if socket is reconnecting; REST send still works
              enabled: true,
            ),
          ],
        ),
      ),
    );
  }
}