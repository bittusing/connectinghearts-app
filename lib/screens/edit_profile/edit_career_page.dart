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

class EditCareerPage extends StatefulWidget {
  const EditCareerPage({super.key});

  @override
  State<EditCareerPage> createState() => _EditCareerPageState();
}

class _EditCareerPageState extends State<EditCareerPage> {
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final _aboutMyCareerController = TextEditingController();
  final _organisationNameController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _profileData;
  String? _error;

  String? _employedIn;
  String? _occupation;
  String? _interestedInSettlingAbroad;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _aboutMyCareerController.dispose();
    _organisationNameController.dispose();
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
        final career = data['career'] as Map<String, dynamic>? ?? {};

        setState(() {
          _profileData = data;
          _aboutMyCareerController.text = career['aboutMyCareer']?.toString() ??
              career['aboutCareer']?.toString() ??
              '';
          _employedIn = career['employed_in']?.toString();
          _occupation = career['occupation']?.toString();
          _organisationNameController.text =
              career['organisationName']?.toString() ?? '';
          _interestedInSettlingAbroad =
              career['interestedInSettlingAbroad']?.toString();
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
        'section': 'career',
      };

      if (_aboutMyCareerController.text.isNotEmpty) {
        payload['aboutMyCareer'] = _aboutMyCareerController.text;
      }
      if (_employedIn != null && _employedIn!.isNotEmpty) {
        payload['employed_in'] = _employedIn;
      }
      if (_occupation != null && _occupation!.isNotEmpty) {
        payload['occupation'] = _occupation;
      }
      if (_organisationNameController.text.isNotEmpty) {
        payload['organisationName'] = _organisationNameController.text;
      }
      if (_interestedInSettlingAbroad != null &&
          _interestedInSettlingAbroad!.isNotEmpty) {
        payload['interestedInSettlingAbroad'] = _interestedInSettlingAbroad;
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

    final interestedInSettlingAbroadOptions = <LookupOption>[
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

    final characterCount = _aboutMyCareerController.text.length;
    final maxCharacters = 125;
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
                        'Update your career information',
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
                      // About My Career
                      Text(
                        'About My Career',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _aboutMyCareerController,
                        maxLines: 6,
                        maxLength: maxCharacters,
                        decoration: InputDecoration(
                          hintText: 'Tell us about your career...',
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
                          counterText: '$characterCount / $maxCharacters',
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
                        label: 'Employed In',
                        value: _employedIn,
                        options: lookupProvider.employedInOptions,
                        hint: 'Select Employed In',
                        onChanged: (value) =>
                            setState(() => _employedIn = value),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Occupation',
                        value: _occupation,
                        options: lookupProvider.occupations,
                        hint: 'Select Occupation',
                        onChanged: (value) =>
                            setState(() => _occupation = value),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _organisationNameController,
                        decoration: InputDecoration(
                          labelText: 'Organisation',
                          hintText: 'Enter organisation name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown(
                        label: 'Interested In Settling Abroad',
                        value: _interestedInSettlingAbroad,
                        options: interestedInSettlingAbroadOptions,
                        hint: 'Select Interested In Settling Abroad',
                        onChanged: (value) =>
                            setState(() => _interestedInSettlingAbroad = value),
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




