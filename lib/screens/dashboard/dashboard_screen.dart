import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lookup_provider.dart';
import '../../providers/notification_count_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/profile/profile_card.dart';
import '../../widgets/profile/stat_card.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../utils/profile_utils.dart';
import '../../config/api_config.dart';
import '../../widgets/dashboard/dashboard_banner_slider.dart';
import '../../models/profile_models.dart';
import '../../services/static_data_service.dart';
import '../../services/version_service.dart';
import '../../widgets/common/update_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final VersionService _versionService = VersionService();
  bool _isLoading = true;
  int _acceptanceCount = 0;
  int _justJoinedCount = 0;
  List<Map<String, dynamic>> _interestReceived = [];
  List<Map<String, dynamic>> _dailyRecommendations = [];
  List<Map<String, dynamic>> _profileVisitors = [];
  List<Map<String, dynamic>> _allProfiles = [];

  // Loading states for each section
  bool _isLoadingInterestReceived = true;
  bool _isLoadingDailyRecommendations = true;
  bool _isLoadingProfileVisitors = true;
  bool _isLoadingAllProfiles = true;

  // Profile data
  String? _profileName;
  String? _profileImageUrl;
  int? _heartsId;
  DateTime? _lastNotificationRefresh;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Refresh notification counts when dashboard opens
    _refreshNotificationCounts();
    // Check for app updates - use addPostFrameCallback to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh notification counts when screen becomes visible again
    // Only refresh if it's been more than 1 second since last refresh (avoid too many calls)
    final now = DateTime.now();
    if (_lastNotificationRefresh == null ||
        now.difference(_lastNotificationRefresh!).inSeconds > 1) {
      _refreshNotificationCounts();
    }
  }

  void _refreshNotificationCounts() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          _lastNotificationRefresh = DateTime.now();
          Provider.of<NotificationCountProvider>(context, listen: false)
              .fetchCounts();
        } catch (e) {
          // Provider might not be available, ignore silently
        }
      }
    });
  }

  Future<void> _checkForUpdate() async {
    print('🔍 Dashboard: Checking for update...');
    try {
      // TEMPORARY: For testing - Uncomment below to test popup without backend API
      
      if (mounted) {
        print('✅ Dashboard: Showing update dialog (TEST MODE)');
        showDialog(
          context: context,
          barrierDismissible: false, // Force update - can't dismiss
          builder: (context) => const UpdateDialog(
            forceUpgrade: true,  // Change to false for optional update
            recommendUpgrade: false,
          ),
        );
        return;
      }
      
      
      final updateInfo = await _versionService.checkForUpdate();
      
      if (updateInfo != null && mounted) {
        final forceUpgrade = updateInfo['forceUpgrade'] ?? false;
        final recommendUpgrade = updateInfo['recommendUpgrade'] ?? false;
        
        if (forceUpgrade || recommendUpgrade) {
          print('✅ Dashboard: Showing update dialog');
          // Show update dialog
          showDialog(
            context: context,
            barrierDismissible: !forceUpgrade, // Can't dismiss if force upgrade
            builder: (context) => UpdateDialog(
              forceUpgrade: forceUpgrade,
              recommendUpgrade: recommendUpgrade,
            ),
          );
        }
      }
    } catch (e) {
      // Silently fail - don't block user
      print('❌ Version check failed: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

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

      // Only call getUser API if storage doesn't have data
      if (_profileName == null || _profileImageUrl == null) {
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
                    userId,
                    primaryPic['id'].toString(),
                  );
                  _profileImageUrl = imageUrl;
                  await _storageService.setProfileImageUrl(imageUrl);
                }
              }
            }

            // Extract heartsId
            final heartsIdValue = userData['heartsId'];
            if (heartsIdValue != null) {
              _heartsId = heartsIdValue is int
                  ? heartsIdValue
                  : int.tryParse(heartsIdValue.toString());
            }
          }
        } catch (e) {
          // If getUser fails, continue with stored data or fallback
        }
      }

      // Fallback: Fetch user profile data if storage and getUser didn't provide name/image
      if (_profileName == null || _profileImageUrl == null) {
        final profileResponse = await _profileService.getUserProfileData();
        if (profileResponse['status'] == 'success' &&
            profileResponse['data'] != null) {
          final data = profileResponse['data'] as Map<String, dynamic>;
          final basic = data['basic'] as Map<String, dynamic>?;
          final misc = data['miscellaneous'] as Map<String, dynamic>?;

          // Extract name and heartsId
          if (_profileName == null) {
            _profileName = basic?['name']?.toString() ??
                (misc?['heartsId'] != null
                    ? 'HEARTS-${misc!['heartsId']}'
                    : null);
            if (_profileName != null) {
              await _storageService.setProfileName(_profileName!);
            }
          }

          if (_heartsId == null) {
            _heartsId = misc?['heartsId'] is int
                ? misc!['heartsId'] as int
                : (misc?['heartsId'] != null
                    ? int.tryParse(misc!['heartsId'].toString())
                    : null);
          }

          // Extract profile picture
          if (_profileImageUrl == null) {
            final profilePic = misc?['profilePic'] as List<dynamic>?;
            if (profilePic != null && profilePic.isNotEmpty) {
              final primaryPic = profilePic.firstWhere(
                (pic) => pic['primary'] == true,
                orElse: () => profilePic.first,
              ) as Map<String, dynamic>?;

              if (primaryPic != null && primaryPic['id'] != null) {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                final userId = authProvider.user?.id ??
                    _heartsId?.toString() ??
                    misc?['clientID']?.toString() ??
                    '';
                if (userId.isNotEmpty) {
                  _profileImageUrl = ApiConfig.buildImageUrl(
                    userId,
                    primaryPic['id'].toString(),
                  );
                  await _storageService.setProfileImageUrl(_profileImageUrl!);
                }
              }
            }
          }
        }
      }

      // Load static data first (cities, states, countries - fast, no API call)
      final staticDataService = StaticDataService.instance;
      await staticDataService.loadAllData();

      // Load lookup data for location resolution (only if not already loaded)
      final lookupProvider = Provider.of<LookupProvider>(
        context,
        listen: false,
      );
      if (lookupProvider.lookupData.isEmpty) {
        await lookupProvider.loadLookupData();
      }
      final lookupData = lookupProvider.lookupData;
      final countries = lookupProvider.countries;

      // Load only essential stats first (for stat cards)
      final statsFuture = Future.wait([
        _profileService.getProfilesByEndpoint(
          'dashboard/getAcceptanceProfiles/acceptedMe',
        ),
        _profileService.getJustJoinedProfiles(),
      ]);

      final stats = await statsFuture;
      final acceptanceResponse = stats[0];
      final justJoinedResponse = stats[1];

      // Load sections lazily - only load first 3-5 profiles per section
      // Load sections in parallel but limit data
      final sectionsFuture = Future.wait([
        _profileService.getInterestsReceived().then((response) {
          if (mounted) setState(() => _isLoadingInterestReceived = false);
          // Limit to first 5 profiles for dashboard preview
          return ApiProfileResponse(
            status: response.status,
            data: response.data.take(5).toList(),
          );
        }).catchError((e) {
          if (mounted) setState(() => _isLoadingInterestReceived = false);
          return ApiProfileResponse(status: 'error', data: []);
        }),
        _profileService.getDailyRecommendations().then((response) {
          if (mounted) setState(() => _isLoadingDailyRecommendations = false);
          return ApiProfileResponse(
            status: response.status,
            data: response.data.take(5).toList(),
          );
        }).catchError((e) {
          if (mounted) setState(() => _isLoadingDailyRecommendations = false);
          return ApiProfileResponse(status: 'error', data: []);
        }),
        _profileService.getProfileVisitors().then((response) {
          if (mounted) setState(() => _isLoadingProfileVisitors = false);
          return ApiProfileResponse(
            status: response.status,
            data: response.data.take(5).toList(),
          );
        }).catchError((e) {
          if (mounted) setState(() => _isLoadingProfileVisitors = false);
          return ApiProfileResponse(status: 'error', data: []);
        }),
        _profileService.getAllProfiles().then((response) {
          if (mounted) setState(() => _isLoadingAllProfiles = false);
          return ApiProfileResponse(
            status: response.status,
            data: response.data.take(5).toList(),
          );
        }).catchError((e) {
          if (mounted) setState(() => _isLoadingAllProfiles = false);
          return ApiProfileResponse(status: 'error', data: []);
        }),
      ]);

      final sections = await sectionsFuture;
      final interestReceived = sections[0];
      final dailyRecs = sections[1];
      final visitors = sections[2];
      final allProfiles = sections[3];

      // Capture countries for use in setState closure
      final countriesList = countries;

      // Transform profiles using simple transformProfile (no expensive location resolution)
      if (mounted) {
        setState(() {
          _acceptanceCount = acceptanceResponse.data.length;
          _justJoinedCount = justJoinedResponse.data.length;
          _interestReceived = interestReceived.data
              .map(
                (p) => transformProfile(
                  p,
                  lookupData: lookupData,
                  countries: countriesList,
                ),
              )
              .toList();
          _dailyRecommendations = dailyRecs.data
              .map(
                (p) => transformProfile(
                  p,
                  lookupData: lookupData,
                  countries: countriesList,
                ),
              )
              .toList();
          _profileVisitors = visitors.data
              .map(
                (p) => transformProfile(
                  p,
                  lookupData: lookupData,
                  countries: countriesList,
                ),
              )
              .toList();
          _allProfiles = allProfiles.data
              .map(
                (p) => transformProfile(
                  p,
                  lookupData: lookupData,
                  countries: countriesList,
                ),
              )
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: AppColors.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 4,
                              ),
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: _profileImageUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      _profileImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.white,
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOUR PROFILE',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 2,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _profileName ??
                                  authProvider.user?.name ??
                                  (_heartsId != null
                                      ? 'HEARTS-$_heartsId'
                                      : 'HEARTS-${authProvider.user?.heartsId ?? ''}'),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ACTIVATE YOUR PLAN Section
                  Column(
                    children: [
                      Text(
                        'ACTIVATE YOUR PLAN',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => context.push('/membership'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            'Upgrade for premium features',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Banner Slider
            DashboardBannerSlider(
              slides: const [
                {
                  'image': 'assets/images/banner11.jpg',
                  'title': 'Heartfulness Celebrations',
                },
                {
                  'image': 'assets/images/banner1.jpg',
                  'title': 'Heartfulness Weddings',
                },
                {
                  'image': 'assets/images/banner2.jpg',
                  'title': 'Celebrating Togetherness',
                },
                {
                  'image': 'assets/images/banner3.jpg',
                  'title': 'Sacred Moments',
                },
              ],
            ),
            const SizedBox(height: 16),
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    value: _acceptanceCount,
                    title: 'Acceptance',
                    subtitle: 'Matches accepted this week',
                    onTap: () => context.push('/acceptance'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    value: _justJoinedCount,
                    title: 'Just Joined',
                    subtitle: 'New prospects today',
                    onTap: () => context.push('/just-joined'),
                  ),
                ),
              ],
            ),

            // Interest Received - only show if data exists or loading
            if (_interestReceived.length > 0 || _isLoadingInterestReceived) ...[
              _buildSection(
                context,
                title: 'Interest Received',
                count: _interestReceived.length,
                profiles: _interestReceived,
                onViewAll: () => context.push('/interest-received'),
                isLoading: _isLoadingInterestReceived,
              ),
              const SizedBox(height: 32),
            ],
            // Daily Recommendations - only show if data exists or loading
            if (_dailyRecommendations.length > 0 ||
                _isLoadingDailyRecommendations) ...[
              _buildSection(
                context,
                title: 'Daily Recommendation',
                count: _dailyRecommendations.length,
                profiles: _dailyRecommendations,
                onViewAll: () => context.push('/daily-picks'),
                isLoading: _isLoadingDailyRecommendations,
              ),
              const SizedBox(height: 32),
            ],
            // Profile Visitors - only show if data exists or loading
            if (_profileVisitors.length > 0 || _isLoadingProfileVisitors) ...[
              _buildSection(
                context,
                title: 'Profile Visitors',
                count: _profileVisitors.length,
                profiles: _profileVisitors,
                onViewAll: () => context.push('/profile-visitors'),
                isLoading: _isLoadingProfileVisitors,
              ),
              const SizedBox(height: 32),
            ],
            // All Profiles - only show if data exists or loading
            if (_allProfiles.length > 0 || _isLoadingAllProfiles) ...[
              _buildSection(
                context,
                title: 'All Profiles',
                count: _allProfiles.length,
                profiles: _allProfiles,
                onViewAll: () => context.push('/profiles'),
                isLoading: _isLoadingAllProfiles,
              ),
              const SizedBox(height: 32),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required int count,
    required List<Map<String, dynamic>> profiles,
    required VoidCallback onViewAll,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count ${count == 1 ? 'RESULT' : 'RESULTS'}',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onViewAll,
                icon: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                label: const Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : profiles.isEmpty
                  ? Center(
                      child: Text(
                        'No profiles available',
                        style:
                            TextStyle(color: theme.textTheme.bodySmall?.color),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      itemCount: profiles.length > 3 ? 3 : profiles.length,
                      itemBuilder: (context, index) {
                        final profile = profiles[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: ProfileCard(
                            name: profile['name'] ??
                                'HEARTS-${profile['id'] ?? ''}',
                            age: profile['age'] ?? 0,
                            height: profile['height']?.toString() ?? '',
                            location: profile['location'] ?? '',
                            cast: profile['caste'] ?? profile['cast'] ?? '',
                            imageUrl: profile['imageUrl'],
                            gender: profile['gender'],
                            onTap: () => context.push(
                              '/profile/${profile['clientID'] ?? profile['id']}',
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
