import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../services/profile_service.dart';
import '../../widgets/common/confirm_modal.dart';
import '../../utils/profile_utils.dart';

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

  // Transform API response to display format (matching webapp transformProfileDetailV1)
  Map<String, dynamic> _transformProfileData(Map<String, dynamic> apiData) {
    final misc = apiData['miscellaneous'] as Map<String, dynamic>? ?? {};
    final basic = apiData['basic'] as Map<String, dynamic>? ?? {};
    final critical = apiData['critical'] as Map<String, dynamic>? ?? {};
    final about = apiData['about'] as Map<String, dynamic>? ?? {};
    final education = apiData['education'] as Map<String, dynamic>? ?? {};
    final career = apiData['career'] as Map<String, dynamic>? ?? {};
    final family = apiData['family'] as Map<String, dynamic>?;
    final contact = apiData['contact'] as Map<String, dynamic>?;
    final kundali = apiData['kundali'] as Map<String, dynamic>?;
    final lifestyle = apiData['lifeStyleData'] as Map<String, dynamic>?;

    final clientID = misc['clientID'] as String? ?? widget.profileId;
    final heartsId = misc['heartsId'] ?? '';
    final profilePic = misc['profilePic'] as List<dynamic>? ?? [];

    // Build profile pictures with correct URL format
    final allProfilePics = profilePic.map((pic) {
      final picId = pic['id'] ?? pic['_id'] ?? '';
      return {
        'id': picId,
        'url':
            'https://backendapp.connectingheart.co.in/api/profile/file/$clientID/$picId',
        'primary': pic['primary'] ?? false,
      };
    }).toList();

    final primaryPic = allProfilePics.firstWhere(
      (pic) => pic['primary'] == true,
      orElse: () => allProfilePics.isNotEmpty ? allProfilePics[0] : {},
    );

    // Calculate age from DOB (format: DD/MM/YYYY)
    int age = 0;
    if (critical['dob'] != null) {
      try {
        final dobStr = critical['dob'].toString();
        final parts = dobStr.split('/');
        if (parts.length == 3) {
          final year = int.parse(parts[2]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[0]);
          final birthDate = DateTime(year, month, day);
          final today = DateTime.now();
          age = today.year - birthDate.year;
          if (today.month < birthDate.month ||
              (today.month == birthDate.month && today.day < birthDate.day)) {
            age--;
          }
        }
      } catch (_) {}
    }

    // Format location
    final city = misc['city'] ?? basic['city'] ?? '';
    final state = misc['state'] ?? basic['state'] ?? '';
    final country = misc['country'] ?? basic['country'] ?? '';
    final locationParts = [city, state, country]
        .where((p) => p != null && p.toString().isNotEmpty)
        .toList();
    final location =
        locationParts.isNotEmpty ? locationParts.join(', ') : 'N/A';

    // Format family income
    String? familyIncome;
    if (family != null && family['familyIncome'] != null) {
      final income = family['familyIncome'];
      if (income is num) {
        familyIncome = 'Rs. $income Lakh';
      } else {
        familyIncome = income.toString();
      }
    }

    // Format time of birth
    String? timeOfBirth;
    if (kundali != null && kundali['tob'] != null) {
      try {
        final tob = kundali['tob'].toString();
        if (tob.contains('T')) {
          final parts = tob.split('T');
          final dateParts = parts[0].split('-');
          if (dateParts.length == 3) {
            final timePart = parts[1].split('.')[0];
            final timeOnly =
                timePart.length >= 5 ? timePart.substring(0, 5) : timePart;
            timeOfBirth =
                '${dateParts[2]}/${dateParts[1]}/${dateParts[0]} $timeOnly';
          }
        } else {
          timeOfBirth = tob;
        }
      } catch (_) {
        timeOfBirth = kundali['tob'].toString();
      }
    }

    // Format place of birth
    String? placeOfBirth;
    if (kundali != null) {
      final placeParts = [
        kundali['city'],
        kundali['state'],
        kundali['country'],
      ].where((p) => p != null && p.toString().isNotEmpty).toList();
      placeOfBirth = placeParts.isNotEmpty ? placeParts.join(', ') : null;
    }

    // Format Y/N to Yes/No
    String formatYesNo(dynamic value) {
      if (value == null) return '';
      final str = value.toString().trim().toUpperCase();
      if (str == 'Y' || str == 'YES') return 'Yes';
      if (str == 'N' || str == 'NO') return 'No';
      return value.toString();
    }

    // Convert to array helper
    List<String>? toArray(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String) {
        return value
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return null;
    }

    return {
      'id': clientID,
      'profileId': heartsId != '' ? 'HEARTS-$heartsId' : '',
      'name': contact?['name'] ?? 'HEARTS-$heartsId',
      'age': age,
      'height': basic['height'] ?? 'N/A',
      'location': location,
      'avatar': primaryPic['url'],
      'allProfilePics': allProfilePics,
      'verified': misc['isMembershipActive'] ?? false,
      'isShortlisted': misc['isShortlisted'] ?? false,
      'isIgnored': misc['isIgnored'] ?? false,
      'isUnlocked': misc['isUnlocked'] ?? false,
      'gender': misc['gender'],

      // Basic details
      'dateOfBirth': critical['dob'] ?? '',
      'maritalStatus': critical['maritalStatus'] ?? '',
      'caste': basic['cast'] ?? '',
      'motherTongue': basic['motherTongue'] ?? misc['motherTongue'] ?? '',
      'religion': basic['religion'] ?? misc['religion'] ?? '',
      'aboutMe': about['description'] ?? '',
      'profileManagedBy': about['managedBy'] ?? '',
      'bodyType': about['bodyType'] ?? '',
      'thalassemia': about['thalassemia'] ?? '',
      'hivPositive': about['hivPositive'] == 'N' || about['hivPositive'] == 'No'
          ? 'No'
          : (about['hivPositive'] ?? 'N/A'),
      'disability': about['disability'] ?? '',

      // Education
      'school': education['school'] ?? '',
      'qualification': education['qualification'] ?? '',
      'otherUGDegree': education['otherUGDegree'] ?? '',
      'aboutEducation': education['aboutEducation'] ?? '',

      // Career
      'aboutCareer': career['aboutMyCareer'] ?? '',
      'employedIn': career['employed_in'] ?? '',
      'occupation': career['occupation'] ?? '',
      'organisationName': career['organisationName'] ?? '',
      'interestedInSettlingAbroad':
          formatYesNo(career['interestedInSettlingAbroad']),
      'income': career['income'] ?? 'Not specified',

      // Family
      'familyDetails': family != null
          ? {
              'familyStatus': family['familyStatus'] ?? '',
              'familyType': family['familyType'] ?? '',
              'familyValues': family['familyValues'] ?? '',
              'familyIncome': familyIncome,
              'fatherOccupation': family['fatherOccupation'] ?? '',
              'motherOccupation': family['motherOccupation'] ?? '',
              'brothers': family['brothers'],
              'marriedBrothers': family['marriedBrothers'],
              'sisters': family['sisters'],
              'marriedSisters': family['marriedSisters'],
              'aboutMyFamily': family['aboutMyFamily'] ?? '',
              'familyBasedOutOf': family['familyBasedOutOf'] ?? '',
              'gothra': family['gothra'] ?? '',
              'livingWithParents': formatYesNo(family['livingWithParents']),
            }
          : null,

      // Kundali
      'kundaliDetails': kundali != null
          ? {
              'rashi': kundali['rashi'] ?? '',
              'nakshatra': kundali['nakshatra'] ?? '',
              'timeOfBirth': timeOfBirth,
              'manglik': kundali['manglik'] ?? '',
              'horoscope': kundali['horoscope'] ?? '',
              'city': kundali['city'] ?? '',
              'state': kundali['state'] ?? '',
              'country': kundali['country'] ?? '',
              'placeOfBirth': placeOfBirth,
            }
          : null,

      // Lifestyle
      'lifestyleData': lifestyle != null
          ? {
              'dietaryHabits': lifestyle['dietaryHabits'] ?? '',
              'drinkingHabits': lifestyle['drinkingHabits'] ?? '',
              'smokingHabits': lifestyle['smokingHabits'] ?? '',
              'languages': toArray(lifestyle['languages']),
              'hobbies': toArray(lifestyle['hobbies']),
              'interest': toArray(lifestyle['interest']),
              'sports': toArray(lifestyle['sports']),
              'cuisine': toArray(lifestyle['cuisine']),
              'movies': lifestyle['movies'] ?? '',
              'books': toArray(lifestyle['books']),
              'dress': toArray(lifestyle['dress']),
              'favRead': lifestyle['favRead'] ?? '',
              'favTVShow': lifestyle['favTVShow'] ?? '',
              'vacayDestination': lifestyle['vacayDestination'] ?? '',
              'openToPets': formatYesNo(lifestyle['openToPets']),
              'ownAHouse': formatYesNo(lifestyle['ownAHouse']),
              'ownACar': formatYesNo(lifestyle['ownACar']),
              'favMusic': toArray(lifestyle['favMusic']),
              'foodICook': formatYesNo(lifestyle['foodICook']),
            }
          : null,

      // Match details
      'matchDetails': {
        'matchPercentage': apiData['matchPercentage'],
        'matchData': apiData['matchData'] ?? [],
      },

      // Contact (if unlocked)
      'contactDetails': (misc['isUnlocked'] == true && contact != null)
          ? {
              'phoneNumber': contact['phoneNumber'] ?? '',
              'email': contact['email'] ?? '',
              'name': contact['name'] ?? '',
              'alternateEmail': contact['alternateEmail'] ?? '',
              'altMobileNumber': contact['altMobileNumber'] ?? '',
              'landline': contact['landline'] ?? '',
            }
          : null,
    };
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use getDetailView1 API as per webapp
      final response = await _profileService.getDetailView1(widget.profileId);

      // Handle response structure: { code, status, data: {...} }
      Map<String, dynamic>? apiData;
      if (response is Map<String, dynamic>) {
        if (response['code'] == 'CH200' &&
            response['status'] == 'success' &&
            response['data'] != null) {
          apiData = response['data'] as Map<String, dynamic>;
        } else {
          apiData = response;
        }
      }

      if (apiData == null) {
        throw Exception('Invalid response format');
      }

      // Transform to display format
      final transformed = _transformProfileData(apiData);

      setState(() {
        _profile = transformed;
        _isShortlisted = transformed['isShortlisted'] ?? false;
        _isIgnored = transformed['isIgnored'] ?? false;
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

    final name = _profile!['name'];
    final age = _profile!['age'] ?? '';
    final profileId = _profile!['profileId'] ?? '';
    final gender = _profile!['gender']?.toString();
    // Check if name is actually a real name (not just HEARTS ID fallback)
    // Name is set to 'HEARTS-{id}' as fallback in transform, so check if it matches profileId
    final hasRealName = name != null &&
        name.toString().isNotEmpty &&
        name.toString() != profileId &&
        !name.toString().startsWith('HEARTS-');
    final profilePics = _profile!['allProfilePics'] as List<dynamic>? ?? [];
    final currentImage =
        profilePics.isNotEmpty && _currentImageIndex < profilePics.length
            ? profilePics[_currentImageIndex]['url']
            : _profile!['avatar'];
    final placeholderImage = getGenderPlaceholder(gender);

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
                          placeholder: (_, __) => Image.asset(
                            placeholderImage,
                            fit: BoxFit.cover,
                          ),
                          errorWidget: (_, __, ___) => Image.asset(
                            placeholderImage,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          placeholderImage,
                          fit: BoxFit.cover,
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
                          // If name exists, show HEARTS ID on top
                          if (hasRealName && profileId.isNotEmpty)
                            Text(
                              profileId,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          // Show name + age OR HEARTS ID + age
                          Text(
                            hasRealName
                                ? '${name.toString()}, ${age.toString().isNotEmpty ? age : ''}'
                                : '${profileId.isNotEmpty ? profileId : ''}, ${age.toString().isNotEmpty ? age : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_profile!['profileManagedBy'] != null &&
                              _profile!['profileManagedBy']
                                  .toString()
                                  .isNotEmpty)
                            Text(
                              'Profile managed by ${_profile!['profileManagedBy'].toString()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Attributes Grid (matching webapp)
          _buildInfoGrid([
            {'label': 'Height', 'value': _profile!['height']?.toString()},
            {'label': 'Location', 'value': _profile!['location']?.toString()},
            if (_profile!['caste'] != null &&
                _profile!['caste'].toString().isNotEmpty)
              {'label': 'Caste', 'value': _profile!['caste']?.toString()},
            if (_profile!['income'] != null &&
                _profile!['income'].toString().isNotEmpty)
              {'label': 'Income', 'value': _profile!['income']?.toString()},
            if (_profile!['maritalStatus'] != null &&
                _profile!['maritalStatus'].toString().isNotEmpty)
              {
                'label': 'Marital Status',
                'value': _profile!['maritalStatus']?.toString()
              },
            if (_profile!['motherTongue'] != null &&
                _profile!['motherTongue'].toString().isNotEmpty)
              {
                'label': 'Mother Tongue',
                'value': _profile!['motherTongue']?.toString()
              },
            if (_profile!['religion'] != null &&
                _profile!['religion'].toString().isNotEmpty)
              {'label': 'Religion', 'value': _profile!['religion']?.toString()},
            if (_profile!['bodyType'] != null &&
                _profile!['bodyType'].toString().isNotEmpty)
              {
                'label': 'Body Type',
                'value': _profile!['bodyType']?.toString()
              },
            if (_profile!['disability'] != null &&
                _profile!['disability'].toString().isNotEmpty)
              {
                'label': 'Disability',
                'value': _profile!['disability']?.toString()
              },
            if (_profile!['thalassemia'] != null &&
                _profile!['thalassemia'].toString().isNotEmpty &&
                _profile!['thalassemia'] != 'N/A')
              {
                'label': 'Thalassemia',
                'value': _profile!['thalassemia']?.toString()
              },
            if (_profile!['hivPositive'] != null &&
                _profile!['hivPositive'].toString().isNotEmpty &&
                _profile!['hivPositive'] != 'N/A')
              {
                'label': 'HIV Positive',
                'value': _profile!['hivPositive']?.toString()
              },
          ]),

          // About Me
          if (_profile!['aboutMe'] != null &&
              _profile!['aboutMe'].toString().isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSection('About Me', _profile!['aboutMe'].toString()),
          ],

          // Career Section
          if ((_profile!['occupation'] != null &&
                  _profile!['occupation'].toString().isNotEmpty) ||
              (_profile!['employedIn'] != null &&
                  _profile!['employedIn'].toString().isNotEmpty) ||
              (_profile!['organisationName'] != null &&
                  _profile!['organisationName'].toString().isNotEmpty) ||
              (_profile!['aboutCareer'] != null &&
                  _profile!['aboutCareer'].toString().isNotEmpty) ||
              (_profile!['interestedInSettlingAbroad'] != null &&
                  _profile!['interestedInSettlingAbroad']
                      .toString()
                      .isNotEmpty)) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('Career'),
            _buildInfoGrid([
              if (_profile!['occupation'] != null &&
                  _profile!['occupation'].toString().isNotEmpty)
                {
                  'label': 'Occupation',
                  'value': _profile!['occupation']?.toString()
                },
              if (_profile!['employedIn'] != null &&
                  _profile!['employedIn'].toString().isNotEmpty)
                {
                  'label': 'Employed In',
                  'value': _profile!['employedIn']?.toString()
                },
              if (_profile!['organisationName'] != null &&
                  _profile!['organisationName'].toString().isNotEmpty)
                {
                  'label': 'Organisation',
                  'value': _profile!['organisationName']?.toString()
                },
              if (_profile!['interestedInSettlingAbroad'] != null &&
                  _profile!['interestedInSettlingAbroad'].toString().isNotEmpty)
                {
                  'label': 'Interested in Settling Abroad',
                  'value': _profile!['interestedInSettlingAbroad']?.toString()
                },
            ]),
            if (_profile!['aboutCareer'] != null &&
                _profile!['aboutCareer'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Career',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _profile!['aboutCareer'].toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Education Section
          if ((_profile!['qualification'] != null &&
                  _profile!['qualification'].toString().isNotEmpty) ||
              (_profile!['school'] != null &&
                  _profile!['school'].toString().isNotEmpty) ||
              (_profile!['otherUGDegree'] != null &&
                  _profile!['otherUGDegree'].toString().isNotEmpty) ||
              (_profile!['aboutEducation'] != null &&
                  _profile!['aboutEducation'].toString().isNotEmpty)) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('Education'),
            if (_profile!['qualification'] != null &&
                _profile!['qualification'].toString().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile!['qualification'].toString(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_profile!['otherUGDegree'] != null &&
                        _profile!['otherUGDegree'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _profile!['otherUGDegree'].toString(),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (_profile!['school'] != null &&
                        _profile!['school'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _profile!['school'].toString(),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (_profile!['aboutEducation'] != null &&
                _profile!['aboutEducation'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Education',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _profile!['aboutEducation'].toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Critical Fields
          if ((_profile!['dateOfBirth'] != null &&
                  _profile!['dateOfBirth'].toString().isNotEmpty) ||
              (_profile!['caste'] != null &&
                  _profile!['caste'].toString().isNotEmpty)) ...[
            const SizedBox(height: 24),
            Text(
              'CRITICAL FIELDS',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            if (_profile!['dateOfBirth'] != null &&
                _profile!['dateOfBirth'].toString().isNotEmpty)
              _buildCriticalField(
                  'Date of Birth', _profile!['dateOfBirth'].toString()),
            if (_profile!['caste'] != null &&
                _profile!['caste'].toString().isNotEmpty)
              _buildCriticalField('Caste', _profile!['caste'].toString()),
          ],

          // Contact Details (if unlocked)
          if (_profile!['isUnlocked'] == true &&
              _profile!['contactDetails'] != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTACT INFORMATION',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_profile!['contactDetails']!['name'] != null &&
                      _profile!['contactDetails']!['name']
                          .toString()
                          .isNotEmpty)
                    _buildInfoRow(
                        label: 'Name',
                        value: _profile!['contactDetails']!['name'].toString()),
                  if (_profile!['contactDetails']!['phoneNumber'] != null &&
                      _profile!['contactDetails']!['phoneNumber']
                          .toString()
                          .isNotEmpty)
                    _buildInfoRow(
                        label: 'Phone Number',
                        value: _profile!['contactDetails']!['phoneNumber'].toString()),
                  if (_profile!['contactDetails']!['altMobileNumber'] != null &&
                      _profile!['contactDetails']!['altMobileNumber']
                          .toString()
                          .isNotEmpty)
                    _buildInfoRow(
                        label: 'Alternate Mobile',
                        value: _profile!['contactDetails']!['altMobileNumber']
                            .toString()),
                  if (_profile!['contactDetails']!['landline'] != null &&
                      _profile!['contactDetails']!['landline']
                          .toString()
                          .isNotEmpty)
                    _buildInfoRow(
                        label: 'Landline',
                        value: _profile!['contactDetails']!['landline'].toString()),
                  if (_profile!['contactDetails']!['email'] != null &&
                      _profile!['contactDetails']!['email']
                          .toString()
                          .isNotEmpty)
                    _buildInfoRow(
                        label: 'Email',
                        value: _profile!['contactDetails']!['email'].toString()),
                  if (_profile!['contactDetails']!['alternateEmail'] != null &&
                      _profile!['contactDetails']!['alternateEmail']
                          .toString()
                          .isNotEmpty)
                    _buildInfoRow(
                        label: 'Alternate Email',
                        value: _profile!['contactDetails']!['alternateEmail']
                            .toString()),
                ],
              ),
            ),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCriticalField(String label, String value) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyTab() {
    final family = _profile!['familyDetails'] as Map<String, dynamic>?;
    final theme = Theme.of(context);

    if (family == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No family details available'),
        ),
      );
    }

    // Build siblings info
    final siblingsInfo = <String>[];
    if (family['brothers'] != null) {
      final brothers = family['brothers'];
      final marriedBrothers = family['marriedBrothers'] ?? 0;
      siblingsInfo.add(
          '$brothers Brother${brothers != 1 ? 's' : ''} ($marriedBrothers Married)');
    }
    if (family['sisters'] != null) {
      final sisters = family['sisters'];
      final marriedSisters = family['marriedSisters'] ?? 0;
      siblingsInfo.add(
          '$sisters Sister${sisters != 1 ? 's' : ''} ($marriedSisters Married)');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Family'),
          const SizedBox(height: 16),

          // Family Type and Location (full width text block)
          if ((family['familyType'] != null &&
                  family['familyType'].toString().isNotEmpty) ||
              (family['familyBasedOutOf'] != null &&
                  family['familyBasedOutOf'].toString().isNotEmpty)) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (family['familyType'] != null &&
                      family['familyType'].toString().isNotEmpty)
                    Text(
                      '${family['familyType']}${family['familyBasedOutOf'] != null && family['familyBasedOutOf'].toString().isNotEmpty ? ' from ${family['familyBasedOutOf']}' : ''}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (family['familyValues'] != null &&
                      family['familyValues'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      family['familyValues'].toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  if (family['familyStatus'] != null &&
                      family['familyStatus'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      family['familyStatus'].toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  if (family['gothra'] != null &&
                      family['gothra'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${family['gothra']} Gotra',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Parents Occupation (full width text block)
          if ((family['fatherOccupation'] != null &&
                  family['fatherOccupation'].toString().isNotEmpty) ||
              (family['motherOccupation'] != null &&
                  family['motherOccupation'].toString().isNotEmpty)) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    family['fatherOccupation'] != null &&
                            family['fatherOccupation'].toString().isNotEmpty
                        ? (family['motherOccupation'] != null &&
                                family['motherOccupation'].toString().isNotEmpty
                            ? 'Father is ${family['fatherOccupation']} & Mother is ${family['motherOccupation']}'
                            : 'Father is ${family['fatherOccupation']}')
                        : 'Mother is ${family['motherOccupation']}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (siblingsInfo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      siblingsInfo.join(' & '),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  if (family['familyIncome'] != null &&
                      family['familyIncome'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Family Income: ${family['familyIncome']}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // About Family (text block with border)
          if (family['aboutMyFamily'] != null &&
              family['aboutMyFamily'].toString().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About their family',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    family['aboutMyFamily'].toString(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Living with Parents (full width text block)
          if (family['livingWithParents'] != null &&
              family['livingWithParents'].toString().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Living with Parents',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    family['livingWithParents'].toString(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildKundaliTab() {
    final kundali = _profile!['kundaliDetails'] as Map<String, dynamic>?;
    final lifestyle = _profile!['lifestyleData'] as Map<String, dynamic>?;
    final theme = Theme.of(context);

    // Debug: Check if kundali data exists
    print('🔍 Kundali Data: $kundali');
    print('🔍 Lifestyle Data: $lifestyle');

    // Check if kundali has any data - EXPLICIT checks for release mode
    bool hasKundaliData = false;
    if (kundali != null) {
      final rashi = kundali['rashi'];
      final nakshatra = kundali['nakshatra'];
      final timeOfBirth = kundali['timeOfBirth'];
      final placeOfBirth = kundali['placeOfBirth'];
      final manglik = kundali['manglik'];
      final horoscope = kundali['horoscope'];
      final city = kundali['city'];
      final state = kundali['state'];
      final country = kundali['country'];
      
      if ((rashi != null && rashi.toString().isNotEmpty) ||
          (nakshatra != null && nakshatra.toString().isNotEmpty) ||
          (timeOfBirth != null && timeOfBirth.toString().isNotEmpty) ||
          (placeOfBirth != null && placeOfBirth.toString().isNotEmpty) ||
          (manglik != null && manglik.toString().isNotEmpty) ||
          (horoscope != null && horoscope.toString().isNotEmpty) ||
          (city != null && city.toString().isNotEmpty) ||
          (state != null && state.toString().isNotEmpty) ||
          (country != null && country.toString().isNotEmpty)) {
        hasKundaliData = true;
      }
    }

    print('🔍 Has Kundali Data: $hasKundaliData');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show message if no kundali data
          if (!hasKundaliData) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No Kundali details available',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
          
          // Kundali & Astro Section
          if (hasKundaliData && kundali != null) ...[
            _buildSectionTitle('Kundali & Astro'),
            if (kundali['timeOfBirth'] != null && kundali['timeOfBirth'].toString().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time,
                        color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 12),
                    Text(
                      kundali['timeOfBirth'].toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (kundali['placeOfBirth'] != null && kundali['placeOfBirth'].toString().isNotEmpty)
              _buildInfoRow(
                  label: 'Place Of Birth',
                  value: kundali['placeOfBirth'].toString()),
            if (kundali['rashi'] != null && kundali['rashi'].toString().isNotEmpty)
              _buildInfoRow(
                  label: 'Rashi', value: kundali['rashi'].toString()),
            if (kundali['nakshatra'] != null && kundali['nakshatra'].toString().isNotEmpty)
              _buildInfoRow(
                  label: 'Nakshatra', value: kundali['nakshatra'].toString()),
            if (kundali['manglik'] != null && kundali['manglik'].toString().isNotEmpty)
              _buildInfoRow(
                  label: 'Manglik', value: kundali['manglik'].toString()),
            if (kundali['horoscope'] != null && kundali['horoscope'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Horoscope match is Must',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],

          // Lifestyle Section
          if (lifestyle != null && (
              (lifestyle['drinkingHabits']?.toString().isNotEmpty ?? false) ||
              (lifestyle['dietaryHabits']?.toString().isNotEmpty ?? false) ||
              (lifestyle['smokingHabits']?.toString().isNotEmpty ?? false)
          )) ...[
            _buildSectionTitle('Lifestyle and Interests'),
            const SizedBox(height: 8),
            Text(
              'Their Habits',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildHabitsRow(lifestyle),
            const SizedBox(height: 24),
          ],

          // Hobbies, Interests, Languages, Sports
          if (lifestyle != null) ...[
            if (lifestyle['hobbies'] != null &&
                (lifestyle['hobbies'] as List?)?.isNotEmpty == true) ...[
              Text(
                'Their hobbies are',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (lifestyle['hobbies'] as List).join(', '),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            if (lifestyle['interest'] != null &&
                (lifestyle['interest'] as List?)?.isNotEmpty == true) ...[
              Text(
                'Their interests are',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (lifestyle['interest'] as List).join(', '),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            if (lifestyle['languages'] != null &&
                (lifestyle['languages'] as List?)?.isNotEmpty == true) ...[
              Text(
                'They can speak',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (lifestyle['languages'] as List).join(', '),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            if (lifestyle['sports'] != null &&
                (lifestyle['sports'] as List?)?.isNotEmpty == true) ...[
              Text(
                'Sports they enjoy',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (lifestyle['sports'] as List).join(', '),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            if (lifestyle['cuisine'] != null &&
                (lifestyle['cuisine'] as List?)?.isNotEmpty == true) ...[
              Text(
                'Favourite Cuisine',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (lifestyle['cuisine'] as List).join(', '),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
          ],

          // Other Preferences
          if (lifestyle != null &&
              ((lifestyle['movies'] != null &&
                      lifestyle['movies'].toString().isNotEmpty) ||
                  (lifestyle['favTVShow'] != null &&
                      lifestyle['favTVShow'].toString().isNotEmpty) ||
                  (lifestyle['favRead'] != null &&
                      lifestyle['favRead'].toString().isNotEmpty) ||
                  (lifestyle['vacayDestination'] != null &&
                      lifestyle['vacayDestination'].toString().isNotEmpty) ||
                  (lifestyle['books'] != null &&
                      (lifestyle['books'] as List?)?.isNotEmpty == true) ||
                  (lifestyle['dress'] != null &&
                      (lifestyle['dress'] as List?)?.isNotEmpty == true) ||
                  (lifestyle['favMusic'] != null &&
                      (lifestyle['favMusic'] as List?)?.isNotEmpty == true) ||
                  (lifestyle['foodICook'] != null &&
                      lifestyle['foodICook'].toString().isNotEmpty) ||
                  (lifestyle['openToPets'] != null &&
                      lifestyle['openToPets'].toString().isNotEmpty) ||
                  (lifestyle['ownAHouse'] != null &&
                      lifestyle['ownAHouse'].toString().isNotEmpty) ||
                  (lifestyle['ownACar'] != null &&
                      lifestyle['ownACar'].toString().isNotEmpty))) ...[
            _buildSectionTitle('Other Preferences'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (lifestyle['movies'] != null &&
                    lifestyle['movies'].toString().isNotEmpty)
                  _buildPreferenceCard('Favourite Movies',
                      lifestyle['movies'].toString(), Icons.movie),
                if (lifestyle['favTVShow'] != null &&
                    lifestyle['favTVShow'].toString().isNotEmpty)
                  _buildPreferenceCard('Favourite TV Show',
                      lifestyle['favTVShow'].toString(), Icons.tv),
                if (lifestyle['favRead'] != null &&
                    lifestyle['favRead'].toString().isNotEmpty)
                  _buildPreferenceCard('Favourite Read',
                      lifestyle['favRead'].toString(), Icons.menu_book),
                if (lifestyle['vacayDestination'] != null &&
                    lifestyle['vacayDestination'].toString().isNotEmpty)
                  _buildPreferenceCard('Vacation Destination',
                      lifestyle['vacayDestination'].toString(), Icons.place),
              ],
            ),
            const SizedBox(height: 16),
            if (lifestyle['books'] != null &&
                (lifestyle['books'] as List?)?.isNotEmpty == true) ...[
              Text(
                'Favourite Books',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (lifestyle['books'] as List).map((book) {
                  return Chip(
                    label: Text(book.toString()),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    labelStyle: TextStyle(color: AppColors.primary),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (lifestyle['dress'] != null &&
                (lifestyle['dress'] as List?)?.isNotEmpty == true) ...[
              Text(
                'Dress Style',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (lifestyle['dress'] as List).map((style) {
                  return Chip(
                    label: Text(style.toString()),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    labelStyle: TextStyle(color: AppColors.primary),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (lifestyle['favMusic'] != null &&
                (lifestyle['favMusic'] as List?)?.isNotEmpty == true) ...[
              Text(
                'Favourite Music',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (lifestyle['favMusic'] as List).map((music) {
                  return Chip(
                    label: Text(music.toString()),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    labelStyle: TextStyle(color: AppColors.primary),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (lifestyle['foodICook'] != null &&
                    lifestyle['foodICook'].toString().isNotEmpty)
                  _buildSmallPreferenceCard('Food I Cook',
                      lifestyle['foodICook'].toString(), Icons.restaurant_menu),
                if (lifestyle['openToPets'] != null &&
                    lifestyle['openToPets'].toString().isNotEmpty)
                  _buildSmallPreferenceCard('Open to Pets',
                      lifestyle['openToPets'].toString(), Icons.pets),
                if (lifestyle['ownAHouse'] != null &&
                    lifestyle['ownAHouse'].toString().isNotEmpty)
                  _buildSmallPreferenceCard('Owns a House',
                      lifestyle['ownAHouse'].toString(), Icons.home),
                if (lifestyle['ownACar'] != null &&
                    lifestyle['ownACar'].toString().isNotEmpty)
                  _buildSmallPreferenceCard('Owns a Car',
                      lifestyle['ownACar'].toString(), Icons.directions_car),
              ],
            ),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPreferenceCard(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallPreferenceCard(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchTab() {
    final matchDetails = _profile!['matchDetails'] as Map<String, dynamic>?;
    final matchData = matchDetails?['matchData'] as List<dynamic>? ?? [];
    final matchPercentage = matchDetails?['matchPercentage'];
    final matchedCount = matchData.where((m) => m['isMatched'] == true).length;
    final totalCount = matchData.length;
    
    final theme = Theme.of(context);
    final gender = _profile!['gender']?.toString();
    final profileImage = _profile!['avatar'];
    final placeholderImage = getGenderPlaceholder(gender);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match Summary with Images (matching webapp)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                // Profile images row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Their preference
                    Column(
                      children: [
                        Text(
                          'Their Preference',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: profileImage != null
                                ? CachedNetworkImage(
                                    imageUrl: profileImage,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Image.asset(
                                      placeholderImage,
                                      fit: BoxFit.cover,
                                    ),
                                    errorWidget: (_, __, ___) => Image.asset(
                                      placeholderImage,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    placeholderImage,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Match percentage circle
                    Column(
                      children: [
                        if (matchPercentage != null)
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, Colors.pinkAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$matchPercentage%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Match',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'You match $matchedCount/$totalCount',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    
                    // You match
                    Column(
                      children: [
                        Text(
                          'You Match',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              placeholderImage,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Matched criteria list
          if (matchData.isNotEmpty) ...[
            Text(
              'Basic Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...matchData.map((match) {
              final isMatched = match['isMatched'] ?? false;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor,
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
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            match['value'] ?? '',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isMatched ? Icons.check_circle : Icons.cancel,
                      color: isMatched ? AppColors.success : Colors.grey,
                      size: 28,
                    ),
                  ],
                ),
              );
            }),
          ],
          
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

    return Column(
      children: validItems
          .map<Widget>((item) => _buildInfoRow(
                label: item['label']!,
                value: item['value']!,
              ))
          .toList(),
    );
  }

  // Simple row with icon (matching webapp design)
  Widget _buildInfoRow({required String label, required String value}) {
    final theme = Theme.of(context);
    final icon = _getIconForLabel(label);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(width: 12),
          // Label and value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Get appropriate icon for each label
  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'height':
        return Icons.height;
      case 'location':
        return Icons.location_on_outlined;
      case 'caste':
        return Icons.book_outlined;
      case 'income':
        return Icons.currency_rupee;
      case 'marital status':
        return Icons.favorite_border;
      case 'mother tongue':
        return Icons.language;
      case 'religion':
        return Icons.book_outlined;
      case 'body type':
        return Icons.person_outline;
      case 'disability':
        return Icons.accessible;
      case 'thalassemia':
        return Icons.medical_services_outlined;
      case 'hiv positive':
        return Icons.warning_amber_outlined;
      case 'occupation':
        return Icons.work_outline;
      case 'employed in':
        return Icons.business_outlined;
      case 'organisation':
      case 'organisation name':
        return Icons.business_outlined;
      case 'interested in settling abroad':
        return Icons.flight_outlined;
      case 'qualification':
        return Icons.school_outlined;
      case 'school':
        return Icons.school_outlined;
      default:
        return Icons.info_outline;
    }
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
