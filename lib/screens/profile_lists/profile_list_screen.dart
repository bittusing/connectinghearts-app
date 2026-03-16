import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../widgets/profile/profile_match_card.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/header_widget.dart';
import '../../widgets/common/bottom_navigation_widget.dart';
import '../../widgets/common/sidebar_widget.dart';
import '../../services/profile_service.dart';
import '../../models/profile_models.dart';
import '../../utils/profile_utils.dart';
import '../../providers/lookup_provider.dart';
import '../../services/static_data_service.dart';

enum ProfileListType {
  allProfiles,
  dailyRecommendations,
  profileVisitors,
  interestReceived,
  interestSent,
  shortlisted,
  ignored,
  blocked,
  iDeclined,
  theyDeclined,
  justJoined,
  unlocked,
}

class ProfileListScreen extends StatefulWidget {
  final ProfileListType listType;

  const ProfileListScreen({
    super.key,
    required this.listType,
  });

  @override
  State<ProfileListScreen> createState() => _ProfileListScreenState();
}

class _ProfileListScreenState extends State<ProfileListScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _profiles = [];

  String get _title {
    switch (widget.listType) {
      case ProfileListType.allProfiles:
        return 'All Profiles';
      case ProfileListType.dailyRecommendations:
        return 'Daily Recommendations';
      case ProfileListType.profileVisitors:
        return 'Profile Visitors';
      case ProfileListType.interestReceived:
        return 'Interests Received';
      case ProfileListType.interestSent:
        return 'Interests Sent';
      case ProfileListType.shortlisted:
        return 'Shortlisted Profiles';
      case ProfileListType.ignored:
        return 'Ignored Profiles';
      case ProfileListType.blocked:
        return 'Blocked Profiles';
      case ProfileListType.iDeclined:
        return 'I Declined';
      case ProfileListType.theyDeclined:
        return 'They Declined';
      case ProfileListType.justJoined:
        return 'Just Joined';
      case ProfileListType.unlocked:
        return 'Unlocked Profiles';
    }
  }

  String get _subtitle {
    switch (widget.listType) {
      case ProfileListType.allProfiles:
        return 'Browse every compatible profile curated for you.';
      case ProfileListType.dailyRecommendations:
        return 'Fresh suggestions based on your preferences.';
      case ProfileListType.profileVisitors:
        return 'Members who recently viewed your profile.';
      case ProfileListType.interestReceived:
        return 'Profiles that have sent you interest.';
      case ProfileListType.interestSent:
        return 'Profiles you have sent interest to.';
      case ProfileListType.shortlisted:
        return 'Profiles you have saved for later review.';
      case ProfileListType.ignored:
        return 'Profiles you have chosen to ignore.';
      case ProfileListType.blocked:
        return 'Profiles you have blocked.';
      case ProfileListType.iDeclined:
        return 'Profiles whose interest you declined.';
      case ProfileListType.theyDeclined:
        return 'Profiles that declined your interest.';
      case ProfileListType.justJoined:
        return 'New profiles that recently joined.';
      case ProfileListType.unlocked:
        return 'Profiles you have unlocked.';
    }
  }

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
      // Load static data first (cities, states, countries - fast, no API call)
      final staticDataService = StaticDataService.instance;
      await staticDataService.loadAllData();

      // Load lookup data for fallback
      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);
      if (lookupProvider.lookupData.isEmpty) {
        await lookupProvider.loadLookupData();
      }
      final lookupData = lookupProvider.lookupData;
      final countries = lookupProvider.countries;

      ApiProfileResponse response;

      switch (widget.listType) {
        case ProfileListType.allProfiles:
          response = await _profileService.getAllProfiles();
          break;
        case ProfileListType.dailyRecommendations:
          response = await _profileService.getDailyRecommendations();
          break;
        case ProfileListType.profileVisitors:
          response = await _profileService.getProfileVisitors();
          break;
        case ProfileListType.interestReceived:
          response = await _profileService.getInterestsReceived();
          break;
        case ProfileListType.interestSent:
          response = await _profileService.getInterestsSent();
          break;
        case ProfileListType.shortlisted:
          response = await _profileService.getShortlistedProfiles();
          break;
        case ProfileListType.ignored:
          response = await _profileService.getIgnoredProfiles();
          break;
        case ProfileListType.blocked:
          response = await _profileService.getBlockedProfiles();
          break;
        case ProfileListType.justJoined:
          response = await _profileService.getJustJoinedProfiles();
          break;
        default:
          response = await _profileService.getAllProfiles();
      }

      setState(() {
        _profiles = response.data
            .map((p) => transformProfile(p,
                lookupData: lookupData, countries: countries))
            .toList();
        _isLoading = false;
      });
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

  Future<void> _handleSendInterest(String profileId) async {
    try {
      await _profileService.sendInterest(profileId);
      _showToast('Interest sent successfully');
      _loadProfiles();
    } catch (e) {
      _showToast(e.toString(), isError: true);
    }
  }

  Future<void> _handleShortlist(String profileId) async {
    try {
      await _profileService.shortlistProfile(profileId);
      _showToast('Profile shortlisted successfully');
      _loadProfiles();
    } catch (e) {
      _showToast(e.toString(), isError: true);
    }
  }

  Future<void> _handleIgnore(String profileId) async {
    try {
      await _profileService.ignoreProfile(profileId);
      _showToast('Profile ignored successfully');
      _loadProfiles();
    } catch (e) {
      _showToast(e.toString(), isError: true);
    }
  }

  Future<void> _handleAccept(String profileId) async {
    try {
      await _profileService.acceptInterest(profileId);
      _showToast('Interest accepted successfully');
      _loadProfiles();
    } catch (e) {
      _showToast(e.toString(), isError: true);
    }
  }

  Future<void> _handleDecline(String profileId) async {
    try {
      await _profileService.declineInterest(profileId);
      _showToast('Interest declined');
      _loadProfiles();
    } catch (e) {
      _showToast(e.toString(), isError: true);
    }
  }

  Future<void> _handleUnshortlist(String profileId) async {
    try {
      await _profileService.unshortlistProfile(profileId);
      _showToast('Removed from shortlist');
      _loadProfiles();
    } catch (e) {
      _showToast(e.toString(), isError: true);
    }
  }

  Future<void> _handleUnignore(String profileId) async {
    try {
      await _profileService.unignoreProfile(profileId);
      _showToast('Profile restored');
      _loadProfiles();
    } catch (e) {
      _showToast(e.toString(), isError: true);
    }
  }

  Future<void> _handleUnblock(String profileId) async {
    try {
      await _profileService.unblockProfile(profileId);
      _showToast('Profile unblocked');
      _loadProfiles();
    } catch (e) {
      _showToast(e.toString(), isError: true);
    }
  }

  void _handleProfileTap(String profileId) {
    if (profileId.isNotEmpty) {
      context.push('/profile/$profileId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const HeaderWidget(),
      drawer: const SidebarWidget(),
      bottomNavigationBar: const BottomNavigationWidget(),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading $_title...',
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
                      onRefresh: _loadProfiles,
                      color: AppColors.primary,
                      child: PageView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: _profiles.length,
                        itemBuilder: (context, index) {
                          final profile = _profiles[index];
                          return GestureDetector(
                            onTap: () => _handleProfileTap(profile['clientID'] ?? profile['id']),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              child: ProfileMatchCard(
                                id: profile['id'] ?? '',
                                name: profile['name'] ?? '',
                                age: profile['age'] ?? 0,
                                height: formatHeightInMeters(profile['height']),
                                location: profile['location'] ?? '',
                                religion: profile['religion'],
                                salary: profile['income'],
                                imageUrl: profile['imageUrl'],
                                gender: profile['gender'],
                                onSendInterest: _shouldShowSendInterest()
                                    ? () => _handleSendInterest(profile['id'])
                                    : null,
                                onShortlist: _shouldShowShortlist()
                                    ? () => _handleShortlist(profile['id'])
                                    : null,
                                onIgnore: _shouldShowIgnore()
                                    ? () => _handleIgnore(profile['id'])
                                    : null,
                                onAcceptInterest: widget.listType ==
                                        ProfileListType.interestReceived
                                    ? () => _handleAccept(profile['id'])
                                    : null,
                                onDeclineInterest: widget.listType ==
                                        ProfileListType.interestReceived
                                    ? () => _handleDecline(profile['id'])
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  bool _shouldShowSendInterest() {
    return [
      ProfileListType.allProfiles,
      ProfileListType.dailyRecommendations,
      ProfileListType.profileVisitors,
      ProfileListType.justJoined,
    ].contains(widget.listType);
  }

  bool _shouldShowShortlist() {
    return [
      ProfileListType.allProfiles,
      ProfileListType.dailyRecommendations,
      ProfileListType.profileVisitors,
      ProfileListType.justJoined,
    ].contains(widget.listType);
  }

  bool _shouldShowIgnore() {
    return [
      ProfileListType.allProfiles,
      ProfileListType.dailyRecommendations,
      ProfileListType.profileVisitors,
      ProfileListType.justJoined,
    ].contains(widget.listType);
  }
}
