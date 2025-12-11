import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../widgets/profile/profile_match_card.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../services/profile_service.dart';
import '../../providers/lookup_provider.dart';
import '../../utils/profile_utils.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  final List<Map<String, dynamic>> _profiles = [];

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
      // Load lookup data first
      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);
      await lookupProvider.loadLookupData();

      // Fetch profiles - the API returns filteredProfiles array
      final response = await _profileService.getAllProfiles();
      if (response.success && response.data.isNotEmpty) {
        final lookupData = lookupProvider.lookupData;
        final transformedProfiles = response.data.map((apiProfile) {
          return transformProfile(apiProfile, lookupData: lookupData);
        }).toList();

        if (mounted) {
          setState(() {
            _profiles.clear();
            _profiles.addAll(transformedProfiles);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'No profiles found';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadProfiles();
  }

  void _handleProfileTap(String clientId) {
    context.push('/profile/$clientId');
  }

  void _handleSendInterest(String profileId) async {
    try {
      await _profileService.sendInterest(profileId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interest sent successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send interest: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleShortlist(String profileId) async {
    try {
      await _profileService.shortlistProfile(profileId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile shortlisted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to shortlist: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleIgnore(String profileId) async {
    try {
      await _profileService.ignoreProfile(profileId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile ignored successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        // Remove from list
        setState(() {
          _profiles.removeWhere((p) => p['id'] == profileId);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ignore: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading profiles...',
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
                        message: 'No profiles found.',
                        icon: Icons.people_outline,
                      )
                    : RefreshIndicator(
                        onRefresh: _onRefresh,
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
                                  id: profile['id'],
                                  name: profile['name'],
                                  age: profile['age'],
                                  height: profile['height'],
                                  location: profile['location'],
                                  religion: profile['religion'],
                                  salary: profile['income'],
                                  imageUrl: profile['imageUrl'],
                                  gender: profile['gender'],
                                  onSendInterest: () => _handleSendInterest(
                                      profile['clientID'] ?? profile['id']),
                                  onShortlist: () => _handleShortlist(
                                      profile['clientID'] ?? profile['id']),
                                  onIgnore: () => _handleIgnore(
                                      profile['clientID'] ?? profile['id']),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
