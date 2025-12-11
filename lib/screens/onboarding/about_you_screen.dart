import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../theme/colors.dart';
import '../../widgets/common/upload_modal.dart';

class AboutYouScreen extends StatefulWidget {
  const AboutYouScreen({super.key});

  @override
  State<AboutYouScreen> createState() => _AboutYouScreenState();
}

class _AboutYouScreenState extends State<AboutYouScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final _aboutMeController = TextEditingController();
  
  File? _profilePicture;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;

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
      final userData = await _authService.getUser();
      final screenName = userData['screenName'] as String?;
      if (screenName != null && screenName != 'aboutYou') {
        _navigateToScreen(screenName);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _navigateToScreen(String screenName) {
    final routes = {
      'personalDetails': '/personal-details',
      'careerDetails': '/career-details',
      'socialDetails': '/social-details',
      'srcmDetails': '/srcm-details',
      'familyDetails': '/family-details',
    };
    final route = routes[screenName];
    if (route != null && mounted) {
      context.go(route);
    }
  }

  Future<void> _uploadProfilePicture(File file) async {
    setState(() => _isUploadingImage = true);
    try {
      await _profileService.uploadProfileImage(file.path);
      setState(() => _profilePicture = file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture uploaded successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showUploadModal() {
    showDialog(
      context: context,
      builder: (context) => UploadModal(
        title: 'Upload Profile Picture',
        onUpload: _uploadProfilePicture,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profilePicture == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload profile picture'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final payload = <String, dynamic>{
        if (_aboutMeController.text.trim().isNotEmpty) 'aboutMe': _aboutMeController.text.trim(),
      };

      if (payload.isNotEmpty) {
        await _profileService.updateOnboardingStep(payload);
      }
      
      await _authService.updateLastActiveScreen('verificationPending');
      
      if (mounted) {
        context.go('/verification-pending');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About You'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Complete your profile',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              // Profile Picture Upload
              _buildLabel('Profile Picture', isRequired: true),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: _isUploadingImage ? null : _showUploadModal,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _profilePicture != null
                            ? AppColors.success
                            : theme.dividerColor,
                        width: 3,
                      ),
                    ),
                    child: _profilePicture != null
                        ? Stack(
                            children: [
                              ClipOval(
                                child: Image.file(
                                  _profilePicture!,
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
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
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isUploadingImage)
                                const CircularProgressIndicator()
                              else ...[
                                Icon(
                                  Icons.camera_alt,
                                  size: 48,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to upload',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // About Me
              _buildLabel('About Me'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _aboutMeController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Tell us about yourself, your interests, hobbies, and what you\'re looking for in a partner...',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Submit Button
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Complete Profile',
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
        ),
      ),
    );
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
}

