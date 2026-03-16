import '../models/chat_models.dart';
import 'api_client.dart';

class ChatService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ChatConversation>> getChatList() async {
    try {
      print('🔍 Calling chat list API: /chat/list');
      print('🌐 Full URL will be: https://backendapp.connectingheart.co.in/api/chat/list');
      final response = await _apiClient.get<Map<String, dynamic>>('/chat/list');
      print('📱 Chat list response: $response');
      
      if (response['data'] != null) {
        final conversationsList = response['data'] as List<dynamic>;
        print('💬 Found ${conversationsList.length} conversations');
        return conversationsList
            .map((conv) => ChatConversation.fromJson(conv))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error getting chat list: $e');
      return [];
    }
  }

  Future<ChatHistory?> getChatHistory(String userId, {int page = 1, int limit = 50}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/chat/history/$userId?page=$page&limit=$limit'
      );
      if (response['data'] != null) {
        return ChatHistory.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error getting chat history: $e');
      return null;
    }
  }

  Future<ChatEligibility?> checkEligibility(String receiverId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/chat/checkEligibility/$receiverId'
      );
      if (response['data'] != null) {
        return ChatEligibility.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error checking chat eligibility: $e');
      return null;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/chat/unreadCount');
      if (response['data'] != null && response['data']['unreadCount'] != null) {
        return response['data']['unreadCount'] as int;
      }
      return 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  Future<bool> sendMessage(
    String receiverId,
    String message, {
    String messageType = 'text',
    String? tempId,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/chat/send',
        body: {
          'receiverId': receiverId,
          'message': message,
          'messageType': messageType,
          if (tempId != null) 'tempId': tempId,
        },
      );
      // Backend usually returns {status:'success', ...}
      return response['success'] == true ||
          response['status'] == 'success' ||
          response['code'] == 'CH200';
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }
}