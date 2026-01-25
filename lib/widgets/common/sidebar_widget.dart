import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/common/confirm_modal.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../config/api_config.dart';

class SidebarWidget extends StatefulWidget {
  const SidebarWidget({super.key});

  @override
  State<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  String? _profileImageUrl;
  String? _profileName;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      // First, try to load from storage (fast, no API call)
      final storedName = await _storageService.getProfileName();
      final storedImageUrl = await _storageService.getProfileImageUrl();

      if (storedName != null) {
        _profileName = storedName;
      }
      if (storedImageUrl != null) {
        _profileImageUrl = storedImageUrl;
      }

      if (mounted) {
        setState(() {});
      }

      // Then, refresh from API in background (update storage if changed)
      try {
        final userResponse = await _authService.getUser();
        if (userResponse['code'] == 'CH200' &&
            userResponse['status'] == 'success' &&
            userResponse['data'] != null) {
          final userData = userResponse['data'] as Map<String, dynamic>;

          // Extract and store name
          final name = userData['name']?.toString();
          if (name != null && name.isNotEmpty) {
            _profileName = name;
            await _storageService.setProfileName(name);
          }

          // Extract and store profile picture
          final profilePic = userData['profilePic'] as List<dynamic>?;
          if (profilePic != null && profilePic.isNotEmpty) {
            final primaryPic = profilePic.firstWhere(
              (pic) => pic['primary'] == true,
              orElse: () => profilePic.first,
            ) as Map<String, dynamic>?;

            if (primaryPic != null && primaryPic['id'] != null) {
              final userId = userData['_id']?.toString() ?? '';
              if (userId.isNotEmpty) {
                final imageUrl = ApiConfig.buildImageUrl(
                    userId, primaryPic['id'].toString());
                _profileImageUrl = imageUrl;
                await _storageService.setProfileImageUrl(imageUrl);
              }
            }
          }
        }
      } catch (e) {
        // If getUser fails, fallback to profile service
        try {
          final profileResponse = await _profileService.getUserProfileData();
          if (profileResponse['status'] == 'success' &&
              profileResponse['data'] != null) {
            final data = profileResponse['data'] as Map<String, dynamic>;
            final basic = data['basic'] as Map<String, dynamic>?;
            final misc = data['miscellaneous'] as Map<String, dynamic>?;

            // Extract name
            final name = basic?['name']?.toString();
            if (name != null && name.isNotEmpty) {
              _profileName = name;
              await _storageService.setProfileName(name);
            }

            // Extract profile picture
            final profilePic = misc?['profilePic'] as List<dynamic>?;
            if (profilePic != null && profilePic.isNotEmpty) {
              final primaryPic = profilePic.firstWhere(
                (pic) => pic['primary'] == true,
                orElse: () => profilePic.first,
              ) as Map<String, dynamic>?;

              if (primaryPic != null && primaryPic['id'] != null) {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                final clientId = misc?['clientID']?.toString() ??
                    authProvider.user?.id ??
                    misc?['heartsId']?.toString() ??
                    '';
                if (clientId.isNotEmpty) {
                  final imageUrl = ApiConfig.buildImageUrl(
                      clientId, primaryPic['id'].toString());
                  _profileImageUrl = imageUrl;
                  await _storageService.setProfileImageUrl(imageUrl);
                }
              }
            }
          }
        } catch (e2) {
          // Silently fail
        }
      }
    } catch (e) {
      // Silently fail
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

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
                    Stack(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.5),
                              width: 2,
                            ),
                            color: Colors.grey[200],
                          ),
                          child: ClipOval(
                            child: _profileImageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: _profileImageUrl!,
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
                                : (authProvider.user?.avatarUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: authProvider.user!.avatarUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const Icon(
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
                                      )),
                          ),
                        ),
                        // Online status indicator
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Name and Edit Profile
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _profileName ?? authProvider.user?.name ?? 'User',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              context.go('/my-profile');
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '',
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
                    route: '/settings-partner-preference',
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
                  // const Divider(color: Colors.grey),
                  // _buildMenuItem(
                  //   context,
                  //   icon: themeProvider.isDarkMode
                  //       ? Icons.light_mode
                  //       : Icons.dark_mode,
                  //   title:
                  //       themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                  //   route: null,
                  //   currentPath: currentPath,
                  //   onTap: () => themeProvider.toggleTheme(),
                  // ),
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
    try {
      final uri = Uri.parse(url);

      // Try to launch URL - use externalApplication for web URLs
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open the URL'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // If canLaunchUrl returns false, try anyway
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open the URL'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
