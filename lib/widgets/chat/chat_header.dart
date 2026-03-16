import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class ChatHeader extends StatelessWidget {
  final String userName;
  final bool isOnline;
  final bool isTyping;
  final VoidCallback onBack;

  const ChatHeader({
    super.key,
    required this.userName,
    required this.isOnline,
    required this.isTyping,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 8,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isTyping
                      ? 'typing...'
                      : isOnline
                          ? 'online'
                          : 'offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: isTyping
                        ? AppColors.primary
                        : isOnline
                            ? Colors.green
                            : Colors.grey,
                    fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          
          // More options
          IconButton(
            onPressed: () {
              // TODO: Implement more options (block, report, etc.)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('More options coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }
}