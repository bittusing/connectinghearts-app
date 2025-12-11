import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/lookup_provider.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../theme/colors.dart';
import '../../models/profile_models.dart';

class CareerDetailsScreen extends StatefulWidget {
  const CareerDetailsScreen({super.key});

  @override
  State<CareerDetailsScreen> createState() => _CareerDetailsScreenState();
}

class _CareerDetailsScreenState extends State<CareerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  
  String? _selectedQualification;
  String? _selectedOtherDegree;
  String? _selectedEmploymentType;
  String? _selectedOccupation;
  String? _selectedIncome;
  
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
      if (screenName != null && screenName != 'careerDetails') {
        _navigateToScreen(screenName);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _navigateToScreen(String screenName) {
    final routes = {
      'personalDetails': '/personal-details',
      'socialDetails': '/social-details',
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
        if (_selectedQualification != null) 'qualification': _selectedQualification,
        if (_selectedOtherDegree != null && _selectedOtherDegree!.isNotEmpty) 'otherDegree': _selectedOtherDegree,
        if (_selectedEmploymentType != null) 'employmentType': _selectedEmploymentType,
        if (_selectedOccupation != null) 'occupation': _selectedOccupation,
        if (_selectedIncome != null) 'income': _selectedIncome,
      };

      await _profileService.updateOnboardingStep(payload);
      await _authService.updateLastActiveScreen('socialDetails');
      
      if (mounted) {
        context.go('/social-details');
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

  Widget _buildTextField({
    required String label,
    required String? value,
    required Function(String?) onChanged,
    String? hintText,
    bool isRequired = false,
  }) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: value ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired: isRequired),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText ?? 'Enter $label',
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
          onChanged: onChanged,
          validator: isRequired && (value == null || value.isEmpty)
              ? (val) => 'Please enter $label'
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lookupProvider = Provider.of<LookupProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Details'),
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
                      'Tell us about your career',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Qualification
                    _buildDropdown(
                      label: 'Qualification',
                      value: _selectedQualification,
                      items: lookupProvider.qualifications,
                      onChanged: (val) => setState(() => _selectedQualification = val),
                    ),
                    const SizedBox(height: 16),
                    // Other Degree (if qualification is "Other")
                    if (_selectedQualification?.toLowerCase().contains('other') == true)
                      _buildTextField(
                        label: 'Other Degree',
                        value: _selectedOtherDegree,
                        onChanged: (val) => setState(() => _selectedOtherDegree = val),
                        hintText: 'Enter your degree',
                      ),
                    if (_selectedQualification?.toLowerCase().contains('other') == true)
                      const SizedBox(height: 16),
                    // Employment Type
                    _buildDropdown(
                      label: 'Employment Type',
                      value: _selectedEmploymentType,
                      items: [
                        LookupOption(label: 'Full Time', value: 'Full Time'),
                        LookupOption(label: 'Part Time', value: 'Part Time'),
                        LookupOption(label: 'Self Employed', value: 'Self Employed'),
                        LookupOption(label: 'Unemployed', value: 'Unemployed'),
                        LookupOption(label: 'Student', value: 'Student'),
                      ],
                      onChanged: (val) => setState(() => _selectedEmploymentType = val),
                    ),
                    const SizedBox(height: 16),
                    // Occupation
                    _buildDropdown(
                      label: 'Occupation',
                      value: _selectedOccupation,
                      items: lookupProvider.occupations,
                      onChanged: (val) => setState(() => _selectedOccupation = val),
                    ),
                    const SizedBox(height: 16),
                    // Income
                    _buildDropdown(
                      label: 'Income',
                      value: _selectedIncome,
                      items: lookupProvider.incomeOptions,
                      onChanged: (val) => setState(() => _selectedIncome = val),
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

