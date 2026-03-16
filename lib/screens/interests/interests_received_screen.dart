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

class InterestsReceivedScreen extends StatefulWidget {
  const InterestsReceivedScreen({super.key});

  @override
  State<InterestsReceivedScreen> createState() =>
      _InterestsReceivedScreenState();
}

class _InterestsReceivedScreenState extends State<InterestsReceivedScreen> {
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
      final response = await _profileService.getInterestsReceived();
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
              'interestReceived',
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

  void _handleProfileTap(String clientId) {
    context.push('/profile/$clientId');
  }

  Future<void> _handleAccept(String profileId) async {
    try {
      await _profileService.acceptInterest(profileId);
      _showToast('Interest accepted successfully');
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

  Future<void> _handleDecline(String profileId) async {
    try {
      await _profileService.declineInterest(profileId);
      _showToast('Interest declined');
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
                    'Loading interests received...',
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
                      message: 'No interests received yet.',
                      icon: Icons.favorite_outline,
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
                                onAcceptInterest: () =>
                                    _handleAccept(profile['id']),
                                onDeclineInterest: () =>
                                    _handleDecline(profile['id']),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
