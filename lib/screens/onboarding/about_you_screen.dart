import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/api_client.dart';
import '../../theme/colors.dart';

class AboutYouScreen extends StatefulWidget {
  const AboutYouScreen({super.key});

  @override
  State<AboutYouScreen> createState() => _AboutYouScreenState();
}

class _AboutYouScreenState extends State<AboutYouScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _aboutMeController = TextEditingController();

  File? _selectedFile;
  String? _uploadedFileId; // Store fileId from upload response
  String? _uploadedImageUrl; // Store image URL for preview
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  bool _uploadModalOpen = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _checkScreenName();
  }

  @override
  void dispose() {
    _aboutMeController.dispose();
    super.dispose();
  }

  Future<void> _checkScreenName() async {
    try {
      final userResponse = await _authService.getUser();
      final responseStatus = userResponse['status']?.toString() ?? '';
      final userData = userResponse['data'] as Map<String, dynamic>?;
      final screenName = userData?['screenName']
              ?.toString()
              .toLowerCase()
              .replaceAll(RegExp(r'\s+'), '') ??
          '';

      if (responseStatus == 'success' &&
          screenName.isNotEmpty &&
          screenName != 'aboutyou') {
        _navigateToScreen(screenName);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _navigateToScreen(String screenName) {
    final routeMap = {
      'personaldetails': '/personal-details',
      'careerdetails': '/career-details',
      'socialdetails': '/social-details',
      'srcmdetails': '/srcm-details',
      'familydetails': '/family-details',
      'partnerpreferences': '/partner-preference',
      'underverification': '/verification-pending',
      'dashboard': '/',
    };
    final route = routeMap[screenName];
    if (route != null && mounted) {
      context.go(route);
    }
  }

  Future<void> _pickImage({required ImageSource source}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();

        // Check file size (5MB limit)
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size should be less than 5MB'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
          _uploadError = null;
        });
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

  Future<void> _uploadImage() async {
    if (_selectedFile == null) {
      setState(() => _uploadError = 'Please choose a file to upload.');
      return;
    }

    setState(() {
      _isUploadingImage = true;
      _uploadError = null;
    });

    try {
      // Call POST /profile/uploadProfilePic with multipart/form-data (profilePhoto, primary: true)
      final response =
          await _profileService.uploadProfileImage(_selectedFile!.path);

      // Response format: {"fileName":"1765187534896-blob","id":1765187535026}
      final fileId = response['id']?.toString() ??
          response['data']?['id']?.toString() ??
          response['fileName']?.toString();

      if (fileId != null) {
        // Get userId for constructing image URL
        try {
          final userResponse = await _authService.getUser();
          final userData = userResponse['data'] as Map<String, dynamic>?;
          final userId =
              userData?['_id']?.toString() ?? userData?['id']?.toString();

          if (userId != null) {
            setState(() {
              _uploadedFileId = fileId;
              _uploadedImageUrl =
                  _selectedFile!.path; // Use local file for preview
              _uploadModalOpen = false;
              _selectedFile = null;
              _uploadError = null;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image uploaded successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            throw Exception('User ID not found');
          }
        } catch (e) {
          throw Exception('Failed to get user ID: ${e.toString()}');
        }
      } else {
        throw Exception('Upload response missing file ID');
      }
    } catch (e) {
      String errorMsg = e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
      setState(() => _uploadError =
          errorMsg.isNotEmpty ? errorMsg : 'Failed to upload image');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_uploadError ?? 'Failed to upload image'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that image is required
    if (_uploadedFileId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Profile picture is required. Please upload an image before submitting.'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _uploadModalOpen = true);
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Prepare payload (match webapp - PATCH /personalDetails)
      final payload = <String, dynamic>{
        if (_aboutMeController.text.trim().isNotEmpty)
          'description': _aboutMeController.text.trim(),
      };

      // Call PATCH /personalDetails (like webapp)
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/personalDetails',
        body: payload,
      );

      // Check response
      final status = response['status']?.toString() ?? '';
      final code = response['code']?.toString() ?? '';

      if (status == 'success' || code == 'CH200') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']?.toString() ??
                  'About you updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Update last active screen (like webapp)
        await _authService.updateLastActiveScreen('underVerification');

        // Navigate to verification pending (like webapp)
        if (mounted) {
          context.go('/verification-pending');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']?.toString() ??
                  'Failed to update about you'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg =
            e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                errorMsg.isNotEmpty ? errorMsg : 'Failed to update about you'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Text.rich(
      TextSpan(
        text: text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
        children: isRequired
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.primary),
                ),
              ]
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Progress indicator
                          Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: 7 / 7,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: AppColors.gradientColors,
                                  ),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Step indicator
                          Text(
                            'STEP 7 OF 7',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // Title
                          Text(
                            'About you',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Complete your profile by adding a photo and a short bio.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          // Profile Picture Upload Section
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.cardColor.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: theme.dividerColor,
                                style: BorderStyle.solid,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildLabel('Profile picture',
                                    isRequired: true),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _uploadModalOpen = true;
                                      _selectedFile = null;
                                      _uploadError = null;
                                    });
                                  },
                                  child: Container(
                                    height: 192,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: theme.dividerColor,
                                      ),
                                    ),
                                    child: _uploadedImageUrl != null
                                        ? Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                child: Image.file(
                                                  File(_uploadedImageUrl!),
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: const Icon(
                                                    Icons.edit,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add,
                                                size: 48,
                                                color: AppColors.primary,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Upload',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color: theme.textTheme
                                                      .bodySmall?.color,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                if (_uploadedImageUrl != null) ...[
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _uploadModalOpen = true;
                                        _selectedFile = null;
                                        _uploadError = null;
                                      });
                                    },
                                    child: Text(
                                      'Change image',
                                      style:
                                          TextStyle(color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // About Me (Bio) with character counter
                          _buildLabel('Tell us about yourself'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _aboutMeController,
                            maxLines: 4,
                            maxLength: 125,
                            decoration: InputDecoration(
                              hintText: 'Tell us about yourself',
                              filled: true,
                              fillColor: theme.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: theme.dividerColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: theme.dividerColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: AppColors.primary, width: 2),
                              ),
                              counterText:
                                  '${_aboutMeController.text.length}/125',
                            ),
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            onChanged: (value) {
                              setState(() {}); // Update counter
                            },
                          ),
                          const SizedBox(height: 32),
                          // Create my profile button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: const LinearGradient(
                                colors: AppColors.gradientColors,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Create my profile',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Back button
                          TextButton(
                            onPressed: () {
                              context.go('/partner-preference');
                            },
                            child: const Text('← Back'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Upload Modal
                  if (_uploadModalOpen)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Image Upload',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Preview area
                              Container(
                                height: 192,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: theme.cardColor.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.dividerColor,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: _selectedFile != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.file(
                                          _selectedFile!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const SizedBox(),
                              ),
                              const SizedBox(height: 16),
                              // Image source selection buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _pickImage(
                                          source: ImageSource.gallery),
                                      icon: const Icon(Icons.photo_library),
                                      label: const Text('Gallery'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.cardColor,
                                        foregroundColor: AppColors.primary,
                                        side: BorderSide(
                                            color: AppColors.primary, width: 2),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _pickImage(
                                          source: ImageSource.camera),
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('Camera'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.cardColor,
                                        foregroundColor: AppColors.primary,
                                        side: BorderSide(
                                            color: AppColors.primary, width: 2),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_selectedFile != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _selectedFile!.path.split('/').last,
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 16),
                              // Upload button
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: const LinearGradient(
                                    colors: AppColors.gradientColors,
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed:
                                      _isUploadingImage || _selectedFile == null
                                          ? null
                                          : _uploadImage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  child: _isUploadingImage
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Upload Image',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Cancel button
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _uploadModalOpen = false;
                                    _selectedFile = null;
                                    _uploadError = null;
                                  });
                                },
                                child: const Text('Cancel'),
                              ),
                              if (_uploadError != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _uploadError!,
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
