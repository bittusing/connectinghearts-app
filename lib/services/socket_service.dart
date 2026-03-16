import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import 'storage_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';
import 'dart:async';

class SocketService extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  bool _isConnected = false;
  String? _currentUserId;
  io.Socket? _socket;
  
  // Event callbacks
  Function(ChatMessage)? onMessageReceived;
  Function(MessageSentEvent)? onMessageSent;
  Function(TypingEvent)? onUserTyping;
  Function(UserStatusEvent)? onUserOnline;
  Function(UserStatusEvent)? onUserOffline;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    try {
      _currentUserId = await _storageService.getUserId();
      final token = await _storageService.getToken();
      
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('❌ Socket connection failed: No auth token found');
        }
        _isConnected = false;
        notifyListeners();
        return;
      }

      // Disconnect any existing socket
      _socket?.dispose();

      final socketUrl = ApiConfig.backendBaseUrl; // https://backendapp.connectingheart.co.in
      if (kDebugMode) {
        print('🔌 Connecting to socket: $socketUrl');
      }

      final completer = Completer<void>();

      _socket = io.io(
        socketUrl,
        <String, dynamic>{
          'transports': ['websocket', 'polling'],
          'autoConnect': true,
          'reconnection': true,
          'reconnectionAttempts': 10,
          'reconnectionDelay': 1000,
          'timeout': 20000,
          'forceNew': true,
          'auth': <String, dynamic>{
            'token': 'Bearer $token',
          },
        },
      );

      _socket!.on('connect', (_) {
        _isConnected = true;
        notifyListeners();
        if (kDebugMode) {
          print('✅ Socket connected. id=${_socket!.id}');
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      _socket!.on('disconnect', (reason) {
        _isConnected = false;
        notifyListeners();
        if (kDebugMode) {
          print('❌ Socket disconnected. reason=$reason');
        }
      });

      _socket!.on('connect_error', (error) {
        _isConnected = false;
        notifyListeners();
        if (kDebugMode) {
          print('❌ Socket connect_error: $error');
        }
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });

      // Receive new message
      _socket!.on('receive_message', (data) {
        try {
          if (data is Map) {
            final msg = ChatMessage.fromJson(Map<String, dynamic>.from(data));
            onMessageReceived?.call(msg);
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error parsing receive_message: $e');
          }
        }
      });

      // Message sent confirmation
      _socket!.on('message_sent', (data) {
        try {
          if (data is Map) {
            final event =
                MessageSentEvent.fromJson(Map<String, dynamic>.from(data));
            onMessageSent?.call(event);
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error parsing message_sent: $e');
          }
        }
      });

      // Typing indicator
      _socket!.on('user_typing', (data) {
        try {
          if (data is Map) {
            final event = TypingEvent.fromJson(Map<String, dynamic>.from(data));
            onUserTyping?.call(event);
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error parsing user_typing: $e');
          }
        }
      });

      // Online/offline
      _socket!.on('user_online', (data) {
        try {
          if (data is Map) {
            final event =
                UserStatusEvent.fromJson(Map<String, dynamic>.from(data));
            onUserOnline?.call(event);
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error parsing user_online: $e');
          }
        }
      });

      _socket!.on('user_offline', (data) {
        try {
          if (data is Map) {
            final event =
                UserStatusEvent.fromJson(Map<String, dynamic>.from(data));
            onUserOffline?.call(event);
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error parsing user_offline: $e');
          }
        }
      });
      
      if (kDebugMode) {
        print('🔌 Socket connected for user: $_currentUserId');
      }

      // Wait briefly until connected (or fail), so UI doesn't get stuck in "reconnecting"
      try {
        await completer.future.timeout(const Duration(seconds: 5));
      } catch (_) {
        // ignore timeout; connection may still succeed later
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Socket connection failed: $e');
      }
    }
  }

  void disconnect() {
    _isConnected = false;
    _currentUserId = null;
    _socket?.dispose();
    _socket = null;
    notifyListeners();
    
    if (kDebugMode) {
      print('🔌 Socket disconnected');
    }
  }

  void sendMessage(SendMessageRequest request) {
    if (!_isConnected) {
      if (kDebugMode) {
        print('❌ Cannot send message: Socket not connected');
      }
      return;
    }

    if (kDebugMode) {
      print('📤 Sending message: ${request.toJson()}');
    }
    _socket?.emit('send_message', request.toJson());
  }

  void markAsRead(String senderId) {
    if (!_isConnected) return;

    if (kDebugMode) {
      print('✅ Marking messages as read from: $senderId');
    }
    _socket?.emit('mark_as_read', {'senderId': senderId});
  }

  void sendTyping(String receiverId, bool isTyping) {
    if (!_isConnected) return;

    if (kDebugMode) {
      print('⌨️ Typing status to $receiverId: $isTyping');
    }
    _socket?.emit('typing', {'receiverId': receiverId, 'isTyping': isTyping});
  }

  void setMessageReceivedCallback(Function(ChatMessage) callback) {
    onMessageReceived = callback;
  }

  void setMessageSentCallback(Function(MessageSentEvent) callback) {
    onMessageSent = callback;
  }

  void setTypingCallback(Function(TypingEvent) callback) {
    onUserTyping = callback;
  }

  void setUserOnlineCallback(Function(UserStatusEvent) callback) {
    onUserOnline = callback;
  }

  void setUserOfflineCallback(Function(UserStatusEvent) callback) {
    onUserOffline = callback;
  }
}