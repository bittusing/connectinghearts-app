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
import '../../widgets/common/searchable_multi_select.dart';

class PartnerPreferenceScreen extends StatefulWidget {
  const PartnerPreferenceScreen({super.key});

  @override
  State<PartnerPreferenceScreen> createState() =>
      _PartnerPreferenceScreenState();
}

class _PartnerPreferenceScreenState extends State<PartnerPreferenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final ApiClient _apiClient = ApiClient();

  // Basic Preferences (ranges)
  String? _minAge; // Value from lookup
  String? _maxAge; // Value from lookup
  String? _minHeight; // Value from lookup
  String? _maxHeight; // Value from lookup
  String? _minIncome; // Value from lookup
  String? _maxIncome; // Value from lookup

  // Location & Background (multi-select)
  List<String> _selectedCountries = []; // Values from lookup
  List<String> _selectedResidentialStatuses = []; // Values from lookup
  List<String> _selectedOccupations = []; // Values from lookup
  List<String> _selectedMotherTongues = []; // Values from lookup

  // Religion & Family (multi-select)
  List<String> _selectedReligions = []; // Values from lookup
  List<String> _selectedMaritalStatuses = []; // Values from lookup
  List<String> _selectedCastes = []; // Values from lookup
  List<String> _selectedEducations = []; // Values from lookup

  // Horoscope (multi-select)
  List<String> _selectedHoroscopes = []; // Values from lookup
  List<String> _selectedManglik = []; // Values from lookup

  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checkScreenName();
    _loadData();
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
          screenName != 'partnerpreferences') {
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
      'srcmdetails': '/srcm-details',
      'familydetails': '/family-details',
      'aboutyou': '/about-you',
      'underverification': '/verification-pending',
      'dashboard': '/',
    };
    final route = routeMap[screenName];
    if (route != null && mounted) {
      context.go(route);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);

      // Load lookup data (includes countries)
      await lookupProvider.loadLookupData();

      // Ensure countries are loaded - loadLookupData() calls fetchCountries() internally
      // Countries should be available via lookupProvider.countries

      // Load existing partner preferences (like webapp)
      try {
        final response = await _profileService.getPartnerPreferences();
        if (response['status'] == 'success' && response['data'] != null) {
          _hydrateForm(
              response['data'] as Map<String, dynamic>, lookupProvider);
        }
      } catch (e) {
        // Silently fail - user can set preferences fresh
      }

      // Also call validateToken API (like webapp)
      try {
        await _authService.validateToken();
      } catch (e) {
        // Silently fail
      }

      // Data loaded
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _hydrateForm(Map<String, dynamic> data, LookupProvider lookupProvider) {
    // Hydrate age range
    if (data['age'] != null && data['age'] is Map) {
      final age = data['age'] as Map<String, dynamic>;
      _minAge = age['min']?.toString();
      _maxAge = age['max']?.toString();
    }

    // Hydrate height range
    if (data['height'] != null && data['height'] is Map) {
      final height = data['height'] as Map<String, dynamic>;
      _minHeight = height['min']?.toString();
      _maxHeight = height['max']?.toString();
    }

    // Hydrate income range
    if (data['income'] != null && data['income'] is Map) {
      final income = data['income'] as Map<String, dynamic>;
      _minIncome = income['min']?.toString();
      _maxIncome = income['max']?.toString();
    }

    // Hydrate multi-select fields
    _selectedCountries =
        _normalizeMultiValue(data['countries'] ?? data['country']);
    _selectedResidentialStatuses =
        _normalizeMultiValue(data['residentialStatus']);
    _selectedOccupations = _normalizeMultiValue(data['occupation']);
    _selectedMotherTongues = _normalizeMultiValue(data['motherTongue']);
    _selectedReligions =
        _normalizeMultiValue(data['religions'] ?? data['religion']);
    _selectedMaritalStatuses =
        _normalizeMultiValue(data['maritalStatuses'] ?? data['maritalStatus']);
    _selectedCastes = _normalizeMultiValue(data['caste'] ?? data['casts']);
    _selectedEducations =
        _normalizeMultiValue(data['education'] ?? data['educations']);
    _selectedHoroscopes =
        _normalizeMultiValue(data['horoscope'] ?? data['horoscopes']);
    _selectedManglik = _normalizeMultiValue(data['manglik']);
  }

  List<String> _normalizeMultiValue(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [value.toString()];
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      // Build range payloads
      Map<String, dynamic>? ageRange;
      if (_minAge != null || _maxAge != null) {
        ageRange = {};
        if (_minAge != null) {
          final minValue = num.tryParse(_minAge!);
          if (minValue != null) ageRange['min'] = minValue;
        }
        if (_maxAge != null) {
          final maxValue = num.tryParse(_maxAge!);
          if (maxValue != null) ageRange['max'] = maxValue;
        }
      }

      Map<String, dynamic>? heightRange;
      if (_minHeight != null || _maxHeight != null) {
        heightRange = {};
        if (_minHeight != null) {
          final minValue = num.tryParse(_minHeight!);
          if (minValue != null) heightRange['min'] = minValue;
        }
        if (_maxHeight != null) {
          final maxValue = num.tryParse(_maxHeight!);
          if (maxValue != null) heightRange['max'] = maxValue;
        }
      }

      Map<String, dynamic>? incomeRange;
      if (_minIncome != null || _maxIncome != null) {
        incomeRange = {};
        if (_minIncome != null) {
          final minValue = num.tryParse(_minIncome!);
          if (minValue != null) incomeRange['min'] = minValue;
        }
        if (_maxIncome != null) {
          final maxValue = num.tryParse(_maxIncome!);
          if (maxValue != null) incomeRange['max'] = maxValue;
        }
      }

      // Prepare payload (match webapp exactly - PATCH /preference)
      // No fields are required - can submit empty payload
      final payload = <String, dynamic>{
        if (ageRange != null && ageRange.isNotEmpty) 'age': ageRange,
        if (heightRange != null && heightRange.isNotEmpty)
          'height': heightRange,
        if (incomeRange != null && incomeRange.isNotEmpty)
          'income': incomeRange,
        if (_selectedCountries.isNotEmpty) 'country': _selectedCountries,
        if (_selectedResidentialStatuses.isNotEmpty)
          'residentialStatus': _selectedResidentialStatuses,
        if (_selectedOccupations.isNotEmpty) 'occupation': _selectedOccupations,
        if (_selectedMotherTongues.isNotEmpty)
          'motherTongue': _selectedMotherTongues,
        if (_selectedReligions.isNotEmpty) 'religion': _selectedReligions,
        if (_selectedMaritalStatuses.isNotEmpty)
          'maritalStatus': _selectedMaritalStatuses,
        if (_selectedCastes.isNotEmpty) 'caste': _selectedCastes,
        if (_selectedEducations.isNotEmpty) 'education': _selectedEducations,
        if (_selectedHoroscopes.isNotEmpty) 'horoscope': _selectedHoroscopes,
        if (_selectedManglik.isNotEmpty) 'manglik': _selectedManglik,
      };

      // Call PATCH /preference (like webapp) - even if payload is empty
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/preference',
        body: payload.isEmpty ? {} : payload,
      );

      // Check response
      final status = response['status']?.toString() ?? '';
      final code = response['code']?.toString() ?? '';

      if (status == 'success' || code == 'CH200') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']?.toString() ??
                  'Partner preferences updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Update last active screen (like webapp)
        await _authService.updateLastActiveScreen('aboutyou');

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

            final route = routeMap[screenName] ?? '/about-you';
            context.go(route);
          } else if (mounted) {
            // Default to about you
            context.go('/about-you');
          }
        } catch (e) {
          // If getUser fails, navigate to about you
          if (mounted) {
            context.go('/about-you');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']?.toString() ??
                  'Failed to update partner preferences'),
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
                : 'Failed to update partner preferences'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildRangeGroup({
    required String label,
    required String minLabel,
    required String maxLabel,
    required String? minValue,
    required String? maxValue,
    required List<LookupOption> options,
    required Function(String?) onMinChanged,
    required Function(String?) onMaxChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SearchableDropdown(
                  label: minLabel,
                  value: minValue,
                  options: options,
                  hint: 'Select $minLabel',
                  onChanged: onMinChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SearchableDropdown(
                  label: maxLabel,
                  value: maxValue,
                  options: options,
                  hint: 'Select $maxLabel',
                  onChanged: onMaxChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxGroup({
    required String label,
    required List<String> selectedValues,
    required List<LookupOption> options,
    required Function(String) onToggle,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final value = option.value?.toString() ?? '';
            final isSelected = selectedValues.contains(value);
            return GestureDetector(
              onTap: () => onToggle(value),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : theme.dividerColor,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      size: 18,
                      color: isSelected
                          ? AppColors.primary
                          : theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      option.label,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : theme.textTheme.bodyLarge?.color,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
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
                          widthFactor: 6 / 7,
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
                        'STEP 6 OF 7',
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
                        'Partner Preferences',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Update your ideal partner criteria to find the perfect match.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Basic Preferences Section
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
                              'Basic Preferences',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildRangeGroup(
                              label: 'Age',
                              minLabel: 'Min Age',
                              maxLabel: 'Max Age',
                              minValue: _minAge,
                              maxValue: _maxAge,
                              options: lookupProvider.ageOptions,
                              onMinChanged: (value) {
                                setState(() => _minAge = value);
                              },
                              onMaxChanged: (value) {
                                setState(() => _maxAge = value);
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildRangeGroup(
                              label: 'Height',
                              minLabel: 'Min Height',
                              maxLabel: 'Max Height',
                              minValue: _minHeight,
                              maxValue: _maxHeight,
                              options: lookupProvider.heightOptions,
                              onMinChanged: (value) {
                                setState(() => _minHeight = value);
                              },
                              onMaxChanged: (value) {
                                setState(() => _maxHeight = value);
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildRangeGroup(
                              label: 'Income',
                              minLabel: 'Min Income',
                              maxLabel: 'Max Income',
                              minValue: _minIncome,
                              maxValue: _maxIncome,
                              options: lookupProvider.incomeOptions,
                              onMinChanged: (value) {
                                setState(() => _minIncome = value);
                              },
                              onMaxChanged: (value) {
                                setState(() => _maxIncome = value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Location & Background Section
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
                              'Location & Background',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: SearchableMultiSelect(
                                    label: 'Country',
                                    values: _selectedCountries,
                                    options: lookupProvider.countries,
                                    hint: 'Select country',
                                    onChanged: (values) {
                                      setState(
                                          () => _selectedCountries = values);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableMultiSelect(
                                    label: 'Residential Status',
                                    values: _selectedResidentialStatuses,
                                    options: lookupProvider.residentialStatuses,
                                    hint: 'Select residential status',
                                    onChanged: (values) {
                                      setState(() =>
                                          _selectedResidentialStatuses =
                                              values);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: SearchableMultiSelect(
                                    label: 'Occupation',
                                    values: _selectedOccupations,
                                    options: lookupProvider.occupations,
                                    hint: 'Select occupation',
                                    onChanged: (values) {
                                      setState(
                                          () => _selectedOccupations = values);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableMultiSelect(
                                    label: 'Mother Tongue',
                                    values: _selectedMotherTongues,
                                    options: lookupProvider.motherTongues,
                                    hint: 'Select mother tongue',
                                    onChanged: (values) {
                                      setState(() =>
                                          _selectedMotherTongues = values);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Religion & Family Section
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
                              'Religion & Family',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildCheckboxGroup(
                              label: 'Religion',
                              selectedValues: _selectedReligions,
                              options: lookupProvider.religions,
                              onToggle: (value) {
                                setState(() {
                                  if (_selectedReligions.contains(value)) {
                                    _selectedReligions.remove(value);
                                  } else {
                                    _selectedReligions.add(value);
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildCheckboxGroup(
                              label: 'Marital Status',
                              selectedValues: _selectedMaritalStatuses,
                              options: lookupProvider.maritalStatuses,
                              onToggle: (value) {
                                setState(() {
                                  if (_selectedMaritalStatuses
                                      .contains(value)) {
                                    _selectedMaritalStatuses.remove(value);
                                  } else {
                                    _selectedMaritalStatuses.add(value);
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: SearchableMultiSelect(
                                    label: 'Caste',
                                    values: _selectedCastes,
                                    options: lookupProvider.castes,
                                    hint: 'Select caste',
                                    onChanged: (values) {
                                      setState(() => _selectedCastes = values);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableMultiSelect(
                                    label: 'Education',
                                    values: _selectedEducations,
                                    options: lookupProvider.highestEducation,
                                    hint: 'Select education',
                                    onChanged: (values) {
                                      setState(
                                          () => _selectedEducations = values);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Horoscope Section
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
                              'Horoscope',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SearchableMultiSelect(
                              label: 'Horoscope',
                              values: _selectedHoroscopes,
                              options: lookupProvider.horoscopes,
                              hint: 'Select horoscope',
                              onChanged: (values) {
                                setState(() => _selectedHoroscopes = values);
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildCheckboxGroup(
                              label: 'Manglik',
                              selectedValues: _selectedManglik,
                              options: lookupProvider.manglik,
                              onToggle: (value) {
                                setState(() {
                                  if (_selectedManglik.contains(value)) {
                                    _selectedManglik.remove(value);
                                  } else {
                                    _selectedManglik.add(value);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Cancel and Save buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              context.go('/family-details');
                            },
                            child: const Text('← Back'),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  context.go('/');
                                },
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: const LinearGradient(
                                    colors: AppColors.gradientColors,
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed:
                                      _isSubmitting ? null : _handleSubmit,
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
                                          'Save Preferences',
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
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
