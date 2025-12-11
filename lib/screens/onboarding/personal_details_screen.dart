import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/lookup_provider.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../theme/colors.dart';
import '../../models/profile_models.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedHeight;
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  String? _selectedResidenceStatus;
  String? _selectedMotherTongue;
  String? _selectedReligion;
  String? _selectedCaste;
  String? _selectedHoroscope;
  String? _selectedManglik;
  String? _selectedIncome;
  String? _selectedEmployment;
  String? _selectedOccupation;
  String? _selectedEducation;
  String? _selectedMaritalStatus;
  String? _selectedChildren;
  
  List<LookupOption> _states = [];
  List<LookupOption> _cities = [];
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
      if (screenName != null && screenName != 'personalDetails') {
        // Redirect to correct screen
        _navigateToScreen(screenName);
      }
    } catch (e) {
      // Handle error silently or show message
    }
  }

  void _navigateToScreen(String screenName) {
    final routes = {
      'careerDetails': '/career-details',
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
      if (_selectedCountry != null) {
        _states = await lookupProvider.getStates(_selectedCountry!);
      }
      if (_selectedState != null) {
        _cities = await lookupProvider.getCities(_selectedState!);
      }
    } catch (e) {
      // Handle error silently or show message
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onCountryChanged(String? value) async {
    setState(() {
      _selectedCountry = value;
      _selectedState = null;
      _selectedCity = null;
      _states = [];
      _cities = [];
    });
    if (value != null) {
      final lookupProvider = Provider.of<LookupProvider>(context, listen: false);
      _states = await lookupProvider.getStates(value);
      setState(() {});
    }
  }

  Future<void> _onStateChanged(String? value) async {
    setState(() {
      _selectedState = value;
      _selectedCity = null;
      _cities = [];
    });
    if (value != null) {
      final lookupProvider = Provider.of<LookupProvider>(context, listen: false);
      _cities = await lookupProvider.getCities(value);
      setState(() {});
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final payload = <String, dynamic>{
        if (_selectedGender != null) 'gender': _selectedGender,
        if (_selectedDate != null) 'dateOfBirth': _selectedDate!.toIso8601String().split('T')[0],
        if (_selectedHeight != null) 'height': _selectedHeight,
        if (_selectedCountry != null) 'country': _selectedCountry,
        if (_selectedState != null) 'state': _selectedState,
        if (_selectedCity != null) 'city': _selectedCity,
        if (_selectedResidenceStatus != null) 'residenceStatus': _selectedResidenceStatus,
        if (_selectedMotherTongue != null) 'motherTongue': _selectedMotherTongue,
        if (_selectedReligion != null) 'religion': _selectedReligion,
        if (_selectedCaste != null) 'caste': _selectedCaste,
        if (_selectedHoroscope != null) 'horoscope': _selectedHoroscope,
        if (_selectedManglik != null) 'manglik': _selectedManglik,
        if (_selectedIncome != null) 'income': _selectedIncome,
        if (_selectedEmployment != null) 'employment': _selectedEmployment,
        if (_selectedOccupation != null) 'occupation': _selectedOccupation,
        if (_selectedEducation != null) 'qualification': _selectedEducation,
        if (_selectedMaritalStatus != null) 'maritalStatus': _selectedMaritalStatus,
        if (_selectedChildren != null) 'children': _selectedChildren,
      };

      await _profileService.updateOnboardingStep(payload);
      await _authService.updateLastActiveScreen('careerDetails');
      
      if (mounted) {
        context.go('/career-details');
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
        title: const Text('Personal Details'),
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
                      'Tell us about yourself',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Gender
                    _buildDropdown(
                      label: 'Gender',
                      value: _selectedGender,
                      items: [
                        LookupOption(label: 'Male', value: 'Male'),
                        LookupOption(label: 'Female', value: 'Female'),
                      ],
                      onChanged: (val) => setState(() => _selectedGender = val),
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    // Date of Birth
                    _buildLabel('Date of Birth', isRequired: true),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate != null
                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                  : 'Select date of birth',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: _selectedDate != null
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Height
                    _buildDropdown(
                      label: 'Height',
                      value: _selectedHeight,
                      items: lookupProvider.heightOptions,
                      onChanged: (val) => setState(() => _selectedHeight = val),
                    ),
                    const SizedBox(height: 16),
                    // Country
                    _buildDropdown(
                      label: 'Country',
                      value: _selectedCountry,
                      items: lookupProvider.countries,
                      onChanged: _onCountryChanged,
                    ),
                    const SizedBox(height: 16),
                    // State
                    if (_selectedCountry != null)
                      _buildDropdown(
                        label: 'State',
                        value: _selectedState,
                        items: _states,
                        onChanged: _onStateChanged,
                      ),
                    if (_selectedCountry != null) const SizedBox(height: 16),
                    // City
                    if (_selectedState != null)
                      _buildDropdown(
                        label: 'City',
                        value: _selectedCity,
                        items: _cities,
                        onChanged: (val) => setState(() => _selectedCity = val),
                      ),
                    if (_selectedState != null) const SizedBox(height: 16),
                    // Residence Status
                    _buildDropdown(
                      label: 'Residence Status',
                      value: _selectedResidenceStatus,
                      items: [
                        LookupOption(label: 'Citizen', value: 'Citizen'),
                        LookupOption(label: 'Permanent Resident', value: 'Permanent Resident'),
                        LookupOption(label: 'Work Visa', value: 'Work Visa'),
                        LookupOption(label: 'Student Visa', value: 'Student Visa'),
                      ],
                      onChanged: (val) => setState(() => _selectedResidenceStatus = val),
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
                    const SizedBox(height: 16),
                    // Income
                    _buildDropdown(
                      label: 'Income',
                      value: _selectedIncome,
                      items: lookupProvider.incomeOptions,
                      onChanged: (val) => setState(() => _selectedIncome = val),
                    ),
                    const SizedBox(height: 16),
                    // Employment
                    _buildDropdown(
                      label: 'Employment Type',
                      value: _selectedEmployment,
                      items: [
                        LookupOption(label: 'Full Time', value: 'Full Time'),
                        LookupOption(label: 'Part Time', value: 'Part Time'),
                        LookupOption(label: 'Self Employed', value: 'Self Employed'),
                        LookupOption(label: 'Unemployed', value: 'Unemployed'),
                      ],
                      onChanged: (val) => setState(() => _selectedEmployment = val),
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
                    // Education
                    _buildDropdown(
                      label: 'Education',
                      value: _selectedEducation,
                      items: lookupProvider.qualifications,
                      onChanged: (val) => setState(() => _selectedEducation = val),
                    ),
                    const SizedBox(height: 16),
                    // Marital Status
                    _buildDropdown(
                      label: 'Marital Status',
                      value: _selectedMaritalStatus,
                      items: lookupProvider.maritalStatuses,
                      onChanged: (val) => setState(() => _selectedMaritalStatus = val),
                    ),
                    const SizedBox(height: 16),
                    // Children
                    _buildDropdown(
                      label: 'Children',
                      value: _selectedChildren,
                      items: [
                        LookupOption(label: 'None', value: 'None'),
                        LookupOption(label: '1', value: '1'),
                        LookupOption(label: '2', value: '2'),
                        LookupOption(label: '3+', value: '3+'),
                      ],
                      onChanged: (val) => setState(() => _selectedChildren = val),
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

