import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lookup_provider.dart';
import '../../providers/notification_count_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/profile/profile_card.dart';
import '../../widgets/profile/stat_card.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/static_data_service.dart';
import '../../config/api_config.dart';
import '../../widgets/dashboard/dashboard_banner_slider.dart';
import '../../services/version_service.dart';
import '../../widgets/common/update_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final VersionService _versionService = VersionService();

  // Profile data (still needed for header)
  String? _profileName;
  String? _profileImageUrl;
  int? _heartsId;
  DateTime? _lastNotificationRefresh;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _refreshNotificationCounts();
    // Check for app updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
      // Load dashboard data using provider
      _loadDashboardData();
    });
  }

  // Load dashboard data with lookup provider
  Future<void> _loadDashboardData() async {
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final lookupProvider = Provider.of<LookupProvider>(context, listen: false);
    
    // Ensure static data is loaded FIRST
    final staticDataService = StaticDataService.instance;
    await staticDataService.loadAllData();
    
    // Ensure lookup data is loaded
    if (lookupProvider.lookupData.isEmpty) {
      await lookupProvider.loadLookupData();
    }
    
    // Load dashboard with lookup data
    await dashboardProvider.loadDashboard(
      lookupData: lookupProvider.lookupData,
      countries: lookupProvider.countries,
    );
  }

  // Load profile data for header (name, image, heartsId)
  Future<void> _loadProfileData() async {
    try {
      // First try to load from storage
      final storedName = await _storageService.getProfileName();
      final storedImageUrl = await _storageService.getProfileImageUrl();

      if (storedName != null && storedImageUrl != null) {
        if (mounted) {
          setState(() {
            _profileName = storedName;
            _profileImageUrl = storedImageUrl;
          });
        }
        return;
      }

      // If not in storage, fetch from API
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

          if (mounted) {
            setState(() {});
          }
        }
      } catch (e) {
        print('Error loading profile data: $e');
      }
    } catch (e) {
      print('Error loading profile data: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh notification counts when screen becomes visible again
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
      final updateInfo = await _versionService.checkForUpdate();
      
      if (updateInfo != null && mounted) {
        final forceUpgrade = updateInfo['forceUpgrade'] ?? false;
        final recommendUpgrade = updateInfo['recommendUpgrade'] ?? false;
        
        if (forceUpgrade || recommendUpgrade) {
          print('✅ Dashboard: Showing update dialog');
          showDialog(
            context: context,
            barrierDismissible: !forceUpgrade,
            builder: (context) => UpdateDialog(
              forceUpgrade: forceUpgrade,
              recommendUpgrade: recommendUpgrade,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Version check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final lookupProvider = Provider.of<LookupProvider>(context, listen: false);

    return RefreshIndicator(
      onRefresh: () => dashboardProvider.refresh(
        lookupData: lookupProvider.lookupData,
        countries: lookupProvider.countries,
      ),
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
                    value: dashboardProvider.acceptanceCount,
                    title: 'Acceptance',
                    subtitle: 'Matches accepted this week',
                    onTap: () => context.push('/acceptance'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    value: dashboardProvider.justJoinedCount,
                    title: 'Just Joined',
                    subtitle: 'New prospects today',
                    onTap: () => context.push('/just-joined'),
                  ),
                ),
              ],
            ),

            // Interest Received
            if (dashboardProvider.interestReceived.isNotEmpty || dashboardProvider.isLoading) ...[
              _buildSection(
                context,
                title: 'Interest Received',
                count: dashboardProvider.interestReceived.length,
                profiles: dashboardProvider.interestReceived,
                onViewAll: () => context.push('/interest-received'),
                isLoading: dashboardProvider.isLoading && dashboardProvider.interestReceived.isEmpty,
              ),
              const SizedBox(height: 32),
            ],
            // Daily Recommendations
            if (dashboardProvider.dailyRecommendations.isNotEmpty || dashboardProvider.isLoading) ...[
              _buildSection(
                context,
                title: 'Daily Recommendation',
                count: dashboardProvider.dailyRecommendations.length,
                profiles: dashboardProvider.dailyRecommendations,
                onViewAll: () => context.push('/daily-picks'),
                isLoading: dashboardProvider.isLoading && dashboardProvider.dailyRecommendations.isEmpty,
              ),
              const SizedBox(height: 32),
            ],
            // Profile Visitors
            if (dashboardProvider.profileVisitors.isNotEmpty || dashboardProvider.isLoading) ...[
              _buildSection(
                context,
                title: 'Profile Visitors',
                count: dashboardProvider.profileVisitors.length,
                profiles: dashboardProvider.profileVisitors,
                onViewAll: () => context.push('/profile-visitors'),
                isLoading: dashboardProvider.isLoading && dashboardProvider.profileVisitors.isEmpty,
              ),
              const SizedBox(height: 32),
            ],
            // All Profiles
            if (dashboardProvider.allProfiles.isNotEmpty || dashboardProvider.isLoading) ...[
              _buildSection(
                context,
                title: 'All Profiles',
                count: dashboardProvider.allProfiles.length,
                profiles: dashboardProvider.allProfiles,
                onViewAll: () => context.push('/profiles'),
                isLoading: dashboardProvider.isLoading && dashboardProvider.allProfiles.isEmpty,
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
