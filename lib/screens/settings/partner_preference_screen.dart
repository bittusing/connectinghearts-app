import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/lookup_provider.dart';
import '../../services/profile_service.dart';
import '../../services/api_client.dart';
import '../../theme/colors.dart';
import '../../models/profile_models.dart';
import '../../widgets/common/searchable_dropdown.dart';
import '../../widgets/common/searchable_multi_select.dart';
import '../../widgets/common/header_widget.dart';
import '../../widgets/common/bottom_navigation_widget.dart';
import '../../widgets/common/sidebar_widget.dart';

class PartnerPreferenceScreen extends StatefulWidget {
  const PartnerPreferenceScreen({super.key});

  @override
  State<PartnerPreferenceScreen> createState() =>
      _PartnerPreferenceScreenState();
}

class _PartnerPreferenceScreenState extends State<PartnerPreferenceScreen> {
  final ProfileService _profileService = ProfileService();
  final ApiClient _apiClient = ApiClient();

  // Basic Preferences (ranges)
  String? _minAge;
  String? _maxAge;
  String? _minHeight;
  String? _maxHeight;
  String? _minIncome;
  String? _maxIncome;

  // Location & Background (multi-select)
  List<String> _selectedCountries = [];
  List<String> _selectedResidentialStatuses = [];
  List<String> _selectedOccupations = [];
  List<String> _selectedMotherTongues = [];

  // Religion & Family (multi-select)
  List<String> _selectedReligions = [];
  List<String> _selectedMaritalStatuses = [];
  List<String> _selectedCastes = [];
  List<String> _selectedEducations = [];

  // Horoscope (multi-select)
  List<String> _selectedHoroscopes = [];
  List<String> _selectedManglik = [];

  bool _isLoading = false;
  bool _isSubmitting = false;
  List<LookupOption> _countryOptions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);
      await lookupProvider.loadLookupData();

      // Load countries
      _countryOptions = lookupProvider.countries;

      // Load existing partner preferences
      try {
        final response = await _profileService.getPartnerPreferences();
        if (response['status'] == 'success' && response['data'] != null) {
          _hydrateForm(
              response['data'] as Map<String, dynamic>, lookupProvider);
        }
      } catch (e) {
        // Silently fail - user can set preferences fresh
      }
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

      if (payload.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Please select at least one preference before updating.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _isSubmitting = false);
        return;
      }

      // Call PATCH /preference (like webapp)
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/preference',
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
                  'Partner preferences updated successfully.'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
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
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lookupProvider = Provider.of<LookupProvider>(context);

    return Scaffold(
      appBar: const HeaderWidget(),
      drawer: const SidebarWidget(),
      bottomNavigationBar: const BottomNavigationWidget(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                          Text(
                            'CONNECTING HEARTS',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              letterSpacing: 3.5,
                              color: AppColors.primary,
                            ),
              ),
                          const SizedBox(height: 8),
              Text(
                            'Partner Preferences',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
                          const SizedBox(height: 4),
              Text(
                            'Update your ideal partner criteria anytime.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'PREFERENCES SAVED',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: AppColors.primary,
                              ),
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
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Age Range
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
                          const SizedBox(height: 24),
                          // Height Range
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
                          const SizedBox(height: 24),
                          // Income Range
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
                          const SizedBox(height: 24),
                          // Country and Residential Status
                          Row(
                            children: [
                              Expanded(
                                child: SearchableMultiSelect(
                                  label: 'Country',
                                  values: _selectedCountries,
                                  options: _countryOptions,
                                  hint: 'Select country',
                                  onChanged: (values) {
                                    setState(() => _selectedCountries = values);
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
                                        _selectedResidentialStatuses = values);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Occupation and Mother Tongue
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
                                    setState(
                                        () => _selectedMotherTongues = values);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Religion
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
                          const SizedBox(height: 24),
                          // Marital Status
                          _buildCheckboxGroup(
                            label: 'Marital Status',
                            selectedValues: _selectedMaritalStatuses,
                            options: lookupProvider.maritalStatuses,
                            onToggle: (value) {
                              setState(() {
                                if (_selectedMaritalStatuses.contains(value)) {
                                  _selectedMaritalStatuses.remove(value);
                                } else {
                                  _selectedMaritalStatuses.add(value);
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          // Caste and Education
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
                          const SizedBox(height: 24),
                          // Horoscope
                          SearchableMultiSelect(
                            label: 'Horoscope',
                            values: _selectedHoroscopes,
                            options: lookupProvider.horoscopes,
                            hint: 'Select horoscope',
                            onChanged: (values) {
                              setState(() => _selectedHoroscopes = values);
                            },
                          ),
                          const SizedBox(height: 24),
                          // Manglik (full width to avoid overflow)
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
              const SizedBox(height: 32),
                          // Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                onPressed: () => context.pop(),
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
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
