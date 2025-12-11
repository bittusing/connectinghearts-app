import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/lookup_provider.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../theme/colors.dart';
import '../../models/profile_models.dart';

class SocialDetailsScreen extends StatefulWidget {
  const SocialDetailsScreen({super.key});

  @override
  State<SocialDetailsScreen> createState() => _SocialDetailsScreenState();
}

class _SocialDetailsScreenState extends State<SocialDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  
  String? _selectedMaritalStatus;
  String? _selectedMotherTongue;
  String? _selectedReligion;
  String? _selectedCaste;
  bool _castNoBar = false;
  String? _selectedHoroscope;
  String? _selectedManglik;
  
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checkScreenName();
    _loadLookupData();
  }

  Future<void> _checkScreenName() async {
    try {
      final userData = await _authService.getUser();
      final screenName = userData['screenName'] as String?;
      if (screenName != null && screenName != 'socialDetails') {
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
      'srcmDetails': '/srcm-details',
      'familyDetails': '/family-details',
      'aboutYou': '/about-you',
    };
    final route = routes[screenName];
    if (route != null && mounted) {
      context.go(route);
    }
  }

  Future<void> _loadLookupData() async {
    setState(() => _isLoading = true);
    try {
      final lookupProvider = Provider.of<LookupProvider>(context, listen: false);
      await lookupProvider.loadLookupData();
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final payload = <String, dynamic>{
        if (_selectedMaritalStatus != null) 'maritalStatus': _selectedMaritalStatus,
        if (_selectedMotherTongue != null) 'motherTongue': _selectedMotherTongue,
        if (_selectedReligion != null) 'religion': _selectedReligion,
        if (_selectedCaste != null) 'caste': _selectedCaste,
        'castNoBar': _castNoBar,
        if (_selectedHoroscope != null) 'horoscope': _selectedHoroscope,
        if (_selectedManglik != null) 'manglik': _selectedManglik,
      };

      await _profileService.updateOnboardingStep(payload);
      await _authService.updateLastActiveScreen('srcmDetails');
      
      if (mounted) {
        context.go('/srcm-details');
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<LookupOption> items,
    required Function(String?) onChanged,
    bool isRequired = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired: isRequired),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
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
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item.value?.toString(),
              child: Text(item.label),
            );
          }).toList(),
          onChanged: onChanged,
          validator: isRequired && value == null
              ? (val) => 'Please select $label'
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
    final lookupProvider = Provider.of<LookupProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Details'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tell us about your social background',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Marital Status
                    _buildDropdown(
                      label: 'Marital Status',
                      value: _selectedMaritalStatus,
                      items: lookupProvider.maritalStatuses,
                      onChanged: (val) => setState(() => _selectedMaritalStatus = val),
                    ),
                    const SizedBox(height: 16),
                    // Mother Tongue
                    _buildDropdown(
                      label: 'Mother Tongue',
                      value: _selectedMotherTongue,
                      items: lookupProvider.motherTongues,
                      onChanged: (val) => setState(() => _selectedMotherTongue = val),
                    ),
                    const SizedBox(height: 16),
                    // Religion
                    _buildDropdown(
                      label: 'Religion',
                      value: _selectedReligion,
                      items: lookupProvider.religions,
                      onChanged: (val) => setState(() => _selectedReligion = val),
                    ),
                    const SizedBox(height: 16),
                    // Caste
                    _buildDropdown(
                      label: 'Caste',
                      value: _selectedCaste,
                      items: lookupProvider.castes,
                      onChanged: (val) => setState(() => _selectedCaste = val),
                    ),
                    const SizedBox(height: 16),
                    // Cast No Bar checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _castNoBar,
                          onChanged: (val) => setState(() => _castNoBar = val ?? false),
                        ),
                        Expanded(
                          child: Text(
                            'Caste No Bar',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Horoscope
                    _buildDropdown(
                      label: 'Horoscope',
                      value: _selectedHoroscope,
                      items: [
                        LookupOption(label: 'Yes', value: 'Yes'),
                        LookupOption(label: 'No', value: 'No'),
                      ],
                      onChanged: (val) => setState(() => _selectedHoroscope = val),
                    ),
                    const SizedBox(height: 16),
                    // Manglik
                    _buildDropdown(
                      label: 'Manglik',
                      value: _selectedManglik,
                      items: [
                        LookupOption(label: 'Yes', value: 'Yes'),
                        LookupOption(label: 'No', value: 'No'),
                      ],
                      onChanged: (val) => setState(() => _selectedManglik = val),
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

