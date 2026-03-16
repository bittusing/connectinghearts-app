import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final Function(bool) onTyping;
  final bool enabled;

  const ChatInput({
    super.key,
    required this.onSend,
    required this.onTyping,
    this.enabled = true,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChanged(String text) {
    final isCurrentlyTyping = text.isNotEmpty;
    
    if (isCurrentlyTyping != _isTyping) {
      setState(() {
        _isTyping = isCurrentlyTyping;
      });
      widget.onTyping(isCurrentlyTyping);
    }
  }

  void _handleSend() {
    final message = _controller.text.trim();
    if (message.isEmpty || !widget.enabled) return;

    widget.onSend(message);
    _controller.clear();
    
    // Stop typing indicator
    if (_isTyping) {
      setState(() {
        _isTyping = false;
      });
      widget.onTyping(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: _handleTextChanged,
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Send button
            Container(
              decoration: BoxDecoration(
                color: widget.enabled && _controller.text.trim().isNotEmpty
                    ? AppColors.primary
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: widget.enabled && _controller.text.trim().isNotEmpty
                    ? _handleSend
                    : null,
                icon: const Icon(
                  Icons.send,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}