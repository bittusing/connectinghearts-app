import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../providers/lookup_provider.dart';
import '../../services/profile_service.dart';
import '../../models/profile_models.dart';
import '../../widgets/common/searchable_dropdown.dart';
import '../../widgets/common/searchable_multi_select.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ProfileService _profileService = ProfileService();
  final _profileIdController = TextEditingController();

  bool _isSearchingById = false;
  String? _profileIdError;
  String? _advancedError;

  // Filter values
  String? _selectedCountry;
  String? _selectedState;
  List<String> _selectedCities = [];
  List<String> _selectedReligions = [];
  List<String> _selectedMotherTongues = [];
  List<String> _selectedMaritalStatuses = [];
  String? _minAge;
  String? _maxAge;
  String? _minHeight;
  String? _maxHeight;
  String? _minIncome;
  String? _maxIncome;

  List<LookupOption> _states = [];
  List<LookupOption> _cities = [];
  bool _loadingStates = false;
  bool _loadingCities = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LookupProvider>(context, listen: false).loadLookupData();
    });
  }

  @override
  void dispose() {
    _profileIdController.dispose();
    super.dispose();
  }

  Future<void> _searchByProfileId() async {
    final profileId =
        _profileIdController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (profileId.isEmpty) {
      setState(
          () => _profileIdError = 'Please enter a valid HEARTS ID number.');
      return;
    }

    setState(() {
      _profileIdError = null;
      _isSearchingById = true;
    });

    try {
      final response = await _profileService.searchByProfileId(profileId);
      final clientId = response['filteredProfile']?['clientID'];

      if (response['status'] == 'success' && clientId != null) {
        if (mounted) {
          context.push('/profile/$clientId');
        }
      } else {
        setState(() =>
            _profileIdError = response['message'] ?? 'Profile not found.');
      }
    } catch (e) {
      setState(() => _profileIdError = e.toString());
    } finally {
      setState(() => _isSearchingById = false);
    }
  }

  Future<void> _loadStates(String countryId) async {
    setState(() {
      _loadingStates = true;
      _selectedState = null;
      _selectedCities = [];
      _states = [];
      _cities = [];
    });

    try {
      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);
      final states = await lookupProvider.getStates(countryId);
      setState(() {
        _states = states;
        _loadingStates = false;
      });
    } catch (e) {
      setState(() => _loadingStates = false);
    }
  }

  Future<void> _loadCities(String stateId) async {
    setState(() {
      _loadingCities = true;
      _selectedCities = [];
      _cities = [];
    });

    try {
      final lookupProvider =
          Provider.of<LookupProvider>(context, listen: false);
      final cities = await lookupProvider.getCities(stateId);
      setState(() {
        _cities = cities;
        _loadingCities = false;
      });
    } catch (e) {
      setState(() => _loadingCities = false);
    }
  }

  void _handleAdvancedSearch() {
    final lookupProvider = Provider.of<LookupProvider>(context, listen: false);
    final payload = ProfileSearchPayload();

    if (_selectedCountry != null) {
      payload.country = [_selectedCountry!];
    }
    if (_selectedState != null) {
      payload.state = [_selectedState!];
    }
    if (_selectedCities.isNotEmpty) {
      payload.city = _selectedCities;
    }
    if (_selectedReligions.isNotEmpty) {
      payload.religion = _selectedReligions;
    }
    if (_selectedMotherTongues.isNotEmpty) {
      payload.motherTongue = _selectedMotherTongues;
    }
    if (_selectedMaritalStatuses.isNotEmpty) {
      payload.maritalStatus = _selectedMaritalStatuses;
    }

    // Helper to convert lookup option value to int
    int? getOptionValueAsInt(
        String? selectedValue, List<LookupOption> options) {
      if (selectedValue == null) return null;
      try {
        final option = options.firstWhere(
          (opt) => opt.value?.toString() == selectedValue,
        );
        if (option.value == null) return null;
        if (option.value is int) return option.value as int;
        if (option.value is num) return (option.value as num).toInt();
        return int.tryParse(option.value.toString());
      } catch (_) {
        // Fallback: try parsing the selectedValue directly
        return int.tryParse(selectedValue);
      }
    }

    // Convert age, height, income values to numbers (matching webapp)
    if (_minAge != null || _maxAge != null) {
      final minAge = getOptionValueAsInt(_minAge, lookupProvider.ageOptions);
      final maxAge = getOptionValueAsInt(_maxAge, lookupProvider.ageOptions);
      if (minAge != null || maxAge != null) {
        payload.age = {
          if (minAge != null) 'min': minAge,
          if (maxAge != null) 'max': maxAge,
        };
      }
    }
    if (_minHeight != null || _maxHeight != null) {
      final minHeight =
          getOptionValueAsInt(_minHeight, lookupProvider.heightOptions);
      final maxHeight =
          getOptionValueAsInt(_maxHeight, lookupProvider.heightOptions);
      if (minHeight != null || maxHeight != null) {
        payload.height = {
          if (minHeight != null) 'min': minHeight,
          if (maxHeight != null) 'max': maxHeight,
        };
      }
    }
    if (_minIncome != null || _maxIncome != null) {
      final minIncome =
          getOptionValueAsInt(_minIncome, lookupProvider.incomeOptions);
      final maxIncome =
          getOptionValueAsInt(_maxIncome, lookupProvider.incomeOptions);
      if (minIncome != null || maxIncome != null) {
        payload.income = {
          if (minIncome != null) 'min': minIncome,
          if (maxIncome != null) 'max': maxIncome,
        };
      }
    }

    if (!payload.hasFilters) {
      setState(() =>
          _advancedError = 'Select at least one filter before searching.');
      return;
    }

    setState(() => _advancedError = null);
    context.push('/search-results', extra: payload);
  }

  void _clearFilters() {
    setState(() {
      _selectedCountry = null;
      _selectedState = null;
      _selectedCities = [];
      _selectedReligions = [];
      _selectedMotherTongues = [];
      _selectedMaritalStatuses = [];
      _minAge = null;
      _maxAge = null;
      _minHeight = null;
      _maxHeight = null;
      _minIncome = null;
      _maxIncome = null;
      _states = [];
      _cities = [];
      _advancedError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lookupProvider = Provider.of<LookupProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Search Profiles')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Profiles',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search by Hearts ID or use advanced filters to find the right match.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search by Profile ID
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search By Profile ID',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter a HEARTS ID to jump directly to a profile.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          'HEARTS-',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _profileIdController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color ??
                                Colors.black87,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: '123456',
                            border: OutlineInputBorder(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              borderSide: BorderSide(color: theme.dividerColor),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_profileIdError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _profileIdError!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSearchingById ? null : _searchByProfileId,
                      child: _isSearchingById
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Search'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Advanced Search
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Advanced Search',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Combine multiple filters to narrow down your results.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  if (lookupProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    // Country
                    SearchableDropdown(
                      label: 'Country',
                      value: _selectedCountry,
                      options: lookupProvider.countries,
                      hint: 'Select country',
                      onChanged: (value) {
                        setState(() {
                          _selectedCountry = value;
                          // Reset state and city when country changes
                          if (value != null) {
                            _loadStates(value);
                          } else {
                            _selectedState = null;
                            _selectedCities = [];
                            _states = [];
                            _cities = [];
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // State
                    SearchableDropdown(
                      label: 'State',
                      value: _selectedState,
                      options: _states,
                      enabled: _selectedCountry != null && !_loadingStates,
                      hint: _selectedCountry == null
                          ? 'Select country first'
                          : _loadingStates
                              ? 'Loading...'
                              : 'Select state',
                      onChanged: (value) {
                        setState(() {
                          _selectedState = value;
                          if (value != null) {
                            _loadCities(value);
                          } else {
                            _selectedCities = [];
                            _cities = [];
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // City (Multi-select)
                    SearchableMultiSelect(
                      label: 'City',
                      values: _selectedCities,
                      options: _cities,
                      enabled: _selectedState != null && !_loadingCities,
                      hint: _selectedState == null
                          ? 'Select state first'
                          : _loadingCities
                              ? 'Loading...'
                              : 'Select cities',
                      onChanged: (values) {
                        setState(() => _selectedCities = values);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Religion
                    _buildMultiSelectChips(
                      label: 'Religion',
                      options: lookupProvider.religions,
                      selectedValues: _selectedReligions,
                      onChanged: (values) =>
                          setState(() => _selectedReligions = values),
                    ),
                    const SizedBox(height: 16),
                    // Mother Tongue
                    _buildMultiSelectChips(
                      label: 'Mother Tongue',
                      options: lookupProvider.motherTongues,
                      selectedValues: _selectedMotherTongues,
                      onChanged: (values) =>
                          setState(() => _selectedMotherTongues = values),
                    ),
                    const SizedBox(height: 16),
                    // Marital Status
                    _buildMultiSelectChips(
                      label: 'Marital Status',
                      options: lookupProvider.maritalStatuses,
                      selectedValues: _selectedMaritalStatuses,
                      onChanged: (values) =>
                          setState(() => _selectedMaritalStatuses = values),
                    ),
                    const SizedBox(height: 16),
                    // Age Range
                    Row(
                      children: [
                        Expanded(
                          child: SearchableDropdown(
                            label: 'Min Age',
                            value: _minAge,
                            options: lookupProvider.ageOptions,
                            hint: 'Select Min Age',
                            onChanged: (value) =>
                                setState(() => _minAge = value),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SearchableDropdown(
                            label: 'Max Age',
                            value: _maxAge,
                            options: lookupProvider.ageOptions,
                            hint: 'Select Max Age',
                            onChanged: (value) =>
                                setState(() => _maxAge = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Height Range
                    Row(
                      children: [
                        Expanded(
                          child: SearchableDropdown(
                            label: 'Min Height',
                            value: _minHeight,
                            options: lookupProvider.heightOptions,
                            hint: 'Select Min Height',
                            onChanged: (value) =>
                                setState(() => _minHeight = value),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SearchableDropdown(
                            label: 'Max Height',
                            value: _maxHeight,
                            options: lookupProvider.heightOptions,
                            hint: 'Select Max Height',
                            onChanged: (value) =>
                                setState(() => _maxHeight = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Income Range
                    Row(
                      children: [
                        Expanded(
                          child: SearchableDropdown(
                            label: 'Min Income',
                            value: _minIncome,
                            options: lookupProvider.incomeOptions,
                            hint: 'Select Min Income',
                            onChanged: (value) =>
                                setState(() => _minIncome = value),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SearchableDropdown(
                            label: 'Max Income',
                            value: _maxIncome,
                            options: lookupProvider.incomeOptions,
                            hint: 'Select Max Income',
                            onChanged: (value) =>
                                setState(() => _maxIncome = value),
                          ),
                        ),
                      ],
                    ),
                    if (_advancedError != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _advancedError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear All'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleAdvancedSearch,
                            child: const Text('Search'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectChips({
    required String label,
    required List<LookupOption> options,
    required List<String> selectedValues,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.take(10).map((option) {
            final isSelected = selectedValues.contains(option.value.toString());
            return FilterChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (selected) {
                final newValues = List<String>.from(selectedValues);
                if (selected) {
                  newValues.add(option.value.toString());
                } else {
                  newValues.remove(option.value.toString());
                }
                onChanged(newValues);
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }
}
