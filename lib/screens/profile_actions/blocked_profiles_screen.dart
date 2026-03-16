import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../widgets/profile/profile_match_card.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/bottom_navigation_widget.dart';
import '../../widgets/common/header_widget.dart';
import '../../services/profile_service.dart';
import '../../utils/profile_utils.dart';
import '../../providers/notification_count_provider.dart';

class BlockedProfilesScreen extends StatefulWidget {
  const BlockedProfilesScreen({super.key});

  @override
  State<BlockedProfilesScreen> createState() => _BlockedProfilesScreenState();
}

class _BlockedProfilesScreenState extends State<BlockedProfilesScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _profileService.getBlockedProfiles();
      final profiles = response.data.map((p) => transformProfile(p)).toList();

      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });

      // Mark notifications as seen (like webapp)
      if (profiles.isNotEmpty && mounted) {
        final profileIds = profiles
            .map((p) => p['id']?.toString())
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toList();

        if (profileIds.isNotEmpty) {
          try {
            await _profileService.updateNotificationCount(
              profileIds,
              'blockedProfile',
            );
            // Refresh notification counts
            if (mounted) {
              Provider.of<NotificationCountProvider>(context, listen: false)
                  .fetchCounts();
            }
          } catch (e) {
            // Silently fail - this is a background operation
            print('Failed to update notification count: $e');
          }
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _handleUnblock(String profileId) async {
    try {
      await _profileService.unblockProfile(profileId);
      _showToast('Profile unblocked');
      _loadProfiles();
      // Refresh notification counts after action
      if (mounted) {
        Provider.of<NotificationCountProvider>(context, listen: false)
            .fetchCounts();
      }
    } catch (e) {
      _showToast(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderWidget(),
      bottomNavigationBar: const BottomNavigationWidget(),
      body: RefreshIndicator(
        onRefresh: _loadProfiles,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProfiles,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _profiles.isEmpty
                    ? const EmptyStateWidget(
                        message: 'No blocked profiles.',
                        icon: Icons.block_outlined,
                      )
                    : PageView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: _profiles.length,
                        itemBuilder: (context, index) {
                          final profile = _profiles[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            child: ProfileMatchCard(
                              id: profile['id'] ?? '',
                              name: profile['name'] ?? '',
                              age: profile['age'] ?? 0,
                              height: profile['height'] ?? '',
                              location: profile['location'] ?? '',
                              religion: profile['religion'],
                              salary: profile['income'],
                              imageUrl: profile['imageUrl'],
                              gender: profile['gender'],
                              onTap: () => context.push(
                                '/profile/${profile['clientID'] ?? profile['id']}',
                              ),
                              customActions: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildCustomButton(
                                    icon: Icons.block,
                                    label: 'Unblock',
                                    color: Colors.green,
                                    onTap: () =>
                                        _handleUnblock(profile['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildCustomButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
