import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/common/confirm_modal.dart';
import 'package:flutter/services.dart' show rootBundle;

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentPath = GoRouterState.of(context).uri.path;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // User Profile Section
            if (authProvider.user != null)
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Profile Picture
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: ClipOval(
                        child: authProvider.user?.avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: authProvider.user!.avatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                  size: 30,
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                  size: 30,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: Colors.grey,
                                size: 30,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and ID
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authProvider.user?.name ?? 'User',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID - ${authProvider.user?.heartsId != null ? 'UWSS${authProvider.user!.heartsId}' : (authProvider.user?.id ?? 'N/A')}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Upgrade Membership Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.go('/membership');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899), // Pink/red color
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Upgrade Membership',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Promotional Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'UPTO 65% OFF ALL MEMBERSHIP PLANS',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Menu Label
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MENU',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 3,
                    color: Colors.black.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.home,
                    title: 'Home',
                    route: '/',
                    currentPath: currentPath,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.person,
                    title: 'Edit Profile',
                    route: '/my-profile',
                    currentPath: currentPath,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.favorite,
                    title: 'Preference Setup',
                    route: '/partner-preference',
                    currentPath: currentPath,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.search,
                    title: 'Search',
                    route: '/search',
                    currentPath: currentPath,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.people,
                    title: 'All Profiles',
                    route: '/profiles',
                    currentPath: currentPath,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.star,
                    title: 'Daily Recommendations',
                    route: '/daily-picks',
                    currentPath: currentPath,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.visibility,
                    title: 'Profile Visitors',
                    route: '/profile-visitors',
                    currentPath: currentPath,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.card_membership,
                    title: 'Membership',
                    route: '/membership',
                    currentPath: currentPath,
                    badge: 'Upgrade',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.lock,
                    title: 'Change Password',
                    route: '/change-password',
                    currentPath: currentPath,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.delete_outline,
                    title: 'Delete Profile',
                    route: '/delete-profile',
                    currentPath: currentPath,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.feedback,
                    title: 'Feedback',
                    route: '/feedback',
                    currentPath: currentPath,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    route: '/help',
                    currentPath: currentPath,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.description,
                    title: 'Terms & Conditions',
                    route: '/terms',
                    currentPath: currentPath,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.shield,
                    title: 'Privacy Policy',
                    route: '/privacy',
                    currentPath: currentPath,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.favorite,
                    title: 'Donate Now',
                    route: null,
                    currentPath: currentPath,
                    external: true,
                    externalUrl:
                        'https://contributions.heartfulness.org/in-en/donation-general-fund',
                  ),
                  const Divider(color: Colors.grey),
                  _buildMenuItem(
                    context,
                    icon: themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    title:
                        themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                    route: null,
                    currentPath: currentPath,
                    onTap: () => themeProvider.toggleTheme(),
                  ),
                ],
              ),
            ),
            // Logout Button
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildLogoutButton(context, authProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    required String currentPath,
    String? badge,
    bool external = false,
    String? externalUrl,
    VoidCallback? onTap,
  }) {
    final isActive = route != null &&
        (currentPath == route || currentPath.startsWith('$route/'));

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color:
            isActive ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.primary : Colors.black54,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.primary : Colors.black87,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : const Icon(
                Icons.chevron_right,
                color: Colors.black54,
                size: 20,
              ),
        onTap: () {
          Navigator.pop(context); // Close drawer
          if (onTap != null) {
            onTap();
          } else if (external && externalUrl != null) {
            _launchURL(externalUrl);
          } else if (route != null) {
            context.go(route);
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          _showLogoutConfirm(context, authProvider);
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => ConfirmModal(
        title: 'You want to Logout',
        description: 'Are you sure you want to logout from your account?',
        confirmLabel: 'Yes',
        cancelLabel: 'No',
        onConfirm: () async {
          Navigator.pop(context);
          await authProvider.logout();
          if (context.mounted) {
            context.go('/login');
          }
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
