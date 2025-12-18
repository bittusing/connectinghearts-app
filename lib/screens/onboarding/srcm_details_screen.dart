import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/api_client.dart';
import '../../theme/colors.dart';

class SRCMDetailsScreen extends StatefulWidget {
  const SRCMDetailsScreen({super.key});

  @override
  State<SRCMDetailsScreen> createState() => _SRCMDetailsScreenState();
}

class _SRCMDetailsScreenState extends State<SRCMDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final ApiClient _apiClient = ApiClient();

  final _srcmIdController = TextEditingController();
  final _satsangCenterController = TextEditingController();
  final _preceptorNameController = TextEditingController();
  final _preceptorMobileController = TextEditingController();
  final _preceptorEmailController = TextEditingController();

  File? _selectedFile;
  String? _uploadedFileName; // Store fileName from upload response
  String? _uploadedImageUrl; // Store image URL for preview
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  bool _uploadModalOpen = false;
  bool _confirmDialogOpen = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _checkScreenName();
  }

  @override
  void dispose() {
    _srcmIdController.dispose();
    _satsangCenterController.dispose();
    _preceptorNameController.dispose();
    _preceptorMobileController.dispose();
    _preceptorEmailController.dispose();
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
          screenName != 'srcmdetails') {
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
      'familydetails': '/family-details',
      'partnerpreferences': '/partner-preference',
      'aboutyou': '/about-you',
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
      // Call POST /srcmDetails/uploadSrcmId with multipart/form-data
      final response =
          await _profileService.uploadSrcmIdImage(_selectedFile!.path);

      // Response format: {"fileName":"1765258323184-school.jpg"}
      final fileName = response['fileName']?.toString() ??
          response['data']?['fileName']?.toString();

      if (fileName != null) {
        // Construct image URL for preview
        // The API returns fileName, we can construct URL: /srcmDetails/file/{fileName}
        // For now, store fileName and show success
        setState(() {
          _uploadedFileName = fileName;
          _uploadedImageUrl = _selectedFile!.path; // Use local file for preview
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
        throw Exception('Upload response missing fileName');
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

  Future<void> _submitDetails() async {
    setState(() => _isSubmitting = true);

    try {
      // Prepare payload (match webapp exactly)
      final payload = <String, dynamic>{};

      if (_srcmIdController.text.trim().isNotEmpty) {
        payload['srcmIdNumber'] = _srcmIdController.text.trim();
      }
      if (_preceptorNameController.text.trim().isNotEmpty) {
        payload['preceptorsName'] = _preceptorNameController.text.trim();
      }
      if (_preceptorMobileController.text.trim().isNotEmpty) {
        // Convert to number if it's a valid number string
        final mobileNum = _preceptorMobileController.text
            .trim()
            .replaceAll(RegExp(r'\D'), '');
        payload['preceptorsContactNumber'] = mobileNum.isNotEmpty
            ? int.tryParse(mobileNum) ?? mobileNum
            : _preceptorMobileController.text.trim();
      }
      if (_preceptorEmailController.text.trim().isNotEmpty) {
        payload['preceptorsEmail'] = _preceptorEmailController.text.trim();
      }
      if (_satsangCenterController.text.trim().isNotEmpty) {
        payload['satsangCenter'] = _satsangCenterController.text.trim();
      }
      // Extract fileName from upload response
      if (_uploadedFileName != null) {
        payload['srcmIdFilename'] = _uploadedFileName;
      }

      // Call PATCH /srcmDetails/updateSrcmDetails (like webapp)
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/srcmDetails/updateSrcmDetails',
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
                  'SRCM details updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Update last active screen (like webapp)
        await _authService.updateLastActiveScreen('familydetails');

        // Get user data and navigate (like webapp)
        try {
          final userResponse = await _authService.getUser();
          final responseStatus = userResponse['status']?.toString() ?? '';
          final userData = userResponse['data'] as Map<String, dynamic>?;
          final screenName = userData?['screenName']
                  ?.toString()
                  .toLowerCase()
                  .replaceAll(RegExp(r'\s+'), '') ??
              '';

          if (responseStatus == 'success' && screenName.isNotEmpty && mounted) {
            final routeMap = {
              'personaldetails': '/personal-details',
              'careerdetails': '/career-details',
              'socialdetails': '/social-details',
              'srcmdetails': '/srcm-details',
              'familydetails': '/family-details',
              'partnerpreferences': '/partner-preference',
              'aboutyou': '/about-you',
              'underverification': '/verification-pending',
              'dashboard': '/',
            };

            final route = routeMap[screenName] ?? '/family-details';
            context.go(route);
          } else if (mounted) {
            // Default to family details
            context.go('/family-details');
          }
        } catch (e) {
          // If getUser fails, navigate to family details
          if (mounted) {
            context.go('/family-details');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']?.toString() ??
                  'Failed to update SRCM details'),
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
            content: Text(errorMsg.isNotEmpty
                ? errorMsg
                : 'Failed to update SRCM details'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleFormSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that image is required
    if (_uploadedFileName == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Please upload SRCM ID Proof image before submitting.'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _uploadModalOpen = true);
      }
      return;
    }

    // Show confirmation dialog
    setState(() => _confirmDialogOpen = true);
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
                              widthFactor: 4 / 7,
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
                            'STEP 4 OF 7',
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
                            'Fill in your SRCM / Heartfulness details',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Provide additional information about your SRCM journey.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          // SRCM ID Proof Upload Section
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
                                _buildLabel('SRCM ID Proof', isRequired: true),
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
                                    height: 160,
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
                          // SRCM ID Number
                          _buildLabel('SRCM / Heartfulness ID Number',
                              isRequired: true),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _srcmIdController,
                            decoration: InputDecoration(
                              hintText:
                                  'Enter your SRCM or Heartfulness ID number',
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
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter SRCM ID number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Satsang center
                          _buildLabel('Satsang center name / city',
                              isRequired: true),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _satsangCenterController,
                            decoration: InputDecoration(
                              hintText: 'Enter Satsang center name or city',
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
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter Satsang center name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Preceptor's Name
                          _buildLabel('Preceptor\'s Name (frequently visited)',
                              isRequired: true),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _preceptorNameController,
                            decoration: InputDecoration(
                              hintText: 'Enter preceptor\'s name',
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
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter preceptor\'s name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Preceptor's Mobile Number
                          _buildLabel('Preceptor\'s Mobile Number',
                              isRequired: true),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _preceptorMobileController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'Enter preceptor\'s mobile number',
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
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter preceptor\'s mobile number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Preceptor's Email
                          _buildLabel('Preceptor\'s Email'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _preceptorEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Enter preceptor\'s email',
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
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Back and Next buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  context.go('/social-details');
                                },
                                child: const Text('← Back'),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: const LinearGradient(
                                    colors: AppColors.gradientColors,
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed:
                                      _isSubmitting ? null : _handleFormSubmit,
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
                                          'Next',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
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
                                height: 160,
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
                  // Confirmation Dialog
                  if (_confirmDialogOpen)
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
                                'Confirmation',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Data submitted cannot be changed. Please ensure the information is correct before proceeding.',
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(
                                            () => _confirmDialogOpen = false);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        side: BorderSide(
                                            color: theme.dividerColor),
                                      ),
                                      child: const Text('Back to edit'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        gradient: const LinearGradient(
                                          colors: AppColors.gradientColors,
                                        ),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(
                                              () => _confirmDialogOpen = false);
                                          _submitDetails();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                        ),
                                        child: const Text(
                                          'Confirm',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
