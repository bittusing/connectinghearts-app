import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../services/profile_service.dart';
import '../../widgets/common/confirm_modal.dart';

class ProfileDetailScreen extends StatefulWidget {
  final String profileId;

  const ProfileDetailScreen({
    super.key,
    required this.profileId,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen>
    with SingleTickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profile;
  int _currentImageIndex = 0;

  bool _hasSentInterest = false;
  bool _isShortlisted = false;
  bool _isIgnored = false;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _profileService.getProfileDetail(widget.profileId);
      setState(() {
        _profile = response.data;
        _isShortlisted = _profile?['isShortlisted'] ?? false;
        _isIgnored = _profile?['isIgnored'] ?? false;
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

  Future<void> _handleSendInterest() async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    try {
      if (_hasSentInterest) {
        await _profileService.unsendInterest(widget.profileId);
        setState(() => _hasSentInterest = false);
        _showToast('Interest withdrawn');
      } else {
        await _profileService.sendInterest(widget.profileId);
        setState(() => _hasSentInterest = true);
        _showToast('Interest sent successfully');
      }
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleShortlist() async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    try {
      if (_isShortlisted) {
        await _profileService.unshortlistProfile(widget.profileId);
        setState(() => _isShortlisted = false);
        _showToast('Removed from shortlist');
      } else {
        await _profileService.shortlistProfile(widget.profileId);
        setState(() => _isShortlisted = true);
        _showToast('Profile shortlisted');
      }
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleIgnore() async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    try {
      if (_isIgnored) {
        await _profileService.unignoreProfile(widget.profileId);
        setState(() => _isIgnored = false);
        _showToast('Profile restored');
      } else {
        await _profileService.ignoreProfile(widget.profileId);
        setState(() => _isIgnored = true);
        _showToast('Profile ignored');
      }
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleUnlock() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Unlock Profile?',
      description: 'This will cost you 1 heart coin!',
      confirmLabel: 'Unlock',
    );

    if (confirmed != true) return;

    try {
      final response = await _profileService.unlockProfile(widget.profileId);
      if (response.success) {
        _showToast('Profile unlocked successfully');
        _loadProfile();
      } else {
        if (response.redirectToMembership) {
          context.push('/membership');
        }
        _showToast(response.message ?? 'Failed to unlock', isError: true);
      }
    } catch (e) {
      _showToast(e.toString(), isError: true);
    }
  }

  void _handleChat() {
    _showToast('Chat Coming Soon');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error ?? 'Profile not found',
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final name = _profile!['name'] ?? 'Unknown';
    final age = _profile!['age'] ?? '';
    final profileId = _profile!['profileId'] ?? '';
    final profilePics = _profile!['allProfilePics'] as List<dynamic>? ?? [];
    final currentImage =
        profilePics.isNotEmpty && _currentImageIndex < profilePics.length
            ? profilePics[_currentImageIndex]['url']
            : _profile!['avatar'];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image Header
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.5,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Profile Image
                  currentImage != null
                      ? CachedNetworkImage(
                          imageUrl: currentImage,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: theme.dividerColor,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: theme.dividerColor,
                            child: const Icon(Icons.person, size: 100),
                          ),
                        )
                      : Container(
                          color: theme.dividerColor,
                          child: const Icon(Icons.person, size: 100),
                        ),
                  // Gradient Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (profileId.isNotEmpty)
                            Text(
                              profileId,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          Text(
                            '$name, $age',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Image Navigation
                  if (profilePics.length > 1) ...[
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${profilePics.length}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _currentImageIndex = (_currentImageIndex -
                                      1 +
                                      profilePics.length) %
                                  profilePics.length;
                            });
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _currentImageIndex =
                                  (_currentImageIndex + 1) % profilePics.length;
                            });
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Dots indicator
                    Positioned(
                      bottom: 80,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(profilePics.length, (index) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == _currentImageIndex
                                  ? Colors.white
                                  : Colors.white54,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Basic'),
                  Tab(text: 'Family'),
                  Tab(text: 'Kundali'),
                  Tab(text: 'Match'),
                ],
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
              ),
              theme.cardColor,
            ),
          ),
          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicTab(),
                _buildFamilyTab(),
                _buildKundaliTab(),
                _buildMatchTab(),
              ],
            ),
          ),
        ],
      ),
      // Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              _buildActionButton(
                icon: _hasSentInterest ? Icons.send : Icons.send_outlined,
                label: _hasSentInterest ? 'Withdraw' : 'Interest',
                color: _hasSentInterest ? Colors.grey : AppColors.primary,
                onTap: _handleSendInterest,
              ),
              _buildActionButton(
                icon: Icons.phone_outlined,
                label: 'Contact',
                onTap: _handleUnlock,
              ),
              _buildActionButton(
                icon: _isShortlisted ? Icons.bookmark : Icons.bookmark_border,
                label: _isShortlisted ? 'Saved' : 'Shortlist',
                onTap: _handleShortlist,
              ),
              _buildActionButton(
                icon: _isIgnored ? Icons.visibility_off : Icons.block,
                label: _isIgnored ? 'Restore' : 'Ignore',
                onTap: _handleIgnore,
              ),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                onTap: _handleChat,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: _isActionLoading ? null : onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color ?? Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoGrid([
            {'label': 'Height', 'value': _profile!['height']},
            {'label': 'Location', 'value': _profile!['location']},
            {'label': 'Caste', 'value': _profile!['caste']},
            {'label': 'Income', 'value': _profile!['income']},
            {'label': 'Marital Status', 'value': _profile!['maritalStatus']},
            {'label': 'Body Type', 'value': _profile!['bodyType']},
          ]),
          const SizedBox(height: 24),
          if (_profile!['aboutMe'] != null) ...[
            _buildSection('About Me', _profile!['aboutMe']),
            const SizedBox(height: 24),
          ],
          if (_profile!['occupation'] != null ||
              _profile!['employedIn'] != null) ...[
            _buildSectionTitle('Career'),
            _buildInfoGrid([
              {'label': 'Occupation', 'value': _profile!['occupation']},
              {'label': 'Employed In', 'value': _profile!['employedIn']},
              {'label': 'Organisation', 'value': _profile!['organisationName']},
            ]),
            if (_profile!['aboutCareer'] != null) ...[
              const SizedBox(height: 8),
              Text(_profile!['aboutCareer']),
            ],
            const SizedBox(height: 24),
          ],
          if (_profile!['qualification'] != null) ...[
            _buildSectionTitle('Education'),
            _buildInfoGrid([
              {'label': 'Qualification', 'value': _profile!['qualification']},
              {'label': 'School', 'value': _profile!['school']},
            ]),
            const SizedBox(height: 24),
          ],
          // Contact Details (if unlocked)
          if (_profile!['isUnlocked'] == true &&
              _profile!['contactDetails'] != null) ...[
            _buildSectionTitle('Contact Details'),
            _buildInfoGrid([
              {'label': 'Name', 'value': _profile!['contactDetails']['name']},
              {
                'label': 'Phone',
                'value': _profile!['contactDetails']['phoneNumber']
              },
              {'label': 'Email', 'value': _profile!['contactDetails']['email']},
            ]),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildFamilyTab() {
    final family = _profile!['familyDetails'] as Map<String, dynamic>?;
    if (family == null) {
      return const Center(child: Text('No family details available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoGrid([
            {'label': 'Family Type', 'value': family['familyType']},
            {'label': 'Family Status', 'value': family['familyStatus']},
            {'label': 'Family Values', 'value': family['familyValues']},
            {'label': 'Father Occupation', 'value': family['fatherOccupation']},
            {'label': 'Mother Occupation', 'value': family['motherOccupation']},
            {'label': 'Brothers', 'value': family['brothers']?.toString()},
            {'label': 'Sisters', 'value': family['sisters']?.toString()},
            {'label': 'Gothra', 'value': family['gothra']},
            {
              'label': 'Living with Parents',
              'value': family['livingWithParents']
            },
          ]),
          if (family['aboutMyFamily'] != null) ...[
            const SizedBox(height: 16),
            _buildSection('About Family', family['aboutMyFamily']),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildKundaliTab() {
    final kundali = _profile!['kundaliDetails'] as Map<String, dynamic>?;
    final lifestyle = _profile!['lifestyleData'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kundali != null) ...[
            _buildSectionTitle('Kundali & Astro'),
            _buildInfoGrid([
              {'label': 'Rashi', 'value': kundali['rashi']},
              {'label': 'Nakshatra', 'value': kundali['nakshatra']},
              {'label': 'Manglik', 'value': kundali['manglik']},
              {'label': 'Time of Birth', 'value': kundali['timeOfBirth']},
              {'label': 'Place of Birth', 'value': kundali['placeOfBirth']},
            ]),
            const SizedBox(height: 24),
          ],
          if (lifestyle != null) ...[
            _buildSectionTitle('Lifestyle'),
            _buildHabitsRow(lifestyle),
            const SizedBox(height: 16),
            _buildInfoGrid([
              {
                'label': 'Hobbies',
                'value': (lifestyle['hobbies'] as List?)?.join(', ')
              },
              {
                'label': 'Interests',
                'value': (lifestyle['interest'] as List?)?.join(', ')
              },
              {
                'label': 'Languages',
                'value': (lifestyle['languages'] as List?)?.join(', ')
              },
              {
                'label': 'Sports',
                'value': (lifestyle['sports'] as List?)?.join(', ')
              },
            ]),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMatchTab() {
    final matchDetails = _profile!['matchDetails'] as Map<String, dynamic>?;
    final matchData = matchDetails?['matchData'] as List<dynamic>? ?? [];
    final matchPercentage = matchDetails?['matchPercentage'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (matchPercentage != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Colors.pinkAccent],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '$matchPercentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Match',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          ...matchData.map((match) {
            final isMatched = match['isMatched'] ?? false;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match['label'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          match['value'] ?? '',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isMatched ? Icons.check_circle : Icons.cancel,
                    color: isMatched ? AppColors.success : Colors.grey,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Text(content),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(List<Map<String, String?>> items) {
    final validItems = items
        .where((item) => item['value'] != null && item['value']!.isNotEmpty)
        .toList();

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: validItems.map((item) {
        return Container(
          width: (MediaQuery.of(context).size.width - 48) / 2,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['label']!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item['value']!,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHabitsRow(Map<String, dynamic> lifestyle) {
    return Row(
      children: [
        if (lifestyle['dietaryHabits'] != null)
          Expanded(
            child: _buildHabitCard(
              Icons.restaurant,
              lifestyle['dietaryHabits'],
            ),
          ),
        if (lifestyle['drinkingHabits'] != null)
          Expanded(
            child: _buildHabitCard(
              Icons.local_bar,
              lifestyle['drinkingHabits'],
            ),
          ),
        if (lifestyle['smokingHabits'] != null)
          Expanded(
            child: _buildHabitCard(
              Icons.smoking_rooms,
              lifestyle['smokingHabits'],
            ),
          ),
      ],
    );
  }

  Widget _buildHabitCard(IconData icon, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
