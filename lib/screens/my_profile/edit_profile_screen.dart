import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../services/profile_service.dart';
import '../../providers/lookup_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
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
      // Load lookup data first
      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);
      await lookupProvider.loadLookupData();

      // Get profile data from new endpoint
      final response = await _profileService.getUserProfileData();
      if (response['status'] == 'success' && response['data'] != null) {
        setState(() {
          _profileData = response['data'] as Map<String, dynamic>;
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

  int _getPhotoCount() {
    if (_profileData == null) return 0;
    final misc = _profileData!['miscellaneous'] ?? {};
    final profilePics = misc['profilePic'] as List<dynamic>? ?? [];
    return profilePics.length;
  }

  int _calculateProfileCompletion() {
    if (_profileData == null) return 0;
    int filledFields = 0;
    int totalFields = 0;

    // Basic fields
    final basic = _profileData!['basic'] ?? {};
    totalFields += 8;
    if (basic['name'] != null && basic['name'].toString().isNotEmpty)
      filledFields++;
    if (basic['height'] != null) filledFields++;
    if (basic['income'] != null) filledFields++;
    // Add more basic field checks...

    // Critical fields
    final critical = _profileData!['critical'] ?? {};
    totalFields += 2;
    if (critical['dob'] != null && critical['dob'].toString().isNotEmpty)
      filledFields++;
    if (critical['maritalStatus'] != null &&
        critical['maritalStatus'].toString().isNotEmpty) filledFields++;

    // About fields
    final about = _profileData!['about'] ?? {};
    totalFields += 3;
    if (about['description'] != null &&
        about['description'].toString().isNotEmpty) filledFields++;
    if (about['aboutYourself'] != null &&
        about['aboutYourself'].toString().isNotEmpty) filledFields++;
    if (about['bodyType'] != null) filledFields++;

    // Family fields
    final family = _profileData!['family'] ?? {};
    totalFields += 5;
    if (family['aboutMyFamily'] != null &&
        family['aboutMyFamily'].toString().isNotEmpty) filledFields++;
    if (family['familyStatus'] != null) filledFields++;
    if (family['familyIncome'] != null) filledFields++;
    if (family['fatherOccupation'] != null) filledFields++;
    if (family['motherOccupation'] != null) filledFields++;

    // Contact fields
    final contact = _profileData!['contact'] ?? {};
    totalFields += 2;
    if (contact['phoneNumber'] != null &&
        contact['phoneNumber'].toString().isNotEmpty) filledFields++;
    if (contact['email'] != null && contact['email'].toString().isNotEmpty)
      filledFields++;

    // Horoscope fields
    final horoscope = _profileData!['horoscope'] ?? {};
    totalFields += 2;
    if (horoscope['rashi'] != null) filledFields++;
    if (horoscope['manglikStatus'] != null) filledFields++;

    // Lifestyle fields
    final lifestyle = _profileData!['lifeStyleData'] ?? {};
    totalFields += 3;
    if (lifestyle['dietaryHabits'] != null) filledFields++;
    if (lifestyle['smokingHabits'] != null) filledFields++;
    if (lifestyle['drinkingHabits'] != null) filledFields++;

    if (totalFields == 0) return 0;
    return ((filledFields / totalFields) * 100).round();
  }

  String _formatHeight(dynamic height) {
    if (height == null) return '';
    final inches = int.tryParse(height.toString()) ?? 0;
    if (inches == 0) return '';
    final feet = inches ~/ 12;
    final remainingInches = inches % 12;
    return "$feet' $remainingInches\"";
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  String _formatIncome(dynamic income) {
    if (income == null) return '';
    final incomeMap = {
      1: 'Rs. 0 - 1 Lakh',
      2: 'Rs. 1 - 2 Lakh',
      3: 'Rs. 2 - 3 Lakh',
      4: 'Rs. 3 - 4 Lakh',
      5: 'Rs. 4 - 5 Lakh',
      6: 'Rs. 5 - 7 Lakh',
      7: 'Rs. 7 - 10 Lakh',
      8: 'Rs. 10 - 15 Lakh',
      9: 'Rs. 15 - 20 Lakh',
      10: 'Rs. 20 - 30 Lakh',
      11: 'Rs. 30 - 50 Lakh',
      12: 'Rs. 50+ Lakh',
    };
    return incomeMap[income] ?? '';
  }

  String _formatYesNo(dynamic value) {
    if (value == null) return '';
    final map = {'y': 'Yes', 'n': 'No', 'yes0': 'Yes', 'no1': 'No'};
    return map[value.toString().toLowerCase()] ?? value.toString();
  }

  // Helper methods to get labels from lookup
  String _getLabel(BuildContext context, String lookupKey, dynamic value) {
    if (value == null) return 'Not Filled';
    final lookupProvider = Provider.of<LookupProvider>(context, listen: false);
    final label = lookupProvider.getLabelFromValue(lookupKey, value);
    return label ?? 'Not Filled';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(context, ''),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: _buildAppBar(context, ''),
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
    final family = _profileData?['family'] ?? {};
    final contact = _profileData?['contact'] ?? {};
    final horoscope = _profileData?['horoscope'] ?? {};
    final lifestyle = _profileData?['lifeStyleData'] ?? {};
    final misc = _profileData?['miscellaneous'] ?? {};

    final profileId =
        misc['heartsId'] != null ? 'UWSS${misc['heartsId']}' : 'N/A';
    final photoCount = _getPhotoCount();
    final completionPercentage = _calculateProfileCompletion();

    return Scaffold(
      appBar: _buildAppBar(context, profileId),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        child: ClipOval(
                          child: Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      if (photoCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                photoCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement photo upload
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC4899),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add photos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Profile with photo gives 10 times better response',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Add quality photos, your photos are safe with us',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Verification Card
            _buildVerificationCard(),
            const SizedBox(height: 16),
            // Profile Completion Card
            _buildProfileCompletionCard(completionPercentage),
            const SizedBox(height: 16),
            // Personal Details Card
            _buildPersonalDetailsCard(context, basic, critical, misc),
            const SizedBox(height: 16),
            // About Me Card
            _buildAboutMeCard(about),
            const SizedBox(height: 16),
            // Family Card
            _buildFamilyCard(context, family, misc),
            const SizedBox(height: 16),
            // Contact Details Card
            _buildContactDetailsCard(contact),
            const SizedBox(height: 16),
            // Horoscope Card
            _buildHoroscopeCard(context, horoscope, critical, misc),
            const SizedBox(height: 16),
            // Lifestyle Card
            _buildLifestyleCard(context, lifestyle),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String profileId) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => context.pop(),
      ),
      title: Text(
        profileId,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.camera_alt_outlined, color: Colors.black),
          onPressed: () {
            // TODO: Implement camera action
          },
        ),
        IconButton(
          icon: const Icon(Icons.visibility_outlined, color: Colors.black),
          onPressed: () {
            // TODO: Implement preview action
          },
        ),
      ],
    );
  }

  Widget _buildVerificationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: const Color(0xFFEC4899), width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: const Text(
              'Verify your profile using selfie to assure others you are genuine and get a badge',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletionCard(int percentage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFFEC4899),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEC4899),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add a few more details to make your profile rich!',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // TODO: Navigate to complete profile
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Complete your profile',
                        style: TextStyle(
                          color: Color(0xFFEC4899),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        color: Color(0xFFEC4899),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsCard(
    BuildContext context,
    Map<String, dynamic> basic,
    Map<String, dynamic> critical,
    Map<String, dynamic> misc,
  ) {
    final religionLabel = _getLabel(context, 'religion', basic['religion']);
    final castLabel = _getLabel(context, 'casts', basic['cast']);
    final maritalStatusLabel =
        _getLabel(context, 'maritalStatus', critical['maritalStatus']);
    final motherTongueLabel =
        _getLabel(context, 'motherTongue', basic['motherTongue']);

    return _buildEditableCard(
      icon: Icons.person_outline,
      title: basic['name']?.toString() ?? 'Personal Details',
      onEdit: () {
        // TODO: Navigate to edit personal details
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
              '$religionLabel ${_formatHeight(basic['height'])}', null),
          _buildDetailRow(castLabel, null),
          _buildDetailRow(
            _getLabel(context, 'city', basic['city'] ?? misc['city']),
            null,
          ),
          _buildDetailRow(maritalStatusLabel, null),
          _buildDetailRow(_formatDate(critical['dob']), null),
          const SizedBox(height: 8),
          _buildDetailRow(_formatIncome(basic['income']), null),
          _buildDetailRow(
            '$motherTongueLabel - ${_getLabel(context, 'city', basic['city'] ?? misc['city'])}',
            null,
          ),
          _buildDetailRow(
            _getLabel(context, 'state', basic['state'] ?? misc['state']),
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMeCard(
    Map<String, dynamic> about,
  ) {
    return _buildEditableCard(
      icon: Icons.person_outline,
      title: 'About Me',
      onEdit: () {
        // TODO: Navigate to edit about me
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            about['description']?.toString() ??
                about['aboutYourself']?.toString() ??
                'Not Filled',
            style: TextStyle(
              color: (about['description'] == null &&
                      about['aboutYourself'] == null)
                  ? Colors.red
                  : Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyCard(
    BuildContext context,
    Map<String, dynamic> family,
    Map<String, dynamic> misc,
  ) {
    return _buildEditableCard(
      icon: Icons.people_outline,
      title: 'Family',
      onEdit: () {
        // TODO: Navigate to edit family
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            'About My Family',
            family['aboutMyFamily']?.toString() ??
                family['aboutFamily']?.toString() ??
                'Not Filled',
            isNotFilled: (family['aboutMyFamily'] == null &&
                family['aboutFamily'] == null),
          ),
          _buildDetailRow(
            'Family Background',
            _getLabel(context, 'familyStatus', family['familyStatus']),
          ),
          _buildDetailRow(
            'Family Income',
            _formatIncome(family['familyIncome']),
          ),
          _buildDetailRow(
            'Father is',
            _getLabel(context, 'occupation', family['fatherOccupation']),
          ),
          _buildDetailRow(
            'Mother is',
            _getLabel(context, 'occupation', family['motherOccupation']),
          ),
          _buildDetailRow(
            'Brother/Sister',
            _formatSiblings(family),
          ),
          _buildDetailRow(
            'Living With Parents?',
            _formatYesNo(family['livingWithParents']),
          ),
          _buildDetailRow(
            'Family based out of',
            _getLabel(context, 'country',
                family['familyBasedOutOf'] ?? misc['country']),
          ),
        ],
      ),
    );
  }

  Widget _buildContactDetailsCard(Map<String, dynamic> contact) {
    return _buildEditableCard(
      icon: Icons.phone_outlined,
      title: 'Contact Details',
      onEdit: () {
        // TODO: Navigate to edit contact
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailRow(
                  'Email ID',
                  contact['email']?.toString() ?? 'Not Filled',
                ),
              ),
              if (contact['email'] != null &&
                  contact['email'].toString().isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'VERIFIED',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          _buildDetailRow(
            'Alternate Email ID',
            contact['alternateEmail']?.toString() ??
                contact['alternateEmailId']?.toString() ??
                'Not Filled',
            isNotFilled: (contact['alternateEmail'] == null &&
                contact['alternateEmailId'] == null),
          ),
          Row(
            children: [
              Expanded(
                child: _buildDetailRow(
                  'Mobile no.',
                  contact['phoneNumber']?.toString() ?? 'Not Filled',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 20),
                onPressed: () {
                  // TODO: Implement mobile settings
                },
              ),
            ],
          ),
          _buildDetailRow(
            'Alt. Mobile no',
            contact['altMobileNumber']?.toString() ??
                contact['alternateMobileNo']?.toString() ??
                'Not Filled',
            isNotFilled: (contact['altMobileNumber'] == null &&
                contact['alternateMobileNo'] == null),
          ),
          _buildDetailRow(
            'Landline no.',
            contact['landline']?.toString() ?? 'Not Filled',
            isNotFilled: contact['landline'] == null,
          ),
        ],
      ),
    );
  }

  Widget _buildHoroscopeCard(
    BuildContext context,
    Map<String, dynamic> horoscope,
    Map<String, dynamic> critical,
    Map<String, dynamic> misc,
  ) {
    return _buildEditableCard(
      icon: Icons.grid_view,
      title: 'Horoscope',
      onEdit: () {
        // TODO: Navigate to edit horoscope
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            'City, Country of Birth',
            _getLabel(context, 'city', horoscope['cityOfBirth']),
            isNotFilled: horoscope['cityOfBirth'] == null,
          ),
          _buildDetailRow(
            'Date & Time of Birth',
            '${_formatDate(critical['dob'] ?? horoscope['dob'] ?? horoscope['dateOfBirth'])}, ${horoscope['timeOfBirth']?.toString() ?? 'Not Available'}',
          ),
          const SizedBox(height: 12),
          const Text(
            'More About Horoscope',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Rashi/Moon Sign?',
            _getLabel(context, 'rashi', horoscope['rashi']),
            isNotFilled: horoscope['rashi'] == null,
          ),
          _buildDetailRow(
            'Nakshatra?',
            _getLabel(context, 'nakshatra', horoscope['nakshatra']),
            isNotFilled: horoscope['nakshatra'] == null,
          ),
          _buildDetailRow(
            'Manglik Status',
            _getLabel(context, 'manglik', horoscope['manglik']),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5CC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.push_pin, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Horoscope match is must.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleCard(
    BuildContext context,
    Map<String, dynamic> lifestyle,
  ) {
    return _buildEditableCard(
      icon: Icons.restaurant_outlined,
      title: 'Lifestyle',
      onEdit: () {
        // TODO: Navigate to edit lifestyle
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Habits',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Dietary Habits',
            _getLabel(context, 'dietaryHabits', lifestyle['dietaryHabits']),
          ),
          _buildDetailRow(
            'Smoking Habits',
            _getLabel(context, 'smokingHabits', lifestyle['smokingHabits']),
          ),
          _buildDetailRow(
            'Drinking Habits',
            _getLabel(context, 'drinkingHabits', lifestyle['drinkingHabits']),
          ),
          _buildDetailRow(
            'Open to Pets?',
            _formatYesNo(lifestyle['openToPets']),
            isNotFilled: lifestyle['openToPets'] == null,
          ),
          const SizedBox(height: 12),
          const Text(
            'Assets',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Own a House',
            _formatYesNo(lifestyle['ownAHouse']),
          ),
          _buildDetailRow(
            'Own a Car',
            _formatYesNo(lifestyle['ownACar']),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Food I cook',
            lifestyle['foodICook']?.toString() ?? 'Not Filled',
            isNotFilled: lifestyle['foodICook'] == null,
          ),
          _buildDetailRow(
            'Hobbies',
            lifestyle['hobbies']?.toString() ?? 'Not Filled',
            isNotFilled: lifestyle['hobbies'] == null,
          ),
          _buildDetailRow(
            'Interests',
            lifestyle['interest']?.toString() ?? 'Not Filled',
            isNotFilled: lifestyle['interest'] == null,
          ),
          _buildDetailRow(
            'Favourite Music',
            lifestyle['favMusic']?.toString() ?? 'Not Filled',
            isNotFilled: lifestyle['favMusic'] == null,
          ),
          _buildDetailRow(
            'Favorite books',
            lifestyle['favRead']?.toString() ?? 'Not Filled',
            isNotFilled: lifestyle['favRead'] == null,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCard({
    required IconData icon,
    required String title,
    required VoidCallback onEdit,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value,
      {bool isNotFilled = false}) {
    final displayValue = value?.isNotEmpty == true ? value! : 'Not Filled';
    final showRed = isNotFilled || (value == null || value.isEmpty);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: 14,
                color: showRed ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSiblings(Map<String, dynamic> family) {
    final brothers = family['brothers']?.toString() ?? '0';
    final marriedBrothers = family['marriedBrothers']?.toString() ?? '0';
    final sisters = family['sisters']?.toString() ?? '0';
    final marriedSisters = family['marriedSisters']?.toString() ?? '0';

    final parts = <String>[];
    if (brothers != '0' || marriedBrothers != '0') {
      parts.add(
          '$brothers brother${brothers != '1' ? 's' : ''} of which married $marriedBrothers');
    }
    if (sisters != '0' || marriedSisters != '0') {
      parts.add(
          '$sisters sister${sisters != '1' ? 's' : ''} of which married $marriedSisters');
    }

    return parts.isEmpty ? 'Not Filled' : parts.join(', ');
  }
}
