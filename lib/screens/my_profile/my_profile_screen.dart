import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../services/profile_service.dart';
import '../../config/api_config.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);
      final response = await _profileService.getMyProfileData();
      if (response.success && response.data != null) {
        setState(() {
          _profileData = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getAvatarUrl() {
    if (_profileData == null) return '';
    final misc = _profileData!['miscellaneous'] ?? {};
    final clientId = misc['clientID'] ?? misc['heartsId']?.toString() ?? '';
    final profilePics = misc['profilePic'] as List<dynamic>? ?? [];
    if (profilePics.isNotEmpty && clientId.isNotEmpty) {
      final pic = profilePics.first;
      final picId = pic['id']?.toString() ?? '';
      if (picId.isNotEmpty) {
        return ApiConfig.buildImageUrl(clientId, picId);
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: AppColors.error)),
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

    final basic = _profileData?['basic'] ?? {};
    final critical = _profileData?['critical'] ?? {};
    final about = _profileData?['about'] ?? {};
    final education = _profileData?['education'] ?? {};
    final career = _profileData?['career'] ?? {};
    final family = _profileData?['family'] ?? {};
    final contact = _profileData?['contact'] ?? {};
    final horoscope = _profileData?['horoscope'] ?? {};
    final lifestyle = _profileData?['lifeStyleData'] ?? {};
    final misc = _profileData?['miscellaneous'] ?? {};
    final enriched = _profileData?['enriched'] ?? {};

    final profileId = misc['heartsId'] != null 
        ? 'HEARTS-${misc['heartsId']}' 
        : 'N/A';
    final avatarUrl = _getAvatarUrl();

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Picture Section
              _buildSection(
                theme,
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: avatarUrl.isNotEmpty
                              ? CachedNetworkImageProvider(avatarUrl)
                              : null,
                          child: avatarUrl.isEmpty
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
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
                            profileId,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (basic['name'] != null)
                            Text(
                              basic['name'],
                              style: theme.textTheme.titleMedium,
                            ),
                          Text(
                            [
                              enriched['cityLabel'],
                              enriched['stateLabel'],
                              enriched['countryLabel'],
                            ].where((s) => s != null).join(', '),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Profile Details
              _buildEditableSection(
                theme,
                title: 'Profile Details',
                onEdit: () => Navigator.pushNamed(context, '/edit-profile-basic'),
                children: [
                  _buildDetailRow('Name', basic['name']),
                  _buildDetailRow('Gender', authProvider.user?.name),
                  _buildDetailRow('Religion', enriched['religionLabel']),
                  _buildDetailRow('Mother Tongue', enriched['motherTongueLabel']),
                  _buildDetailRow('Country', enriched['countryLabel']),
                  _buildDetailRow('State', enriched['stateLabel']),
                  _buildDetailRow('City', enriched['cityLabel']),
                  _buildDetailRow('Caste', enriched['castLabel']),
                  _buildDetailRow('Height', _formatHeight(basic['height'])),
                ],
              ),
              const SizedBox(height: 16),
              // Critical Fields
              _buildCriticalSection(
                theme,
                children: [
                  _buildDetailRow('Date of Birth', _formatDate(critical['dob'])),
                  _buildDetailRow('Marital Status', enriched['maritalStatusLabel']),
                ],
              ),
              const SizedBox(height: 16),
              // About Me
              _buildEditableSection(
                theme,
                title: 'About Me',
                onEdit: () => Navigator.pushNamed(context, '/edit-about'),
                children: [
                  _buildDetailRow('About Yourself', about['description'] ?? about['aboutYourself']),
                  _buildDetailRow('Profile Managed By', enriched['managedByLabel']),
                  _buildDetailRow('Body Type', enriched['bodyTypeLabel']),
                  _buildDetailRow('Disability', enriched['disabilityLabel']),
                ],
              ),
              const SizedBox(height: 16),
              // Education
              _buildEditableSection(
                theme,
                title: 'Education',
                onEdit: () => Navigator.pushNamed(context, '/edit-education'),
                children: [
                  _buildDetailRow('Qualification', enriched['qualificationLabel']),
                  _buildDetailRow('School', education['school']),
                  _buildDetailRow('About Education', education['aboutEducation']),
                ],
              ),
              const SizedBox(height: 16),
              // Career
              _buildEditableSection(
                theme,
                title: 'Career',
                onEdit: () => Navigator.pushNamed(context, '/edit-career'),
                children: [
                  _buildDetailRow('Employed In', enriched['employedInLabel']),
                  _buildDetailRow('Occupation', enriched['occupationLabel']),
                  _buildDetailRow('Organisation', career['organisationName']),
                  _buildDetailRow('About Career', career['aboutMyCareer']),
                ],
              ),
              const SizedBox(height: 16),
              // Family
              _buildEditableSection(
                theme,
                title: 'Family',
                onEdit: () => Navigator.pushNamed(context, '/edit-family'),
                children: [
                  _buildDetailRow('Family Status', family['familyStatus']),
                  _buildDetailRow('Family Type', family['familyType']),
                  _buildDetailRow('Family Values', family['familyValues']),
                  _buildDetailRow('Father Occupation', enriched['fatherOccupationLabel']),
                  _buildDetailRow('Mother Occupation', enriched['motherOccupationLabel']),
                  _buildDetailRow('Brothers', family['brothers']?.toString()),
                  _buildDetailRow('Sisters', family['sisters']?.toString()),
                  _buildDetailRow('Gothra', family['gothra']),
                ],
              ),
              const SizedBox(height: 16),
              // Contact
              _buildEditableSection(
                theme,
                title: 'Contact Details',
                onEdit: () => Navigator.pushNamed(context, '/edit-contact'),
                children: [
                  _buildDetailRow('Mobile', contact['phoneNumber']),
                  _buildDetailRow('Email', contact['email']),
                  _buildDetailRow('Alternate Mobile', contact['altMobileNumber']),
                  _buildDetailRow('Alternate Email', contact['alternateEmail']),
                ],
              ),
              const SizedBox(height: 16),
              // Horoscope
              _buildEditableSection(
                theme,
                title: 'Horoscope',
                onEdit: () => Navigator.pushNamed(context, '/edit-horoscope'),
                children: [
                  _buildDetailRow('Rashi', enriched['rashiLabel']),
                  _buildDetailRow('Nakshatra', enriched['nakshatraLabel']),
                  _buildDetailRow('Manglik', enriched['manglikLabel']),
                  _buildDetailRow('Place of Birth', horoscope['placeOfBirth']),
                  _buildDetailRow('Time of Birth', horoscope['timeOfBirth']),
                ],
              ),
              const SizedBox(height: 16),
              // Lifestyle
              _buildEditableSection(
                theme,
                title: 'Lifestyle',
                onEdit: () => Navigator.pushNamed(context, '/edit-lifestyle'),
                children: [
                  _buildDetailRow('Dietary Habits', enriched['dietaryHabitsLabel']),
                  _buildDetailRow('Drinking Habits', enriched['drinkingHabitsLabel']),
                  _buildDetailRow('Smoking Habits', enriched['smokingHabitsLabel']),
                  _buildDetailRow('Own a House', _formatYesNo(lifestyle['ownAHouse'])),
                  _buildDetailRow('Own a Car', _formatYesNo(lifestyle['ownACar'])),
                  _buildDetailRow('Open to Pets', _formatYesNo(lifestyle['openToPets'])),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
      ),
      child: child,
    );
  }

  Widget _buildEditableSection(
    ThemeData theme, {
    required String title,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCriticalSection(
    ThemeData theme, {
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.yellow.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Critical Field',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    final displayValue = value?.isNotEmpty == true ? value! : 'Not Filled';
    final isNotFilled = displayValue == 'Not Filled';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                color: isNotFilled ? AppColors.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHeight(dynamic height) {
    if (height == null) return '';
    final inches = int.tryParse(height.toString()) ?? 0;
    if (inches == 0) return '';
    final feet = inches ~/ 12;
    final remainingInches = inches % 12;
    return "$feet'$remainingInches\"";
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  String _formatYesNo(String? value) {
    if (value == null) return '';
    final map = {'y': 'Yes', 'n': 'No', 'yes0': 'Yes', 'no1': 'No'};
    return map[value.toLowerCase()] ?? value;
  }
}

