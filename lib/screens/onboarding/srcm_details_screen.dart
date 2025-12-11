import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../theme/colors.dart';
import '../../widgets/common/upload_modal.dart';

class SRCMDetailsScreen extends StatefulWidget {
  const SRCMDetailsScreen({super.key});

  @override
  State<SRCMDetailsScreen> createState() => _SRCMDetailsScreenState();
}

class _SRCMDetailsScreenState extends State<SRCMDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  
  final _srcmIdController = TextEditingController();
  final _satsangCenterController = TextEditingController();
  final _preceptorNameController = TextEditingController();
  final _preceptorMobileController = TextEditingController();
  final _preceptorEmailController = TextEditingController();
  
  File? _idProofFile;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;

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
      final userData = await _authService.getUser();
      final screenName = userData['screenName'] as String?;
      if (screenName != null && screenName != 'srcmDetails') {
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
      'familyDetails': '/family-details',
      'aboutYou': '/about-you',
    };
    final route = routes[screenName];
    if (route != null && mounted) {
      context.go(route);
    }
  }

  Future<void> _uploadIdProof(File file) async {
    setState(() => _isUploadingImage = true);
    try {
      await _profileService.uploadSrcmIdImage(file.path);
      setState(() => _idProofFile = file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID proof uploaded successfully'),
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
        title: 'Upload ID Proof',
        onUpload: _uploadIdProof,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idProofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload ID proof'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final payload = <String, dynamic>{
        'srcmId': _srcmIdController.text.trim(),
        'satsangCenter': _satsangCenterController.text.trim(),
        'preceptorName': _preceptorNameController.text.trim(),
        'preceptorMobile': _preceptorMobileController.text.trim(),
        'preceptorEmail': _preceptorEmailController.text.trim(),
      };

      await _profileService.updateSrcmDetails(payload);
      await _authService.updateLastActiveScreen('familyDetails');
      
      if (mounted) {
        context.go('/family-details');
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool isRequired = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired: isRequired),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: 'Enter $label',
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
          validator: isRequired && controller.text.trim().isEmpty
              ? (val) => 'Please enter $label'
              : null,
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SRCM Details'),
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
                'SRCM Verification Details',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              // ID Proof Upload
              _buildLabel('ID Proof', isRequired: true),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isUploadingImage ? null : _showUploadModal,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _idProofFile != null
                          ? AppColors.success
                          : theme.dividerColor,
                      width: 2,
                    ),
                  ),
                  child: _idProofFile != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                _idProofFile!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => setState(() => _idProofFile = null),
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
                                Icons.cloud_upload_outlined,
                                size: 48,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to upload ID proof',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // SRCM ID
              _buildTextField(
                label: 'SRCM ID Number',
                controller: _srcmIdController,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              // Satsang Center
              _buildTextField(
                label: 'Satsang Center',
                controller: _satsangCenterController,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              // Preceptor Name
              _buildTextField(
                label: 'Preceptor Name',
                controller: _preceptorNameController,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              // Preceptor Mobile
              _buildTextField(
                label: 'Preceptor Mobile',
                controller: _preceptorMobileController,
                keyboardType: TextInputType.phone,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              // Preceptor Email
              _buildTextField(
                label: 'Preceptor Email',
                controller: _preceptorEmailController,
                keyboardType: TextInputType.emailAddress,
                isRequired: true,
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
                          'Continue',
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
}

