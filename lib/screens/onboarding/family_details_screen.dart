import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/lookup_provider.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../theme/colors.dart';
import '../../models/profile_models.dart';

class FamilyDetailsScreen extends StatefulWidget {
  const FamilyDetailsScreen({super.key});

  @override
  State<FamilyDetailsScreen> createState() => _FamilyDetailsScreenState();
}

class _FamilyDetailsScreenState extends State<FamilyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  
  String? _selectedFamilyStatus;
  String? _selectedFamilyType;
  String? _selectedFamilyValues;
  String? _selectedFamilyIncome;
  String? _selectedFatherOccupation;
  String? _selectedMotherOccupation;
  int _brothersCount = 0;
  int _sistersCount = 0;
  int _marriedBrothersCount = 0;
  int _marriedSistersCount = 0;
  bool _livingWithParents = false;
  String? _selectedGothra;
  String? _selectedFamilyBaseLocation;
  
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
      if (screenName != null && screenName != 'familyDetails') {
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
        if (_selectedFamilyStatus != null) 'familyStatus': _selectedFamilyStatus,
        if (_selectedFamilyType != null) 'familyType': _selectedFamilyType,
        if (_selectedFamilyValues != null) 'familyValues': _selectedFamilyValues,
        if (_selectedFamilyIncome != null) 'familyIncome': _selectedFamilyIncome,
        if (_selectedFatherOccupation != null) 'fatherOccupation': _selectedFatherOccupation,
        if (_selectedMotherOccupation != null) 'motherOccupation': _selectedMotherOccupation,
        'brothersCount': _brothersCount,
        'sistersCount': _sistersCount,
        'marriedBrothersCount': _marriedBrothersCount,
        'marriedSistersCount': _marriedSistersCount,
        'livingWithParents': _livingWithParents,
        if (_selectedGothra != null && _selectedGothra!.isNotEmpty) 'gothra': _selectedGothra,
        if (_selectedFamilyBaseLocation != null && _selectedFamilyBaseLocation!.isNotEmpty) 'familyBaseLocation': _selectedFamilyBaseLocation,
      };

      await _profileService.updateOnboardingStep(payload);
      await _authService.updateLastActiveScreen('aboutYou');
      
      if (mounted) {
        context.go('/about-you');
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

  Widget _buildCounter({
    required String label,
    required int value,
    required Function(int) onChanged,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            Text(
              value.toString(),
              style: theme.textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String? value,
    required Function(String?) onChanged,
    String? hintText,
  }) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: value ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
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
        title: const Text('Family Details'),
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
                      'Tell us about your family',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Family Status
                    _buildDropdown(
                      label: 'Family Status',
                      value: _selectedFamilyStatus,
                      items: [
                        LookupOption(label: 'Middle Class', value: 'Middle Class'),
                        LookupOption(label: 'Upper Middle Class', value: 'Upper Middle Class'),
                        LookupOption(label: 'Rich', value: 'Rich'),
                        LookupOption(label: 'Affluent', value: 'Affluent'),
                      ],
                      onChanged: (val) => setState(() => _selectedFamilyStatus = val),
                    ),
                    const SizedBox(height: 16),
                    // Family Type
                    _buildDropdown(
                      label: 'Family Type',
                      value: _selectedFamilyType,
                      items: [
                        LookupOption(label: 'Nuclear', value: 'Nuclear'),
                        LookupOption(label: 'Joint', value: 'Joint'),
                        LookupOption(label: 'Extended', value: 'Extended'),
                      ],
                      onChanged: (val) => setState(() => _selectedFamilyType = val),
                    ),
                    const SizedBox(height: 16),
                    // Family Values
                    _buildDropdown(
                      label: 'Family Values',
                      value: _selectedFamilyValues,
                      items: [
                        LookupOption(label: 'Traditional', value: 'Traditional'),
                        LookupOption(label: 'Moderate', value: 'Moderate'),
                        LookupOption(label: 'Liberal', value: 'Liberal'),
                      ],
                      onChanged: (val) => setState(() => _selectedFamilyValues = val),
                    ),
                    const SizedBox(height: 16),
                    // Family Income
                    _buildDropdown(
                      label: 'Family Income',
                      value: _selectedFamilyIncome,
                      items: lookupProvider.incomeOptions,
                      onChanged: (val) => setState(() => _selectedFamilyIncome = val),
                    ),
                    const SizedBox(height: 16),
                    // Father Occupation
                    _buildDropdown(
                      label: 'Father Occupation',
                      value: _selectedFatherOccupation,
                      items: lookupProvider.occupations,
                      onChanged: (val) => setState(() => _selectedFatherOccupation = val),
                    ),
                    const SizedBox(height: 16),
                    // Mother Occupation
                    _buildDropdown(
                      label: 'Mother Occupation',
                      value: _selectedMotherOccupation,
                      items: lookupProvider.occupations,
                      onChanged: (val) => setState(() => _selectedMotherOccupation = val),
                    ),
                    const SizedBox(height: 16),
                    // Brothers Count
                    _buildCounter(
                      label: 'Brothers',
                      value: _brothersCount,
                      onChanged: (val) => setState(() => _brothersCount = val),
                    ),
                    const SizedBox(height: 16),
                    // Sisters Count
                    _buildCounter(
                      label: 'Sisters',
                      value: _sistersCount,
                      onChanged: (val) => setState(() => _sistersCount = val),
                    ),
                    const SizedBox(height: 16),
                    // Married Brothers Count
                    _buildCounter(
                      label: 'Married Brothers',
                      value: _marriedBrothersCount,
                      onChanged: (val) => setState(() => _marriedBrothersCount = val),
                    ),
                    const SizedBox(height: 16),
                    // Married Sisters Count
                    _buildCounter(
                      label: 'Married Sisters',
                      value: _marriedSistersCount,
                      onChanged: (val) => setState(() => _marriedSistersCount = val),
                    ),
                    const SizedBox(height: 16),
                    // Living with Parents
                    Row(
                      children: [
                        Checkbox(
                          value: _livingWithParents,
                          onChanged: (val) => setState(() => _livingWithParents = val ?? false),
                        ),
                        Expanded(
                          child: Text(
                            'Living with Parents',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Gothra
                    _buildTextField(
                      label: 'Gothra',
                      value: _selectedGothra,
                      onChanged: (val) => setState(() => _selectedGothra = val),
                      hintText: 'Enter Gothra',
                    ),
                    const SizedBox(height: 16),
                    // Family Base Location
                    _buildTextField(
                      label: 'Family Base Location',
                      value: _selectedFamilyBaseLocation,
                      onChanged: (val) => setState(() => _selectedFamilyBaseLocation = val),
                      hintText: 'Enter family base location',
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

