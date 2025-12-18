import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/colors.dart';
import '../../services/profile_service.dart';
import '../../providers/lookup_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../../utils/profile_utils.dart';
import '../../widgets/common/header_widget.dart';
import '../../widgets/common/bottom_navigation_widget.dart';
import '../../models/profile_models.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String? _error;
  bool _uploadModalOpen = false;
  File? _selectedFile;
  String? _uploadPreview;
  bool _uploadingImage = false;
  String? _uploadError;
  String? _uploadingPhotoId;
  String? _deletingPhotoId;

  // Enriched labels
  String? _countryLabel;
  String? _stateLabel;
  String? _cityLabel;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);
      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);
      await lookupProvider.loadLookupData();

      final response = await _profileService.getUserProfileData();
      if (response['status'] == 'success' && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final misc = data['miscellaneous'] as Map<String, dynamic>?;

        // Fetch enriched location labels
        String? countryLabel;
        String? stateLabel;
        String? cityLabel;

        if (misc != null) {
          final countryId = misc['country']?.toString();
          final stateId = misc['state']?.toString();
          final cityId = misc['city']?.toString();

          // Get country label
          if (countryId != null) {
            countryLabel = lookupProvider.getCountryLabel(countryId);

            // Get state label
            if (stateId != null && countryId.isNotEmpty) {
              try {
                final states = await lookupProvider.getStates(countryId);
                final state = states.firstWhere(
                  (s) => s.value?.toString() == stateId,
                  orElse: () => states.isNotEmpty
                      ? states.first
                      : LookupOption(label: '', value: ''),
                );
                stateLabel = state.label;

                // Get city label
                if (cityId != null && stateId.isNotEmpty) {
                  try {
                    final cities = await lookupProvider.getCities(stateId);
                    final city = cities.firstWhere(
                      (c) => c.value?.toString() == cityId,
                      orElse: () => cities.isNotEmpty
                          ? cities.first
                          : LookupOption(label: '', value: ''),
                    );
                    cityLabel = city.label;
                  } catch (_) {
                    // Silently fail
                  }
                }
              } catch (_) {
                // Silently fail
              }
            }
          }
        }

        setState(() {
          _profileData = data;
          _countryLabel = countryLabel;
          _stateLabel = stateLabel;
          _cityLabel = cityLabel;
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _uploadPreview = image.path;
          _uploadError = null;
        });
      }
    } catch (e) {
      setState(() {
        _uploadError = 'Failed to pick image: ${e.toString()}';
      });
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_selectedFile == null) {
      setState(() => _uploadError = 'Please choose a file to upload.');
      return;
    }

    setState(() {
      _uploadingImage = true;
      _uploadError = null;
    });

    try {
      await _profileService.uploadProfileImage(_selectedFile!.path,
          primary: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _uploadModalOpen = false;
          _selectedFile = null;
          _uploadPreview = null;
        });
        await _loadProfile();
      }
    } catch (e) {
      setState(() {
        _uploadError = e.toString().replaceAll('Exception: ', '');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_uploadError ?? 'Failed to upload image'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingImage = false);
      }
    }
  }

  Future<void> _uploadAdditionalPhoto(File file) async {
    setState(() => _uploadingPhotoId = 'uploading');
    try {
      await _profileService.uploadProfileImage(file.path, primary: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingPhotoId = null);
      }
    }
  }

  Future<void> _deletePhoto(String photoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deletingPhotoId = photoId);
    try {
      await _profileService.deleteProfilePic(photoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete photo: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _deletingPhotoId = null);
      }
    }
  }

  Future<void> _handlePhotoFileSelect() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        await _uploadAdditionalPhoto(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatHeight(dynamic height) {
    if (height == null) return '';
    final inches = int.tryParse(height.toString()) ?? 0;
    if (inches == 0) return '';
    final feet = inches ~/ 12;
    final remainingInches = inches % 12;
    final meters = (inches * 0.0254).toStringAsFixed(2);
    return "$feet'$remainingInches\"($meters mts)";
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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

  String _formatGender(dynamic gender) {
    if (gender == null) return 'Not Filled';
    final genderMap = {
      'm': 'Male',
      'f': 'Female',
      'male': 'Male',
      'female': 'Female',
    };
    return genderMap[gender.toString().toLowerCase()] ?? gender.toString();
  }

  int? _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return null;
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      final monthDiff = today.month - birthDate.month;
      if (monthDiff < 0 || (monthDiff == 0 && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  String _getLabel(BuildContext context, String lookupKey, dynamic value) {
    if (value == null) return 'Not Filled';
    final lookupProvider = Provider.of<LookupProvider>(context, listen: false);
    final label = lookupProvider.getLabelFromValue(lookupKey, value);
    return label ?? 'Not Filled';
  }

  String _formatArray(dynamic value, BuildContext context, String lookupKey) {
    if (value == null) return 'Not Filled';

    if (value is List) {
      if (value.isEmpty) return 'Not Filled';

      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);
      final labels = value
          .map((item) {
            final label = lookupProvider.getLabelFromValue(lookupKey, item);
            return label ?? item.toString();
          })
          .where((label) => label.isNotEmpty)
          .toList();

      return labels.isEmpty ? 'Not Filled' : labels.join(', ');
    }

    return value.toString();
  }

  String? _getProfileImageUrl() {
    if (_profileData == null) return null;
    final misc = _profileData!['miscellaneous'] as Map<String, dynamic>?;
    final profilePic = misc?['profilePic'] as List<dynamic>?;
    if (profilePic == null || profilePic.isEmpty) return null;

    final primaryPic = profilePic.firstWhere(
      (pic) => pic['primary'] == true,
      orElse: () => profilePic.first,
    ) as Map<String, dynamic>?;

    if (primaryPic == null || primaryPic['id'] == null) return null;

    // Try to get clientID first, then fallback to user id or heartsId
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final clientId = misc?['clientID']?.toString() ??
        authProvider.user?.id ??
        misc?['heartsId']?.toString() ??
        '';
    if (clientId.isEmpty) return null;

    return ApiConfig.buildImageUrl(clientId, primaryPic['id'].toString());
  }

  String? _getClientId() {
    if (_profileData == null) return null;
    final misc = _profileData!['miscellaneous'] as Map<String, dynamic>?;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return misc?['clientID']?.toString() ??
        authProvider.user?.id ??
        misc?['heartsId']?.toString();
  }

  Widget _buildProfilePictureSection({
    required String profileId,
    required String profileName,
    required String displayAge,
    required String? profileImageUrl,
    required String gender,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
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
          Stack(
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
                child: ClipOval(
                  child: profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: profileImageUrl,
                          fit: BoxFit.cover,
                          width: 128,
                          height: 128,
                          placeholder: (context, url) => Image.asset(
                            getGenderPlaceholder(gender),
                            fit: BoxFit.cover,
                            width: 128,
                            height: 128,
                          ),
                          errorWidget: (context, url, error) {
                            // Log error for debugging
                            debugPrint(
                                'Image load error: $error for URL: $url');
                            return Image.asset(
                              getGenderPlaceholder(gender),
                              fit: BoxFit.cover,
                              width: 128,
                              height: 128,
                            );
                          },
                        )
                      : Image.asset(
                          getGenderPlaceholder(gender),
                          fit: BoxFit.cover,
                          width: 128,
                          height: 128,
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => setState(() => _uploadModalOpen = true),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
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
                  profileId,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (profileName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    profileName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
                if (displayAge.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    displayAge,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                // Location display
                if (_cityLabel != null ||
                    _stateLabel != null ||
                    _countryLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      _cityLabel,
                      _stateLabel,
                      _countryLabel,
                    ].where((s) => s != null && s.isNotEmpty).join(', '),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallerySection(
      List<dynamic> profilePics, String clientId, String gender) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
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
          const Text(
            'Photos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          profilePics.isEmpty
              ? _buildEmptyPhotoGallery(gender)
              : _buildPhotoGrid(profilePics, clientId, gender),
        ],
      ),
    );
  }

  Widget _buildEmptyPhotoGallery(String gender) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.grey.shade300, style: BorderStyle.solid),
            color: Colors.grey.shade50,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  getGenderPlaceholder(gender),
                  width: 48,
                  height: 48,
                  opacity: const AlwaysStoppedAnimation(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'No photos yet',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        _buildAddPhotoButton(),
      ],
    );
  }

  Widget _buildPhotoGrid(
      List<dynamic> profilePics, String clientId, String gender) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: profilePics.length + 1,
      itemBuilder: (context, index) {
        if (index == profilePics.length) {
          return _buildAddPhotoButton();
        }

        final pic = profilePics[index] as Map<String, dynamic>;
        final photoId = pic['id']?.toString() ?? pic['_id']?.toString() ?? '';
        // Use clientID from misc if available, otherwise use clientId parameter
        final misc = _profileData!['miscellaneous'] as Map<String, dynamic>?;
        final clientIdFromMisc = misc?['clientID']?.toString();
        final effectiveClientId = (clientIdFromMisc != null &&
                clientIdFromMisc.isNotEmpty)
            ? clientIdFromMisc
            : (clientId.isNotEmpty
                ? clientId
                : (Provider.of<AuthProvider>(context, listen: false).user?.id ??
                    ''));
        final imageUrl = effectiveClientId.isNotEmpty && photoId.isNotEmpty
            ? ApiConfig.buildImageUrl(effectiveClientId, photoId)
            : null;
        final isPrimary = pic['primary'] == true;
        final isDeleting = _deletingPhotoId == photoId;

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPrimary ? AppColors.primary : Colors.grey.shade300,
                  width: isPrimary ? 2 : 1,
                ),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Image.asset(
                          getGenderPlaceholder(gender),
                          fit: BoxFit.cover,
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          getGenderPlaceholder(gender),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        getGenderPlaceholder(gender),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            if (isPrimary)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Primary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: isDeleting ? null : () => _deletePhoto(photoId),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 12,
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _uploadingPhotoId != null ? null : _handlePhotoFileSelect,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
          color: Colors.grey.shade50,
        ),
        child: _uploadingPhotoId != null
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Uploading...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 32, color: Colors.grey),
                    SizedBox(height: 4),
                    Text(
                      'Add Photo',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileDetailsSection(
      BuildContext context,
      Map<String, dynamic> basic,
      Map<String, dynamic> critical,
      Map<String, dynamic> misc) {
    return _buildEditableSection(
      title: 'Profile Details',
      onEdit: () {
        context.go('/edit-profile-basic');
      },
      children: [
        DetailRow(
          label: 'Name',
          value: basic['name']?.toString() ?? 'Not Filled',
        ),
        DetailRow(
          label: 'Gender',
          value: _formatGender(basic['gender']),
        ),
        DetailRow(
          label: 'Religion',
          value: _getLabel(context, 'religion', basic['religion']),
        ),
        DetailRow(
          label: 'Mother Tongue',
          value: _getLabel(context, 'motherTongue', basic['motherTongue']),
        ),
        DetailRow(
          label: 'Residential Status',
          value: _getLabel(
              context, 'residentialStatus', basic['residentialStatus']),
        ),
        DetailRow(
          label: 'Country',
          value: _countryLabel ??
              _getLabel(
                  context, 'country', basic['country'] ?? misc['country']),
        ),
        DetailRow(
          label: 'State',
          value: _stateLabel ??
              _getLabel(context, 'state', basic['state'] ?? misc['state']),
        ),
        DetailRow(
          label: 'City',
          value: _cityLabel ??
              _getLabel(context, 'city', basic['city'] ?? misc['city']),
        ),
        DetailRow(
          label: 'Income',
          value: _formatIncome(basic['income']),
        ),
        DetailRow(
          label: 'Caste',
          value: _getLabel(context, 'casts', basic['cast']),
        ),
        DetailRow(
          label: 'Height',
          value: basic['height'] != null
              ? _formatHeight(basic['height'])
              : 'Not Filled',
        ),
      ],
    );
  }

  Widget _buildCriticalFieldSection(
      BuildContext context, Map<String, dynamic> critical) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.yellow.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.yellow.shade200),
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
          const Text(
            'Critical Field',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          DetailRow(
            label: 'Date of Birth',
            value: critical['dob'] != null
                ? _formatDate(critical['dob'].toString())
                : 'Not Filled',
            isNotFilled: critical['dob'] == null,
          ),
          DetailRow(
            label: 'Marital Status',
            value:
                _getLabel(context, 'maritalStatus', critical['maritalStatus']),
            isNotFilled: critical['maritalStatus'] == null,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMeSection(Map<String, dynamic> about) {
    return _buildEditableSection(
      title: 'About Me',
      onEdit: () {
        context.go('/edit-about');
      },
      children: [
        DetailRow(
          label: 'Tell us About YourSelf',
          value: about['description']?.toString() ??
              about['aboutYourself']?.toString() ??
              'Not Filled',
          isNotFilled:
              about['description'] == null && about['aboutYourself'] == null,
        ),
        DetailRow(
          label: 'Profile Managed By',
          value: _getLabel(context, 'managedBy', about['managedBy']),
          isNotFilled: about['managedBy'] == null,
        ),
        DetailRow(
          label: 'Disability',
          value: _getLabel(context, 'disability', about['disability']),
          isNotFilled: about['disability'] == null,
        ),
        DetailRow(
          label: 'Body Type',
          value: _getLabel(context, 'bodyType', about['bodyType']),
          isNotFilled: about['bodyType'] == null,
        ),
        DetailRow(
          label: 'Thalassemia',
          value: _getLabel(context, 'thalassemia', about['thalassemia']),
          isNotFilled: about['thalassemia'] == null,
        ),
        DetailRow(
          label: 'HIV Positive',
          value: _formatYesNo(about['hivPositive']),
          isNotFilled: about['hivPositive'] == null,
        ),
      ],
    );
  }

  Widget _buildEducationSection(
      BuildContext context, Map<String, dynamic> education) {
    return _buildEditableSection(
      title: 'Education',
      onEdit: () {
        context.go('/edit-education');
      },
      children: [
        DetailRow(
          label: 'About My Education',
          value: education['aboutEducation']?.toString() ?? 'Not Filled',
          isNotFilled: education['aboutEducation'] == null,
        ),
        DetailRow(
          label: 'Qualification',
          value:
              _getLabel(context, 'qualification', education['qualification']),
        ),
        DetailRow(
          label: 'Other UG Degree',
          value: education['otherUGDegree']?.toString() ?? 'Not Filled',
          isNotFilled: education['otherUGDegree'] == null,
        ),
        DetailRow(
          label: 'School',
          value: education['school']?.toString() ?? 'Not Filled',
          isNotFilled: education['school'] == null,
        ),
      ],
    );
  }

  Widget _buildCareerSection(
      BuildContext context, Map<String, dynamic> career) {
    return _buildEditableSection(
      title: 'Career',
      onEdit: () {
        context.go('/edit-career');
      },
      children: [
        DetailRow(
          label: 'About My Career',
          value: career['aboutMyCareer']?.toString() ?? 'Not Filled',
          isNotFilled: career['aboutMyCareer'] == null,
        ),
        DetailRow(
          label: 'Employed In',
          value: _getLabel(context, 'employed_in', career['employed_in']),
          isNotFilled: career['employed_in'] == null,
        ),
        DetailRow(
          label: 'Occupation',
          value: _getLabel(context, 'occupation', career['occupation']),
          isNotFilled: career['occupation'] == null,
        ),
        DetailRow(
          label: 'Organisation Name',
          value: career['organisationName']?.toString() ?? 'Not Filled',
          isNotFilled: career['organisationName'] == null,
        ),
        DetailRow(
          label: 'Interested In Settling Abroad',
          value: _getLabel(context, 'interestedInSettlingAbroad',
              career['interestedInSettlingAbroad']),
          isNotFilled: career['interestedInSettlingAbroad'] == null,
        ),
      ],
    );
  }

  Widget _buildFamilySection(BuildContext context, Map<String, dynamic> family,
      Map<String, dynamic> misc) {
    return _buildEditableSection(
      title: 'Family',
      onEdit: () {
        context.go('/edit-family');
      },
      children: [
        DetailRow(
          label: 'About My Family',
          value: family['aboutMyFamily']?.toString() ??
              family['aboutFamily']?.toString() ??
              'Not Filled',
          isNotFilled:
              family['aboutMyFamily'] == null && family['aboutFamily'] == null,
        ),
        DetailRow(
          label: 'Family Status',
          value: _getLabel(context, 'familyStatus', family['familyStatus']),
          isNotFilled: family['familyStatus'] == null,
        ),
        DetailRow(
          label: 'Family Type',
          value: _getLabel(context, 'familyType', family['familyType']),
          isNotFilled: family['familyType'] == null,
        ),
        DetailRow(
          label: 'Family Values',
          value: _getLabel(context, 'familyValues', family['familyValues']),
          isNotFilled: family['familyValues'] == null,
        ),
        DetailRow(
          label: 'Family Income',
          value: _formatIncome(family['familyIncome']),
          isNotFilled: family['familyIncome'] == null,
        ),
        DetailRow(
          label: 'Father Is',
          value: _getLabel(context, 'occupation', family['fatherOccupation']),
          isNotFilled: family['fatherOccupation'] == null,
        ),
        DetailRow(
          label: 'Mother Is',
          value: _getLabel(context, 'occupation', family['motherOccupation']),
          isNotFilled: family['motherOccupation'] == null,
        ),
        DetailRow(
          label: 'Brothers',
          value: family['brothers']?.toString() ?? 'Not Filled',
          isNotFilled: family['brothers'] == null,
        ),
        DetailRow(
          label: 'Married Brothers',
          value: family['marriedBrothers']?.toString() ?? 'Not Filled',
          isNotFilled: family['marriedBrothers'] == null,
        ),
        DetailRow(
          label: 'Sisters',
          value: family['sisters']?.toString() ?? 'Not Filled',
          isNotFilled: family['sisters'] == null,
        ),
        DetailRow(
          label: 'Married Sisters',
          value: family['marriedSisters']?.toString() ?? 'Not Filled',
          isNotFilled: family['marriedSisters'] == null,
        ),
        DetailRow(
          label: 'Gothra',
          value: family['gothra']?.toString() ?? 'Not Filled',
          isNotFilled: family['gothra'] == null,
        ),
        DetailRow(
          label: 'Living With Parents',
          value: _formatYesNo(family['livingWithParents']),
          isNotFilled: family['livingWithParents'] == null,
        ),
        DetailRow(
          label: 'Family Based',
          value: _getLabel(context, 'country',
              family['familyBasedOutOf'] ?? misc['country']),
          isNotFilled: family['familyBasedOutOf'] == null,
        ),
      ],
    );
  }

  Widget _buildContactDetailsSection(Map<String, dynamic> contact) {
    return _buildEditableSection(
      title: 'Contact Details',
      onEdit: () {
        context.go('/edit-contact');
      },
      children: [
        Row(
          children: [
            Expanded(
              child: DetailRow(
                label: 'Mobile Number',
                value: contact['phoneNumber']?.toString() ?? 'Not Filled',
              ),
            ),
            if (contact['phoneNumber'] != null &&
                contact['phoneNumber'].toString().isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
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
        DetailRow(
          label: 'Email Id',
          value: contact['email']?.toString() ?? 'Not Filled',
        ),
        DetailRow(
          label: 'Alternate Mobile No',
          value: contact['altMobileNumber']?.toString() ??
              contact['alternateMobileNo']?.toString() ??
              'Not Filled',
          isNotFilled: contact['altMobileNumber'] == null &&
              contact['alternateMobileNo'] == null,
        ),
        DetailRow(
          label: 'Alternate Email Id',
          value: contact['alternateEmail']?.toString() ??
              contact['alternateEmailId']?.toString() ??
              'Not Filled',
          isNotFilled: contact['alternateEmail'] == null &&
              contact['alternateEmailId'] == null,
        ),
        DetailRow(
          label: 'Landline',
          value: contact['landline']?.toString() ?? 'Not Filled',
          isNotFilled: contact['landline'] == null,
        ),
      ],
    );
  }

  Widget _buildHoroscopeSection(
      BuildContext context,
      Map<String, dynamic> horoscope,
      Map<String, dynamic> critical,
      Map<String, dynamic> misc) {
    return _buildEditableSection(
      title: 'Horoscope',
      onEdit: () {
        context.go('/edit-horoscope');
      },
      children: [
        DetailRow(
          label: 'Rashi',
          value: _getLabel(context, 'rashi', horoscope['rashi']),
          isNotFilled: horoscope['rashi'] == null,
        ),
        DetailRow(
          label: 'Nakshatra',
          value: _getLabel(context, 'nakshatra', horoscope['nakshatra']),
          isNotFilled: horoscope['nakshatra'] == null,
        ),
        DetailRow(
          label: 'Place Of Birth',
          value: [
            _getLabel(context, 'city', horoscope['cityOfBirth']),
            _getLabel(context, 'state', horoscope['stateOfBirth']),
            _getLabel(context, 'country', horoscope['countryOfBirth']),
          ].where((s) => s != 'Not Filled').join(', ').ifEmpty('Not Filled'),
          isNotFilled: horoscope['cityOfBirth'] == null &&
              horoscope['stateOfBirth'] == null &&
              horoscope['countryOfBirth'] == null,
        ),
        DetailRow(
          label: 'Time of Birth',
          value: horoscope['timeOfBirth']?.toString() ?? 'Not Filled',
          isNotFilled: horoscope['timeOfBirth'] == null,
        ),
        DetailRow(
          label: 'Manglik',
          value: _getLabel(context, 'manglik', horoscope['manglik']),
        ),
        DetailRow(
          label: 'Horoscope',
          value: _getLabel(context, 'horoscopes', horoscope['horoscope']),
        ),
      ],
    );
  }

  Widget _buildLifestyleSection(
      BuildContext context, Map<String, dynamic> lifestyle) {
    return _buildEditableSection(
      title: 'Life Style',
      onEdit: () {
        context.go('/edit-lifestyle');
      },
      children: [
        const Text(
          'Habits',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DetailRow(
          label: 'Dietary Habits',
          value:
              _getLabel(context, 'dietaryHabits', lifestyle['dietaryHabits']),
        ),
        DetailRow(
          label: 'Drinking Habits',
          value:
              _getLabel(context, 'drinkingHabits', lifestyle['drinkingHabits']),
        ),
        DetailRow(
          label: 'Smoking Habits',
          value:
              _getLabel(context, 'smokingHabits', lifestyle['smokingHabits']),
        ),
        const SizedBox(height: 16),
        const Text(
          'Assets',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DetailRow(
          label: 'Own a House?',
          value: _formatYesNo(lifestyle['ownAHouse']),
          isNotFilled: lifestyle['ownAHouse'] == null,
        ),
        DetailRow(
          label: 'Own a Car?',
          value: _formatYesNo(lifestyle['ownACar']),
          isNotFilled: lifestyle['ownACar'] == null,
        ),
        DetailRow(
          label: 'Open to Pets?',
          value: _formatYesNo(lifestyle['openToPets']),
          isNotFilled: lifestyle['openToPets'] == null,
        ),
        const SizedBox(height: 16),
        const Text(
          'Other Life Style Preferences',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DetailRow(
          label: 'Languages I Known',
          value: _formatArray(lifestyle['languages'], context, 'languages'),
          isNotFilled: lifestyle['languages'] == null ||
              (lifestyle['languages'] is List &&
                  (lifestyle['languages'] as List).isEmpty),
        ),
        DetailRow(
          label: 'Hobbies',
          value: _formatArray(lifestyle['hobbies'], context, 'hobbies'),
          isNotFilled: lifestyle['hobbies'] == null ||
              (lifestyle['hobbies'] is List &&
                  (lifestyle['hobbies'] as List).isEmpty),
        ),
        DetailRow(
          label: 'Interests',
          value: _formatArray(lifestyle['interest'], context, 'interests'),
          isNotFilled: lifestyle['interest'] == null ||
              (lifestyle['interest'] is List &&
                  (lifestyle['interest'] as List).isEmpty),
        ),
        DetailRow(
          label: 'Food i Cook',
          value: lifestyle['foodICook']?.toString() ?? 'Not Filled',
          isNotFilled: lifestyle['foodICook'] == null,
        ),
        DetailRow(
          label: 'Favourite Music',
          value: _formatArray(lifestyle['favMusic'], context, 'music'),
          isNotFilled: lifestyle['favMusic'] == null ||
              (lifestyle['favMusic'] is List &&
                  (lifestyle['favMusic'] as List).isEmpty),
        ),
        DetailRow(
          label: 'Favourite Read',
          value: lifestyle['favRead']?.toString() ?? 'Not Filled',
          isNotFilled: lifestyle['favRead'] == null,
        ),
        DetailRow(
          label: 'Dress Style',
          value: _formatArray(lifestyle['dress'], context, 'dressStyle'),
          isNotFilled: lifestyle['dress'] == null ||
              (lifestyle['dress'] is List &&
                  (lifestyle['dress'] as List).isEmpty),
        ),
        DetailRow(
          label: 'Sports',
          value: _formatArray(lifestyle['sports'], context, 'sports'),
          isNotFilled: lifestyle['sports'] == null ||
              (lifestyle['sports'] is List &&
                  (lifestyle['sports'] as List).isEmpty),
        ),
        DetailRow(
          label: 'Books',
          value: _formatArray(lifestyle['books'], context, 'books'),
          isNotFilled: lifestyle['books'] == null ||
              (lifestyle['books'] is List &&
                  (lifestyle['books'] as List).isEmpty),
        ),
        DetailRow(
          label: 'Favourite Cuisine',
          value: _formatArray(lifestyle['cuisine'], context, 'cuisines'),
          isNotFilled: lifestyle['cuisine'] == null ||
              (lifestyle['cuisine'] is List &&
                  (lifestyle['cuisine'] as List).isEmpty),
        ),
        DetailRow(
          label: 'Favourite Movies',
          value: lifestyle['movies']?.toString() ?? 'Not Filled',
          isNotFilled: lifestyle['movies'] == null,
        ),
        DetailRow(
          label: 'Favourite Tv Shows',
          value: lifestyle['favTVShow']?.toString() ?? 'Not Filled',
          isNotFilled: lifestyle['favTVShow'] == null,
        ),
        DetailRow(
          label: 'Vacation Destination',
          value: lifestyle['vacayDestination']?.toString() ?? 'Not Filled',
          isNotFilled: lifestyle['vacayDestination'] == null,
        ),
      ],
    );
  }

  Widget _buildEditableSection({
    required String title,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 20,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const HeaderWidget(),
        bottomNavigationBar: const BottomNavigationWidget(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _profileData == null) {
      return Scaffold(
        appBar: const HeaderWidget(),
        bottomNavigationBar: const BottomNavigationWidget(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Failed to load profile',
                  style: const TextStyle(color: AppColors.error)),
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

    final basic = _profileData!['basic'] as Map<String, dynamic>? ?? {};
    final critical = _profileData!['critical'] as Map<String, dynamic>? ?? {};
    final about = _profileData!['about'] as Map<String, dynamic>? ?? {};
    final education = _profileData!['education'] as Map<String, dynamic>? ?? {};
    final career = _profileData!['career'] as Map<String, dynamic>? ?? {};
    final family = _profileData!['family'] as Map<String, dynamic>? ?? {};
    final contact = _profileData!['contact'] as Map<String, dynamic>? ?? {};
    final horoscope = _profileData!['horoscope'] as Map<String, dynamic>? ?? {};
    final lifestyle =
        _profileData!['lifeStyleData'] as Map<String, dynamic>? ?? {};
    final misc = _profileData!['miscellaneous'] as Map<String, dynamic>? ?? {};

    final profileId =
        misc['heartsId'] != null ? 'HEARTS-${misc['heartsId']}' : 'N/A';
    final profileName = basic['name']?.toString() ?? '';
    final age = _calculateAge(critical['dob']?.toString());
    final displayAge = age != null ? '$age yrs' : '';
    final profileImageUrl = _getProfileImageUrl();
    final clientId = _getClientId() ?? '';
    final gender = basic['gender']?.toString() ?? 'M';
    final profilePics = misc['profilePic'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: const HeaderWidget(),
      bottomNavigationBar: const BottomNavigationWidget(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                _buildProfilePictureSection(
                  profileId: profileId,
                  profileName: profileName,
                  displayAge: displayAge,
                  profileImageUrl: profileImageUrl,
                  gender: gender,
                ),
                const SizedBox(height: 24),
                // Photo Gallery Section
                _buildPhotoGallerySection(profilePics, clientId, gender),
                const SizedBox(height: 24),
                // Profile Details Section
                _buildProfileDetailsSection(context, basic, critical, misc),
                const SizedBox(height: 24),
                // Critical Field Section
                _buildCriticalFieldSection(context, critical),
                const SizedBox(height: 24),
                // About Me Section
                _buildAboutMeSection(about),
                const SizedBox(height: 24),
                // Education Section
                _buildEducationSection(context, education),
                const SizedBox(height: 24),
                // Career Section
                _buildCareerSection(context, career),
                const SizedBox(height: 24),
                // Family Section
                _buildFamilySection(context, family, misc),
                const SizedBox(height: 24),
                // Contact Details Section
                _buildContactDetailsSection(contact),
                const SizedBox(height: 24),
                // Horoscope Section
                _buildHoroscopeSection(context, horoscope, critical, misc),
                const SizedBox(height: 24),
                // Life Style Section
                _buildLifestyleSection(context, lifestyle),
                const SizedBox(height: 32),
              ],
            ),
          ),
          // Upload Modal
          if (_uploadModalOpen) _buildUploadModal(),
        ],
      ),
    );
  }

  Widget _buildUploadModal() {
    return GestureDetector(
      onTap: _uploadingImage
          ? null
          : () => setState(() {
                _uploadModalOpen = false;
                _selectedFile = null;
                _uploadPreview = null;
                _uploadError = null;
              }),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping modal content
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Image Upload',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: _uploadingImage
                            ? null
                            : () => setState(() {
                                  _uploadModalOpen = false;
                                  _selectedFile = null;
                                  _uploadPreview = null;
                                  _uploadError = null;
                                }),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_uploadPreview != null)
                    Container(
                      height: 200,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(
                          File(_uploadPreview!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _uploadingImage || _selectedFile == null
                        ? null
                        : _uploadProfileImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: _uploadingImage
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Upload Image'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _uploadingImage ? null : _pickImage,
                    child: const Text('Choose File'),
                  ),
                  if (_uploadError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _uploadError!,
                      style:
                          const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isNotFilled;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.isNotFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value.isNotEmpty ? value : 'Not Filled';
    final showRed = isNotFilled && displayValue == 'Not Filled';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
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
}

extension StringExtension on String {
  String ifEmpty(String fallback) {
    return isEmpty ? fallback : this;
  }
}
