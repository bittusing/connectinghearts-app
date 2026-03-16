import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../widgets/profile/profile_match_card.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/bottom_navigation_widget.dart';
import '../../widgets/common/header_widget.dart';
import '../../services/profile_service.dart';
import '../../utils/profile_utils.dart';
import '../../providers/notification_count_provider.dart';

class UnlockedProfilesScreen extends StatefulWidget {
  const UnlockedProfilesScreen({super.key});

  @override
  State<UnlockedProfilesScreen> createState() => _UnlockedProfilesScreenState();
}

class _UnlockedProfilesScreenState extends State<UnlockedProfilesScreen> {
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
      final response = await _profileService.getUnlockedProfiles();
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
              'unlockedProfiles',
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

  void _handleProfileTap(String clientId) {
    context.push('/profile/$clientId');
  }

  Future<void> _handleSendInterest(String profileId) async {
    try {
      await _profileService.sendInterest(profileId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Interest sent successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      // Refresh notification counts after action
      if (mounted) {
        Provider.of<NotificationCountProvider>(context, listen: false)
            .fetchCounts();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleShortlist(String profileId) async {
    try {
      await _profileService.shortlistProfile(profileId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile shortlisted'),
          backgroundColor: AppColors.success,
        ),
      );
      // Refresh notification counts after action
      if (mounted) {
        Provider.of<NotificationCountProvider>(context, listen: false)
            .fetchCounts();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleIgnore(String profileId) async {
    try {
      await _profileService.ignoreProfile(profileId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile ignored'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadProfiles();
      // Refresh notification counts after action
      if (mounted) {
        Provider.of<NotificationCountProvider>(context, listen: false)
            .fetchCounts();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const HeaderWidget(),
      bottomNavigationBar: const BottomNavigationWidget(),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading unlocked profiles...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
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
                      message: 'No unlocked profiles yet.',
                      icon: Icons.lock_open_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProfiles,
                      color: AppColors.primary,
                      child: PageView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: _profiles.length,
                        itemBuilder: (context, index) {
                          final profile = _profiles[index];
                          return GestureDetector(
                            onTap: () => _handleProfileTap(
                                profile['clientID'] ?? profile['id']),
                            child: Padding(
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
                                onSendInterest: () =>
                                    _handleSendInterest(profile['id']),
                                onShortlist: () =>
                                    _handleShortlist(profile['id']),
                                onIgnore: () =>
                                    _handleIgnore(profile['id']),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
