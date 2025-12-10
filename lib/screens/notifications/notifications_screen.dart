import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  final List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      // Mock notifications
      _notifications.addAll([
        {
          'id': '1',
          'type': 'interest_received',
          'title': 'New Interest Received',
          'message': 'HEARTS-1001 has shown interest in your profile',
          'time': '2 hours ago',
          'isRead': false,
        },
        {
          'id': '2',
          'type': 'profile_visitor',
          'title': 'Profile Visitor',
          'message': 'HEARTS-1002 viewed your profile',
          'time': '5 hours ago',
          'isRead': false,
        },
        {
          'id': '3',
          'type': 'interest_accepted',
          'title': 'Interest Accepted',
          'message': 'HEARTS-1003 accepted your interest',
          'time': '1 day ago',
          'isRead': true,
        },
      ]);
    });
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'interest_received':
        return Icons.favorite;
      case 'profile_visitor':
        return Icons.visibility;
      case 'interest_accepted':
        return Icons.check_circle;
      case 'interest_declined':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'interest_received':
        return AppColors.primary;
      case 'profile_visitor':
        return AppColors.info;
      case 'interest_accepted':
        return AppColors.success;
      case 'interest_declined':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var notification in _notifications) {
                  notification['isRead'] = true;
                }
              });
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['isRead'] as bool;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isRead
                              ? theme.cardColor
                              : AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRead
                                ? theme.dividerColor
                                : AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _getNotificationColor(notification['type'])
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getNotificationIcon(notification['type']),
                              color: _getNotificationColor(notification['type']),
                            ),
                          ),
                          title: Text(
                            notification['title'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                notification['message'],
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification['time'],
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          trailing: !isRead
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              notification['isRead'] = true;
                            });
                            // Navigate based on notification type
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

