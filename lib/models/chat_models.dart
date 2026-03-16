class ChatEligibility {
  final bool canChat;
  final bool creditRequired;
  final bool alreadyInitiated;

  ChatEligibility({
    required this.canChat,
    required this.creditRequired,
    required this.alreadyInitiated,
  });

  factory ChatEligibility.fromJson(Map<String, dynamic> json) {
    return ChatEligibility(
      canChat: json['canChat'] ?? false,
      creditRequired: json['creditRequired'] ?? false,
      alreadyInitiated: json['alreadyInitiated'] ?? false,
    );
  }
}

class ChatMessage {
  final String? id;
  final String? tempId;
  final String senderId;
  final String receiverId;
  final String message;
  final String messageType;
  final bool isRead;
  final String createdAt;

  ChatMessage({
    this.id,
    this.tempId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.messageType = 'text',
    this.isRead = false,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? json['id'],
      tempId: json['tempId'],
      senderId: json['sender_id'] ?? json['senderId'] ?? '',
      receiverId: json['receiver_id'] ?? json['receiverId'] ?? '',
      message: json['message'] ?? '',
      messageType: json['messageType'] ?? 'text',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'tempId': tempId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'messageType': messageType,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? tempId,
    String? senderId,
    String? receiverId,
    String? message,
    String? messageType,
    bool? isRead,
    String? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      tempId: tempId ?? this.tempId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ChatConversation {
  final String userId;
  final String userName;
  final int heartsId;
  final String? profilePic;
  final String lastMessage;
  final String? lastMessageTime;
  final int unreadCount;
  final bool isLastMessageFromMe;

  ChatConversation({
    required this.userId,
    required this.userName,
    required this.heartsId,
    this.profilePic,
    required this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isLastMessageFromMe = false,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      heartsId: json['heartsId'] ?? 0,
      profilePic: json['profilePic'],
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'],
      unreadCount: json['unreadCount'] ?? 0,
      isLastMessageFromMe: json['isLastMessageFromMe'] ?? false,
    );
  }

  // For backward compatibility
  String? get timestamp => lastMessageTime;
}

class ChatHistory {
  final List<ChatMessage> messages;

  ChatHistory({required this.messages});

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    final messagesList = json['messages'] as List<dynamic>? ?? [];
    return ChatHistory(
      messages: messagesList.map((msg) => ChatMessage.fromJson(msg)).toList(),
    );
  }
}

class SendMessageRequest {
  final String receiverId;
  final String message;
  final String messageType;
  final String? tempId;

  SendMessageRequest({
    required this.receiverId,
    required this.message,
    this.messageType = 'text',
    this.tempId,
  });

  Map<String, dynamic> toJson() {
    return {
      'receiverId': receiverId,
      'message': message,
      'messageType': messageType,
      if (tempId != null) 'tempId': tempId,
    };
  }
}

class MessageSentEvent {
  final String id;
  final String? tempId;
  final bool creditDeducted;

  MessageSentEvent({
    required this.id,
    this.tempId,
    this.creditDeducted = false,
  });

  factory MessageSentEvent.fromJson(Map<String, dynamic> json) {
    return MessageSentEvent(
      id: json['_id'] ?? json['id'] ?? '',
      tempId: json['tempId'],
      creditDeducted: json['creditDeducted'] ?? false,
    );
  }
}

class TypingEvent {
  final String userId;
  final bool isTyping;

  TypingEvent({
    required this.userId,
    required this.isTyping,
  });

  factory TypingEvent.fromJson(Map<String, dynamic> json) {
    return TypingEvent(
      userId: json['userId'] ?? '',
      isTyping: json['isTyping'] ?? false,
    );
  }
}

class UserStatusEvent {
  final String userId;

  UserStatusEvent({required this.userId});

  factory UserStatusEvent.fromJson(Map<String, dynamic> json) {
    return UserStatusEvent(
      userId: json['userId'] ?? '',
    );
  }
}