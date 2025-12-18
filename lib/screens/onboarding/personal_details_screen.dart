import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/lookup_provider.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/api_client.dart';
import '../../theme/colors.dart';
import '../../models/profile_models.dart';
import '../../widgets/common/searchable_dropdown.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  DateTime? _selectedDate;
  String? _selectedGender; // No default - required
  String? _selectedHeight;
  String? _selectedCountry;
  String? _selectedCountryValue;
  String? _selectedState;
  String? _selectedStateValue;
  String? _selectedCity;
  String? _selectedCityValue;
  String? _selectedResidenceStatus;

  List<LookupOption> _states = [];
  List<LookupOption> _cities = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _lookupDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkScreenName();
    _loadLookupData();
  }

  Future<void> _checkScreenName() async {
    try {
      final userResponse = await _authService.getUser();
      // Response structure: { code, status, message, data: { screenName, ... } }
      final responseStatus = userResponse['status']?.toString() ?? '';
      final userData = userResponse['data'] as Map<String, dynamic>?;
      final screenName = userData?['screenName']
              ?.toString()
              .toLowerCase()
              .replaceAll(RegExp(r'\s+'), '') ??
          '';

      if (responseStatus == 'success' &&
          screenName.isNotEmpty &&
          screenName != 'personaldetails') {
        // Redirect to correct screen
        _navigateToScreen(screenName);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _navigateToScreen(String screenName) {
    final routeMap = {
      'careerdetails': '/career-details',
      'socialdetails': '/social-details',
      'srcmdetails': '/srcm-details',
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

  Future<void> _loadLookupData() async {
    setState(() => _isLoading = true);
    try {
      // Call lookup API (like webapp)
      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);
      await lookupProvider.loadLookupData();

      // Also call validateToken API (like webapp)
      try {
        await _authService.validateToken();
      } catch (e) {
        // Silently fail
      }

      setState(() => _lookupDataLoaded = true);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onCountryChanged(String? value) async {
    if (value == null) {
      setState(() {
        _selectedCountry = null;
        _selectedCountryValue = null;
        _selectedState = null;
        _selectedStateValue = null;
        _selectedCity = null;
        _selectedCityValue = null;
        _states = [];
        _cities = [];
      });
      return;
    }

    // Find country value from lookup
    final lookupProvider = Provider.of<LookupProvider>(context, listen: false);
    final countryOption = lookupProvider.countries.firstWhere(
      (c) => c.value?.toString() == value,
      orElse: () => LookupOption(label: '', value: value),
    );

    setState(() {
      _selectedCountry = countryOption.label;
      _selectedCountryValue = value;
      _selectedState = null;
      _selectedStateValue = null;
      _selectedCity = null;
      _selectedCityValue = null;
      _states = [];
      _cities = [];
    });

    // Load states
    try {
      final states = await lookupProvider.getStates(value);
      if (mounted) {
        setState(() => _states = states);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onStateChanged(String? value) async {
    if (value == null) {
      setState(() {
        _selectedState = null;
        _selectedStateValue = null;
        _selectedCity = null;
        _selectedCityValue = null;
        _cities = [];
      });
      return;
    }

    // Find state value from lookup
    final stateOption = _states.firstWhere(
      (s) => s.value?.toString() == value,
      orElse: () => LookupOption(label: '', value: value),
    );

    setState(() {
      _selectedState = stateOption.label;
      _selectedStateValue = value;
      _selectedCity = null;
      _selectedCityValue = null;
      _cities = [];
    });

    // Load cities
    try {
      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);
      final cities = await lookupProvider.getCities(value);
      if (mounted) {
        setState(() => _cities = cities);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onCityChanged(String? value) async {
    if (value == null) {
      setState(() {
        _selectedCity = null;
        _selectedCityValue = null;
      });
      return;
    }

    // Find city value from lookup
    final cityOption = _cities.firstWhere(
      (c) => c.value?.toString() == value,
      orElse: () => LookupOption(label: '', value: value),
    );

    setState(() {
      _selectedCity = cityOption.label;
      _selectedCityValue = value;
    });
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime minDate = DateTime(now.year - 100, now.month, now.day);
    final DateTime maxDate = DateTime(now.year - 18, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: maxDate,
      firstDate: minDate,
      lastDate: maxDate,
      helpText: 'Select date of birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate required fields
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select gender'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date of birth'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);

      // Convert DOB to timestamp (like webapp)
      final dobTimestamp = _selectedDate!.millisecondsSinceEpoch;

      // Get height value from lookup (height is stored as value string, need to find option)
      int? heightValue;
      if (_selectedHeight != null) {
        try {
          final heightOption = lookupProvider.heightOptions.firstWhere(
            (h) => h.value?.toString() == _selectedHeight,
          );
          if (heightOption.value != null) {
            heightValue = heightOption.value is int
                ? heightOption.value as int
                : (heightOption.value is num
                    ? (heightOption.value as num).toInt()
                    : int.tryParse(heightOption.value.toString()));
          }
        } catch (e) {
          // Height option not found, skip
        }
      }

      // Residential status is already stored as value from SearchableDropdown
      String? residentialStatusValue = _selectedResidenceStatus;

      // Prepare payload (match webapp exactly)
      final payload = <String, dynamic>{
        'gender': _selectedGender == 'Male' ? 'M' : 'F',
        'dob': dobTimestamp,
        if (heightValue != null) 'height': heightValue,
        if (_selectedCountryValue != null) 'country': _selectedCountryValue,
        if (_selectedStateValue != null) 'state': _selectedStateValue,
        if (_selectedCityValue != null) 'city': _selectedCityValue,
        if (residentialStatusValue != null)
          'residentialStatus': residentialStatusValue,
        'employed_in': 'pvtSct', // Default as per webapp
        'maritalStatus': 'nvm', // Default as per webapp
        'haveChildren': 'N', // Default as per webapp
        'castNoBar': false, // Default as per webapp
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
                  'Personal details updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Update last active screen (like webapp)
        await _authService.updateLastActiveScreen('careerdetails');

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

            final route = routeMap[screenName] ?? '/career-details';
            context.go(route);
          } else if (mounted) {
            // Default to career details
            context.go('/career-details');
          }
        } catch (e) {
          // If getUser fails, navigate to career details
          if (mounted) {
            context.go('/career-details');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']?.toString() ??
                  'Failed to update personal details'),
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
                : 'Failed to update personal details'),
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
    final lookupProvider = Provider.of<LookupProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                          widthFactor: 1 / 7,
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
                        'STEP 1 OF 7',
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
                        'Fill in your Personal Details',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Provide additional information like your Date of Birth, Height and Location.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Basics Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BASICS',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Gender (ToggleGroup - required, no default)
                            _buildLabel('Gender', isRequired: true),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedGender = 'Male'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _selectedGender == 'Male'
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _selectedGender == 'Male'
                                              ? AppColors.primary
                                              : theme.dividerColor,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        'Male',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _selectedGender == 'Male'
                                              ? Colors.white
                                              : theme
                                                  .textTheme.bodyLarge?.color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedGender = 'Female'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _selectedGender == 'Female'
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _selectedGender == 'Female'
                                              ? AppColors.primary
                                              : theme.dividerColor,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        'Female',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _selectedGender == 'Female'
                                              ? Colors.white
                                              : theme
                                                  .textTheme.bodyLarge?.color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // DOB and Height in grid
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Date of Birth',
                                          isRequired: true),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: _selectDate,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.cardColor,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: theme.dividerColor),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _selectedDate != null
                                                    ? '${_selectedDate!.day.toString().padLeft(2, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.year}'
                                                    : 'dd-mm-yyyy',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color: _selectedDate != null
                                                      ? theme.textTheme
                                                          .bodyLarge?.color
                                                      : theme.textTheme
                                                          .bodySmall?.color
                                                          ?.withOpacity(0.5),
                                                ),
                                              ),
                                              Icon(
                                                Icons.calendar_today,
                                                size: 20,
                                                color: theme
                                                    .textTheme.bodySmall?.color,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdown(
                                    label: 'Height',
                                    value: _selectedHeight,
                                    options: lookupProvider.heightOptions,
                                    hint: 'Select height',
                                    onChanged: (value) {
                                      setState(() => _selectedHeight = value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Country and State in grid
                            Row(
                              children: [
                                Expanded(
                                  child: SearchableDropdown(
                                    label: 'Country',
                                    value: _selectedCountryValue,
                                    options: lookupProvider.countries,
                                    hint: 'Select country',
                                    onChanged: _onCountryChanged,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdown(
                                    label: 'State',
                                    value: _selectedStateValue,
                                    options: _states,
                                    enabled: _selectedCountryValue != null,
                                    hint: _selectedCountryValue == null
                                        ? 'Select country first'
                                        : 'Select state',
                                    onChanged: _onStateChanged,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // City and Residential Status in grid
                            Row(
                              children: [
                                Expanded(
                                  child: SearchableDropdown(
                                    label: 'City',
                                    value: _selectedCityValue,
                                    options: _cities,
                                    enabled: _selectedStateValue != null,
                                    hint: _selectedStateValue == null
                                        ? 'Select state first'
                                        : 'Select city',
                                    onChanged: _onCityChanged,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdown(
                                    label: 'Residential Status',
                                    value: _selectedResidenceStatus,
                                    options: lookupProvider.residentialStatuses,
                                    hint: 'Select residential status',
                                    onChanged: (value) {
                                      setState(() =>
                                          _selectedResidenceStatus = value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Back and Next buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              context.go('/login');
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
      ),
    );
  }
}
