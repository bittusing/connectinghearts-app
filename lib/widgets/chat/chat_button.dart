import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/chat_service.dart';
import '../../theme/colors.dart';
// credit confirmation uses showDialog; no inline modal widget

class ChatButton extends StatefulWidget {
  final String userId;
  final String userName;
  final String? className;
  final ChatButtonVariant variant;
  final Widget? child;

  const ChatButton({
    super.key,
    required this.userId,
    required this.userName,
    this.className,
    this.variant = ChatButtonVariant.button,
    this.child,
  });

  @override
  State<ChatButton> createState() => _ChatButtonState();
}

class _ChatButtonState extends State<ChatButton> {
  final ChatService _chatService = ChatService();
  bool _checking = false;

  Future<void> _handleChatClick() async {
    setState(() => _checking = true);
    
    try {
      final eligibility = await _chatService.checkEligibility(widget.userId);
      
      if (eligibility == null) {
        _showToast('Failed to check eligibility', isError: true);
        return;
      }

      if (!eligibility.canChat) {
        _showToast('You need an active membership to chat. Please upgrade your plan.', isError: true);
        return;
      }

      // Show modal if credit required and not already initiated
      if (eligibility.creditRequired && !eligibility.alreadyInitiated) {
        final confirmed = await _showCreditDialog();
        if (confirmed == true) {
          _openChat();
        }
      } else {
        // Open chat directly
        _openChat();
      }
    } catch (error) {
      _showToast('Failed to check eligibility', isError: true);
    } finally {
      setState(() => _checking = false);
    }
  }

  Future<bool?> _showCreditDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Credit Confirmation'),
          content: Text(
            widget.userName.isNotEmpty
                ? '${widget.userName} से chatting करने पर आपका 1 credit use होगा'
                : 'Chatting करने पर आपका 1 credit use होगा',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _openChat() {
    context.push('/chat/${widget.userId}?name=${Uri.encodeComponent(widget.userName)}');
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Button only; credit confirmation is shown via showDialog (full-screen overlay)
    if (widget.child != null) {
      return GestureDetector(
        onTap: _checking ? null : _handleChatClick,
        child: widget.child,
      );
    }

    if (widget.variant == ChatButtonVariant.icon) {
      return IconButton(
        onPressed: _checking ? null : _handleChatClick,
        icon: const Icon(Icons.chat_bubble_outline),
        tooltip: 'Chat',
        style: IconButton.styleFrom(
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.grey[700],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _checking ? null : _handleChatClick,
      icon: const Icon(Icons.chat_bubble_outline, size: 18),
      label: Text(_checking ? 'Checking...' : 'Chat'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

enum ChatButtonVariant {
  button,
  icon,
}