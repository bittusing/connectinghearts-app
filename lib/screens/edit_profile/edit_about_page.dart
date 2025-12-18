import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/profile_service.dart';
import '../../providers/lookup_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/common/header_widget.dart';
import '../../widgets/common/bottom_navigation_widget.dart';
import '../../widgets/common/sidebar_widget.dart';
import '../../widgets/common/searchable_dropdown.dart';
import '../../models/profile_models.dart';

class EditAboutPage extends StatefulWidget {
  const EditAboutPage({super.key});

  @override
  State<EditAboutPage> createState() => _EditAboutPageState();
}

class _EditAboutPageState extends State<EditAboutPage> {
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _profileData;
  String? _error;

  String? _managedBy;
  String? _disability;
  String? _bodyType;
  String? _thalassemia;
  String? _hivPositive;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);
      await lookupProvider.loadLookupData();

      final response = await _profileService.getUserProfileData();
      if (response['status'] == 'success' && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final about = data['about'] as Map<String, dynamic>? ?? {};

        setState(() {
          _profileData = data;
          _descriptionController.text = about['description']?.toString() ??
              about['aboutYourself']?.toString() ??
              '';
          _managedBy = about['managedBy']?.toString();
          _disability = about['disability']?.toString();
          _bodyType = about['bodyType']?.toString();
          _thalassemia = about['thalassemia']?.toString();
          _hivPositive = about['hivPositive']?.toString();
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final payload = <String, dynamic>{
        'section': 'about',
      };

      if (_descriptionController.text.isNotEmpty) {
        payload['description'] = _descriptionController.text;
      }
      if (_managedBy != null && _managedBy!.isNotEmpty) {
        payload['managedBy'] = _managedBy;
      }
      if (_disability != null && _disability!.isNotEmpty) {
        payload['disability'] = _disability;
      }
      if (_bodyType != null && _bodyType!.isNotEmpty) {
        payload['bodyType'] = _bodyType;
      }
      if (_thalassemia != null && _thalassemia!.isNotEmpty) {
        payload['thalassemia'] = _thalassemia;
      }
      if (_hivPositive != null && _hivPositive!.isNotEmpty) {
        payload['hivPositive'] = _hivPositive;
      }

      final response = await _profileService.updateProfileSection(payload);

      if (response['status'] == 'success' || response['code'] == 'CH200') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/my-profile');
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lookupProvider = Provider.of<LookupProvider>(context);

    // Get lookup options
    final managedByOptions =
        (lookupProvider.lookupData['managedBy'] as List<dynamic>?)
                ?.cast<LookupOption>() ??
            <LookupOption>[];
    final disabilityOptions =
        (lookupProvider.lookupData['disability'] as List<dynamic>?)
                ?.cast<LookupOption>() ??
            <LookupOption>[];
    final bodyTypeOptions =
        (lookupProvider.lookupData['bodyType'] as List<dynamic>?)
                ?.cast<LookupOption>() ??
            <LookupOption>[];
    final thalassemiaOptions =
        (lookupProvider.lookupData['thalassemia'] as List<dynamic>?)
                ?.cast<LookupOption>() ??
            <LookupOption>[];
    final hivPositiveOptions = <LookupOption>[
      LookupOption(label: 'Yes', value: 'Y'),
      LookupOption(label: 'No', value: 'N'),
    ];

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
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final characterCount = _descriptionController.text.length;
    final maxCharacters = 500;
    final isOverLimit = characterCount > maxCharacters;

    return Scaffold(
      appBar: const HeaderWidget(),
      drawer: const SidebarWidget(),
      bottomNavigationBar: const BottomNavigationWidget(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: theme.dividerColor.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Profile',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Update your about me information',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: theme.dividerColor.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Description
                      Text(
                        'Tell us About YourSelf',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 8,
                        maxLength: maxCharacters,
                        decoration: InputDecoration(
                          hintText: 'Tell us about yourself...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  isOverLimit ? Colors.red : theme.dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  isOverLimit ? Colors.red : theme.dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  isOverLimit ? Colors.red : AppColors.primary,
                              width: 2,
                            ),
                          ),
                          counterText: '$characterCount/$maxCharacters',
                          counterStyle: TextStyle(
                            color: isOverLimit
                                ? Colors.red
                                : theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      SearchableDropdown(
                        label: 'Profile Managed By',
                        value: _managedBy,
                        options: managedByOptions,
                        hint: 'Select Profile Managed By',
                        onChanged: (value) =>
                            setState(() => _managedBy = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Disability',
                        value: _disability,
                        options: disabilityOptions,
                        hint: 'Select Disability',
                        onChanged: (value) =>
                            setState(() => _disability = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Body Type',
                        value: _bodyType,
                        options: bodyTypeOptions,
                        hint: 'Select Body Type',
                        onChanged: (value) => setState(() => _bodyType = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Thalassemia',
                        value: _thalassemia,
                        options: thalassemiaOptions,
                        hint: 'Select Thalassemia',
                        onChanged: (value) =>
                            setState(() => _thalassemia = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'HIV Positive',
                        value: _hivPositive,
                        options: hivPositiveOptions,
                        hint: 'Select HIV Positive',
                        onChanged: (value) =>
                            setState(() => _hivPositive = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Update',
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
      ),
    );
  }
}




