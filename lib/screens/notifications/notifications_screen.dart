import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../providers/notification_count_provider.dart';
import '../../widgets/common/bottom_navigation_widget.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBar: const BottomNavigationWidget(),
      body: Consumer<NotificationCountProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final counts = provider.counts;

          final categories = [
            _NotificationCategory(
              id: 'interest-received',
              label: 'Interests Received',
              route: '/interests-received',
              count: counts.interestReceived,
              icon: Icons.favorite,
              iconColor: AppColors.primary,
              badgeIcon: Icons.auto_awesome,
              badgeColor: Colors.amber,
            ),
            _NotificationCategory(
              id: 'interest-sent',
              label: 'Interests Sent',
              route: '/interests-sent',
              count: counts.interestSent,
              icon: Icons.favorite,
              iconColor: AppColors.primary,
            ),
            _NotificationCategory(
              id: 'unlocked-profiles',
              label: 'Unlocked Profiles',
              route: '/unlocked-profiles',
              count: counts.unlockedProfiles,
              icon: Icons.favorite,
              iconColor: AppColors.primary,
              badgeIcon: Icons.lock,
              badgeColor: Colors.amber,
            ),
            _NotificationCategory(
              id: 'i-declined',
              label: 'I Declined',
              route: '/i-declined',
              count: counts.iDeclined,
              icon: Icons.favorite,
              iconColor: Colors.orange,
              badgeIcon: Icons.close,
              badgeColor: Colors.white,
            ),
            _NotificationCategory(
              id: 'they-declined',
              label: 'They Declined',
              route: '/they-declined',
              count: counts.theyDeclined,
              icon: Icons.favorite,
              iconColor: AppColors.primary,
              badgeIcon: Icons.close,
              badgeColor: Colors.white,
            ),
            _NotificationCategory(
              id: 'shortlisted',
              label: 'Shortlisted Profiles',
              route: '/shortlisted',
              count: counts.shortlisted,
              icon: Icons.flag,
              iconColor: Colors.red,
            ),
            _NotificationCategory(
              id: 'ignored',
              label: 'Ignored Profiles',
              route: '/ignored',
              count: counts.ignored,
              icon: Icons.block,
              iconColor: Colors.blue,
              badgeIcon: Icons.close,
              badgeColor: Colors.white,
            ),
            _NotificationCategory(
              id: 'blocked',
              label: 'Blocked Profiles',
              route: '/blocked',
              count: counts.blocked,
              icon: Icons.block,
              iconColor: Colors.red,
              badgeIcon: Icons.close,
              badgeColor: Colors.white,
            ),
          ];

          return RefreshIndicator(
            onRefresh: () => provider.fetchCounts(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Categories
                  ...categories.map((category) => _buildCategoryCard(
                        context,
                        category,
                      )),
                    ],
                  ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    _NotificationCategory category,
  ) {
    final theme = Theme.of(context);
    final hasCount = category.count > 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => context.push(category.route),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                color: theme.dividerColor,
                          ),
                        ),
            child: Row(
              children: [
                // Icon
                Stack(
                  children: [
                    Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                        color: category.iconColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                        category.icon,
                        color: category.iconColor,
                        size: 24,
                            ),
                          ),
                    if (category.badgeIcon != null)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: category.badgeColor,
                            shape: BoxShape.circle,
                              ),
                          child: Icon(
                            category.badgeIcon,
                            size: 12,
                            color: category.iconColor,
                          ),
                        ),
                              ),
                            ],
                          ),
                const SizedBox(width: 16),
                // Label
                Expanded(
                  child: Text(
                    category.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Count badge
                if (hasCount)
                  Container(
                    width: 24,
                    height: 24,
                                  decoration: const BoxDecoration(
                      color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                    child: Center(
                      child: Text(
                        category.count > 9 ? '9+' : '${category.count}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ],
                        ),
          ),
                  ),
                ),
    );
  }
}

class _NotificationCategory {
  final String id;
  final String label;
  final String route;
  final int count;
  final IconData icon;
  final Color iconColor;
  final IconData? badgeIcon;
  final Color? badgeColor;

  _NotificationCategory({
    required this.id,
    required this.label,
    required this.route,
    required this.count,
    required this.icon,
    required this.iconColor,
    this.badgeIcon,
    this.badgeColor,
  });
}
