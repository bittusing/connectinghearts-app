import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../services/profile_service.dart';
import '../../providers/lookup_provider.dart';
import '../../utils/profile_utils.dart';
import '../../config/api_config.dart';

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
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey<State<StatefulWidget>>> _sectionKeys = {};

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profile;
  int _currentImageIndex = 0;

  bool _hasSentInterest = false;
  bool _isShortlisted = false;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    // Create keys for each section
    for (int i = 0; i < 6; i++) {
      _sectionKeys[i] = GlobalKey<State<StatefulWidget>>();
    }
    _loadProfile();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Auto-change tabs based on scroll position
      for (int i = 0; i < 6; i++) {
        final key = _sectionKeys[i];
        if (key?.currentContext != null) {
          final RenderBox? box =
              key?.currentContext?.findRenderObject() as RenderBox?;
          if (box != null) {
            final position = box.localToGlobal(Offset.zero);
            // Check if section is in viewport (accounting for tab bar height ~50)
            if (position.dy <= 150 && position.dy >= -50) {
              if (_tabController.index != i &&
                  !_tabController.indexIsChanging) {
                _tabController.animateTo(i);
              }
              break;
            }
          }
        }
      }
    });
  }

  void _scrollToSection(int index) {
    final key = _sectionKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1, // Scroll to show section just below tab bar
      );
    }
  }

  Widget _buildSection(
      {required GlobalKey<State<StatefulWidget>> key, required Widget child}) {
    return Container(
      key: key,
      child: child,
    );
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load lookup data first
      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);
      await lookupProvider.loadLookupData();

      // Use getDetailView1 endpoint
      final response = await _profileService.getDetailView1(widget.profileId);
      // API returns { code, status, data: { ... } }
      final profileData = response['data'] as Map<String, dynamic>? ?? response;

      setState(() {
        _profile = profileData;
        final miscellaneous =
            profileData['miscellaneous'] as Map<String, dynamic>? ?? {};
        _isShortlisted = miscellaneous['isShortlisted'] ?? false;
        _hasSentInterest =
            false; // Not in API response, would need separate call
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

  void _handleChat() {
    _showToast('Chat Coming Soon');
  }

  Future<void> _handleSuperInterest() async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    try {
      // Super interest is typically the same as regular interest but with a premium feature
      // For now, we'll use the regular interest endpoint
      await _profileService.sendInterest(widget.profileId);
      setState(() => _hasSentInterest = true);
      _showToast('Super Interest sent successfully');
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      setState(() => _isActionLoading = false);
    }
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

    final miscellaneous =
        _profile!['miscellaneous'] as Map<String, dynamic>? ?? {};
    final critical = _profile!['critical'] as Map<String, dynamic>? ?? {};

    // Calculate age from DOB
    int? age;
    if (critical['dob'] != null) {
      try {
        final dobStr = critical['dob'].toString();
        // Format: "05/10/1997"
        final parts = dobStr.split('/');
        if (parts.length == 3) {
          final dob = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          age = calculateAge(dob);
        }
      } catch (_) {}
    }

    final heartsId = miscellaneous['heartsId']?.toString() ?? '';
    final profileId = heartsId.isNotEmpty ? 'HEARTS-$heartsId' : '';

    // Get profile images
    final profilePics = miscellaneous['profilePic'] as List<dynamic>? ?? [];
    final clientId = miscellaneous['clientID'] ?? widget.profileId;
    final gender = miscellaneous['gender']?.toString();
    String? currentImage;

    if (profilePics.isNotEmpty && _currentImageIndex < profilePics.length) {
      final pic = profilePics[_currentImageIndex] as Map<String, dynamic>;
      final picId = pic['id']?.toString();
      if (picId != null && clientId != null) {
        currentImage = ApiConfig.buildImageUrl(clientId.toString(), picId);
      }
    }

    if (currentImage == null && profilePics.isNotEmpty) {
      final firstPic = profilePics[0] as Map<String, dynamic>;
      final picId = firstPic['id']?.toString();
      if (picId != null && clientId != null) {
        currentImage = ApiConfig.buildImageUrl(clientId.toString(), picId);
      }
    }

    // Use gender-based placeholder if no image
    final placeholderImage = getGenderPlaceholder(gender);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
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
                            child: Image.asset(
                              placeholderImage,
                              fit: BoxFit.cover,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: theme.dividerColor,
                            child: Image.asset(
                              placeholderImage,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : Container(
                          color: theme.dividerColor,
                          child: Image.asset(
                            placeholderImage,
                            fit: BoxFit.cover,
                          ),
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
                            age != null
                                ? '$profileId, $age years'
                                : (profileId.isNotEmpty
                                    ? profileId
                                    : 'Unknown'),
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
                isScrollable: true,
                onTap: (index) {
                  // Scroll to section when tab is clicked
                  _scrollToSection(index);
                },
                tabs: const [
                  Tab(text: 'About'),
                  Tab(text: 'Career'),
                  Tab(text: 'Education'),
                  Tab(text: 'Family'),
                  Tab(text: 'Horoscope'),
                  Tab(text: 'Looking For'),
                ],
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
              ),
              theme.cardColor,
            ),
          ),
          // Tab Content - Single scrollable list with sections
          SliverList(
            delegate: SliverChildListDelegate([
              _buildSection(key: _sectionKeys[0]!, child: _buildAboutTab()),
              _buildSection(key: _sectionKeys[1]!, child: _buildCareerTab()),
              _buildSection(key: _sectionKeys[2]!, child: _buildEducationTab()),
              _buildSection(key: _sectionKeys[3]!, child: _buildFamilyTab()),
              _buildSection(key: _sectionKeys[4]!, child: _buildHoroscopeTab()),
              _buildSection(
                  key: _sectionKeys[5]!, child: _buildLookingForTab()),
            ]),
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: _hasSentInterest ? Icons.favorite : Icons.favorite_border,
                label: 'Interest',
                color: _hasSentInterest ? AppColors.primary : Colors.grey,
                onTap: _handleSendInterest,
              ),
              _buildActionButton(
                icon: Icons.star,
                label: 'Super Interest',
                color: Colors.amber,
                onTap: _handleSuperInterest,
              ),
              _buildActionButton(
                icon: _isShortlisted ? Icons.bookmark : Icons.bookmark_border,
                label: 'Shortlist',
                color: _isShortlisted ? AppColors.primary : Colors.grey,
                onTap: _handleShortlist,
              ),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                color: Colors.grey,
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

  Widget _buildAboutTab() {
    final basic = _profile!['basic'] as Map<String, dynamic>? ?? {};
    final critical = _profile!['critical'] as Map<String, dynamic>? ?? {};
    final about = _profile!['about'] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoGrid([
            {'label': 'Height', 'value': basic['height']?.toString() ?? ''},
            {
              'label': 'Location',
              'value':
                  '${basic['city'] ?? ''}, ${basic['state'] ?? ''}, ${basic['country'] ?? ''}'
                      .replaceAll(RegExp(r'^,\s*|,\s*$'), '')
                      .replaceAll(RegExp(r',\s*,+'), ', ')
            },
            {'label': 'Caste', 'value': basic['cast']?.toString() ?? ''},
            {
              'label': 'Marital Status',
              'value': critical['maritalStatus']?.toString() ?? ''
            },
            {
              'label': 'Body Type',
              'value': about['bodyType']?.toString() ?? ''
            },
            {'label': 'Religion', 'value': basic['religion']?.toString() ?? ''},
            {
              'label': 'Mother Tongue',
              'value': basic['motherTongue']?.toString() ?? ''
            },
            {
              'label': 'Residential Status',
              'value': basic['residentialStatus']?.toString() ?? ''
            },
            {
              'label': 'Thalassemia',
              'value': about['thalassemia']?.toString() ?? ''
            },
            {
              'label': 'HIV Positive',
              'value': about['hivPositive']?.toString() ?? ''
            },
            {
              'label': 'Disability',
              'value': about['disability']?.toString() ?? ''
            },
          ]),
          const SizedBox(height: 24),
          if (about['description'] != null &&
              about['description'].toString().isNotEmpty) ...[
            _buildContentSection('About Me', about['description'].toString()),
            const SizedBox(height: 24),
          ],
          if (about['managedBy'] != null) ...[
            _buildInfoGrid([
              {
                'label': 'Managed By',
                'value': about['managedBy']?.toString() ?? ''
              },
            ]),
            const SizedBox(height: 24),
          ],
          // Lifestyle Data Section
          if (_profile!['lifeStyleData'] != null) ...[
            _buildLifestyleSection(
                _profile!['lifeStyleData'] as Map<String, dynamic>),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildCareerTab() {
    final career = _profile!['career'] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Heading
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Career',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
          ),
          _buildInfoGrid([
            {
              'label': 'Occupation',
              'value': career['occupation']?.toString() ?? ''
            },
            {
              'label': 'Employed In',
              'value': career['employed_in']?.toString() ?? ''
            },
            {
              'label': 'Organisation',
              'value': career['organisationName']?.toString() ?? ''
            },
            {'label': 'Income', 'value': career['income']?.toString() ?? ''},
            {
              'label': 'Interested in Settling Abroad',
              'value': career['interestedInSettlingAbroad']?.toString() == 'Y'
                  ? 'Yes'
                  : 'No'
            },
          ]),
          if (career['aboutMyCareer'] != null &&
              career['aboutMyCareer'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildContentSection(
                'About Career', career['aboutMyCareer'].toString()),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationTab() {
    final education = _profile!['education'] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Heading
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Education',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
          ),
          _buildInfoGrid([
            {
              'label': 'Qualification',
              'value': education['qualification']?.toString() ?? ''
            },
            {'label': 'School', 'value': education['school']?.toString() ?? ''},
            {
              'label': 'Other UG Degree',
              'value': education['otherUGDegree']?.toString() ?? ''
            },
          ]),
          if (education['aboutEducation'] != null &&
              education['aboutEducation'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildContentSection(
                'About Education', education['aboutEducation'].toString()),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildFamilyTab() {
    final family = _profile!['family'] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Heading
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Family',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
          ),
          _buildInfoGrid([
            {
              'label': 'Family Type',
              'value': family['familyType']?.toString() ?? ''
            },
            {
              'label': 'Family Status',
              'value': family['familyStatus']?.toString() ?? ''
            },
            {
              'label': 'Family Values',
              'value': family['familyValues']?.toString() ?? ''
            },
            {
              'label': 'Family Income',
              'value': family['familyIncome']?.toString() ?? ''
            },
            {
              'label': 'Father Occupation',
              'value': family['fatherOccupation']?.toString() ?? ''
            },
            {
              'label': 'Mother Occupation',
              'value': family['motherOccupation']?.toString() ?? ''
            },
            {
              'label': 'Brothers',
              'value': family['brothers'] != null
                  ? '${family['brothers']} (${family['marriedBrothers'] ?? 0} Married)'
                  : ''
            },
            {
              'label': 'Sisters',
              'value': family['sisters'] != null
                  ? '${family['sisters']} (${family['marriedSisters'] ?? 0} Married)'
                  : ''
            },
            {'label': 'Gothra', 'value': family['gothra']?.toString() ?? ''},
            {
              'label': 'Living with Parents',
              'value': family['livingWithParents']?.toString() ?? ''
            },
            {
              'label': 'Family Based Out Of',
              'value': family['familyBasedOutOf']?.toString() ?? ''
            },
          ]),
          if (family['aboutMyFamily'] != null &&
              family['aboutMyFamily'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildContentSection(
                'About Family', family['aboutMyFamily'].toString()),
          ],
        ],
      ),
    );
  }

  Widget _buildHoroscopeTab() {
    final kundali = _profile!['kundali'] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Heading
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Horoscope',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
          ),
          _buildInfoGrid([
            {
              'label': 'Horoscope',
              'value': kundali['horoscope']?.toString() ?? ''
            },
            {'label': 'Rashi', 'value': kundali['rashi']?.toString() ?? ''},
            {
              'label': 'Nakshatra',
              'value': kundali['nakshatra']?.toString() ?? ''
            },
            {'label': 'Manglik', 'value': kundali['manglik']?.toString() ?? ''},
            {
              'label': 'Time of Birth',
              'value': kundali['tob']?.toString() ?? ''
            },
            {
              'label': 'Place of Birth',
              'value': _buildKundaliLocation(kundali)
            },
          ]),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  String? _buildKundaliLocation(Map<String, dynamic> kundali) {
    final city = kundali['city']?.toString();
    final state = kundali['state']?.toString();
    final country = kundali['country']?.toString();
    return [city, state, country]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');
  }

  Widget _buildLookingForTab() {
    final matchData = _profile!['matchData'] as List<dynamic>? ?? [];
    final matchPercentage = _profile!['matchPercentage']?.toString() ?? '0';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Heading
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Looking For',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
          ),
          if (matchPercentage.isNotEmpty && matchPercentage != '0') ...[
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
          ],
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
                          match['label']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          match['value']?.toString() ?? '',
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
        ],
      ),
    );
  }

  String? _getLabelOrValue(String lookupKey, dynamic value) {
    if (value == null) return null;
    final lookupProvider = Provider.of<LookupProvider>(context, listen: false);
    return lookupProvider.getLabelFromValue(lookupKey, value) ??
        value.toString();
  }

  String? _buildLocation(
      Map<String, dynamic> data, LookupProvider lookupProvider) {
    final city = _getLabelOrValue('city', data['city']);
    final state = _getLabelOrValue('state', data['state']);
    final countryValue = data['country'];
    final country = countryValue != null
        ? lookupProvider.getCountryLabel(countryValue)
        : null;
    return [city, state, country]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');
  }

  Widget _buildLifestyleSection(Map<String, dynamic> lifestyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Lifestyle & Interests'),
        const SizedBox(height: 16),
        // Habits Row (horizontal, max 3)
        if (lifestyle['dietaryHabits'] != null ||
            lifestyle['drinkingHabits'] != null ||
            lifestyle['smokingHabits'] != null)
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (lifestyle['dietaryHabits'] != null)
                  _buildHabitCard(
                    Icons.restaurant,
                    'Dietary Habits',
                    lifestyle['dietaryHabits'].toString(),
                  ),
                if (lifestyle['drinkingHabits'] != null)
                  _buildHabitCard(
                    Icons.local_bar,
                    'Drinking',
                    lifestyle['drinkingHabits'].toString(),
                  ),
                if (lifestyle['smokingHabits'] != null)
                  _buildHabitCard(
                    Icons.smoking_rooms,
                    'Smoking',
                    lifestyle['smokingHabits'].toString(),
                  ),
              ].take(3).toList(),
            ),
          ),
        const SizedBox(height: 16),
        // Other lifestyle fields
        _buildInfoGrid([
          if (lifestyle['hobbies'] != null)
            {
              'label': 'Hobbies',
              'value': lifestyle['hobbies']?.toString() ?? ''
            },
          if (lifestyle['interest'] != null)
            {
              'label': 'Interests',
              'value': lifestyle['interest']?.toString() ?? ''
            },
          if (lifestyle['languages'] != null)
            {
              'label': 'Languages',
              'value': lifestyle['languages']?.toString() ?? ''
            },
          if (lifestyle['sports'] != null)
            {'label': 'Sports', 'value': lifestyle['sports']?.toString() ?? ''},
          if (lifestyle['cuisine'] != null)
            {
              'label': 'Favourite Cuisine',
              'value': lifestyle['cuisine']?.toString() ?? ''
            },
          if (lifestyle['movies'] != null)
            {
              'label': 'Favourite Movies',
              'value': lifestyle['movies']?.toString() ?? ''
            },
          if (lifestyle['favTVShow'] != null)
            {
              'label': 'Favourite TV Show',
              'value': lifestyle['favTVShow']?.toString() ?? ''
            },
          if (lifestyle['favRead'] != null)
            {
              'label': 'Favourite Read',
              'value': lifestyle['favRead']?.toString() ?? ''
            },
          if (lifestyle['books'] != null)
            {
              'label': 'Favourite Books',
              'value': lifestyle['books']?.toString() ?? ''
            },
          if (lifestyle['favMusic'] != null)
            {
              'label': 'Favourite Music',
              'value': lifestyle['favMusic']?.toString() ?? ''
            },
          if (lifestyle['dress'] != null)
            {
              'label': 'Dress Style',
              'value': lifestyle['dress']?.toString() ?? ''
            },
          if (lifestyle['vacayDestination'] != null)
            {
              'label': 'Vacation Destination',
              'value': lifestyle['vacayDestination']?.toString() ?? ''
            },
          if (lifestyle['foodICook'] != null)
            {
              'label': 'Food I Cook',
              'value':
                  lifestyle['foodICook']?.toString() == 'yes' ? 'Yes' : 'No'
            },
          if (lifestyle['openToPets'] != null)
            {
              'label': 'Open to Pets',
              'value': lifestyle['openToPets']?.toString() ?? ''
            },
          if (lifestyle['ownAHouse'] != null)
            {
              'label': 'Owns a House',
              'value': lifestyle['ownAHouse']?.toString() ?? ''
            },
          if (lifestyle['ownACar'] != null)
            {
              'label': 'Owns a Car',
              'value': lifestyle['ownACar']?.toString() ?? ''
            },
        ]),
      ],
    );
  }

  Widget _buildHabitCard(IconData icon, String label, String value) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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

  Widget _buildContentSection(String title, String content) {
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
    final validItems = items.where((item) {
      final value = item['value'];
      return value != null && value.isNotEmpty && value != 'null';
    }).toList();

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
