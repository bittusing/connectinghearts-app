import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/profile/profile_card.dart';
import '../../widgets/profile/stat_card.dart';
import '../../services/profile_service.dart';
import '../../utils/profile_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  int _acceptanceCount = 0;
  int _justJoinedCount = 0;
  List<Map<String, dynamic>> _dailyRecommendations = [];
  List<Map<String, dynamic>> _profileVisitors = [];
  List<Map<String, dynamic>> _allProfiles = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load stats
      final acceptanceResponse = await _profileService.getProfilesByEndpoint(
        'dashboard/getAcceptanceProfiles/acceptedMe',
      );
      final justJoinedResponse = await _profileService.getJustJoinedProfiles();

      // Load sections
      final dailyRecs = await _profileService.getDailyRecommendations();
      final visitors = await _profileService.getProfileVisitors();
      final allProfiles = await _profileService.getAllProfiles();

      if (mounted) {
        setState(() {
          _acceptanceCount = acceptanceResponse.data.length;
          _justJoinedCount = justJoinedResponse.data.length;
          _dailyRecommendations =
              dailyRecs.data.map((p) => transformProfile(p)).toList();
          _profileVisitors =
              visitors.data.map((p) => transformProfile(p)).toList();
          _allProfiles =
              allProfiles.data.map((p) => transformProfile(p)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
                            child: const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.success,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
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
                              authProvider.user?.name ??
                                  'HEARTS-${authProvider.user?.heartsId ?? ''}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              authProvider.user?.planName != null
                                  ? '${authProvider.user!.planName} Plan'
                                  : 'Profile completion 100%',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ),
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
            const SizedBox(height: 32),
            // Daily Recommendations
            _buildSection(
              context,
              title: 'Daily Recommendation',
              count: _dailyRecommendations.length,
              profiles: _dailyRecommendations,
              onViewAll: () => context.push('/daily-picks'),
              isLoading: _isLoading,
            ),
            const SizedBox(height: 32),
            // Profile Visitors
            _buildSection(
              context,
              title: 'Profile Visitors',
              count: _profileVisitors.length,
              profiles: _profileVisitors,
              onViewAll: () => context.push('/profile-visitors'),
              isLoading: _isLoading,
            ),
            const SizedBox(height: 32),
            // All Profiles
            _buildSection(
              context,
              title: 'All Profiles',
              count: _allProfiles.length,
              profiles: _allProfiles,
              onViewAll: () => context.push('/profiles'),
              isLoading: _isLoading,
            ),
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
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                        ),
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
                            height: profile['height'] ?? '',
                            location: profile['location'] ?? '',
                            imageUrl: profile['imageUrl'],
                            gender: profile['gender'],
                            onTap: () => context.push(
                                '/profile/${profile['clientID'] ?? profile['id']}'),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
