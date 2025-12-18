import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/profile_models.dart';

/// Static data service for managing cities, states, and countries data
/// Loads data from JSON file to avoid API calls
class StaticDataService {
  static StaticDataService? _instance;
  static StaticDataService get instance {
    _instance ??= StaticDataService._();
    return _instance!;
  }

  StaticDataService._();

  // Cache for loaded data
  Map<String, List<LookupOption>>? _citiesByStateCache;
  Map<String, String>? _cityValueToLabelCache;
  Map<String, String>? _cityLabelToValueCache;

  List<LookupOption>? _countriesCache;
  Map<String, String>? _countryValueToLabelCache;
  Map<String, String>? _countryLabelToValueCache;

  Map<String, List<LookupOption>>? _statesByCountryCache;
  Map<String, String>? _stateValueToLabelCache;
  Map<String, String>? _stateLabelToValueCache;

  Map<String, String>? _castValueToLabelCache;
  bool _isLookupsLoaded = false;

  bool _isLoading = false;
  bool _isCitiesLoaded = false;
  bool _isCountriesLoaded = false;
  bool _isStatesLoaded = false;

  /// Load all static data (cities, states, countries, lookups) from JSON files
  Future<void> loadAllData() async {
    await Future.wait([
      loadCitiesData(),
      loadCountriesData(),
      loadStatesData(),
      loadLookupsData(),
    ]);
  }

  /// Load cities data from JSON file
  Future<void> loadCitiesData() async {
    if (_isCitiesLoaded || _isLoading) return;

    _isLoading = true;
    try {
      // Load JSON file from assets
      final String jsonString = await rootBundle.loadString(
        'assets/data/connectinghearts.cities.json',
      );

      final List<dynamic> jsonData = json.decode(jsonString);

      // Build lookup maps
      final Map<String, List<LookupOption>> citiesByState = {};
      final Map<String, String> cityValueToLabel = {};
      final Map<String, String> cityLabelToValue = {};

      for (final item in jsonData) {
        if (item is Map<String, dynamic>) {
          final stateId = item['state_id']?.toString();
          final cities = item['cities'] as List<dynamic>?;

          if (stateId != null && cities != null) {
            final cityOptions = cities
                .map((city) {
                  if (city is Map<String, dynamic>) {
                    final label = city['label']?.toString() ?? '';
                    final value = city['value']?.toString() ?? '';

                    // Build lookup maps
                    if (value.isNotEmpty && label.isNotEmpty) {
                      cityValueToLabel[value] = label;
                      cityLabelToValue[label] = value;
                    }

                    return LookupOption(label: label, value: value);
                  }
                  return null;
                })
                .whereType<LookupOption>()
                .toList();

            // Group cities by state_id
            if (citiesByState.containsKey(stateId)) {
              citiesByState[stateId]!.addAll(cityOptions);
            } else {
              citiesByState[stateId] = cityOptions;
            }
          }
        }
      }

      _citiesByStateCache = citiesByState;
      _cityValueToLabelCache = cityValueToLabel;
      _cityLabelToValueCache = cityLabelToValue;
      _isCitiesLoaded = true;
    } catch (e) {
      // Handle error - file might not be loaded yet
      print('Error loading cities data: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Load countries data from JSON file
  Future<void> loadCountriesData() async {
    if (_isCountriesLoaded || _isLoading) return;

    _isLoading = true;
    try {
      // Load JSON file from assets
      final String jsonString = await rootBundle.loadString(
        'assets/data/connectinghearts.countries.json',
      );

      final List<dynamic> jsonData = json.decode(jsonString);

      // Build lookup maps
      final List<LookupOption> countries = [];
      final Map<String, String> countryValueToLabel = {};
      final Map<String, String> countryLabelToValue = {};

      for (final item in jsonData) {
        if (item is Map<String, dynamic>) {
          final label = item['label']?.toString() ?? '';
          final value = item['value']?.toString() ?? '';

          if (value.isNotEmpty && label.isNotEmpty) {
            countryValueToLabel[value] = label;
            countryLabelToValue[label] = value;
            countries.add(LookupOption(label: label, value: value));
          }
        }
      }

      _countriesCache = countries;
      _countryValueToLabelCache = countryValueToLabel;
      _countryLabelToValueCache = countryLabelToValue;
      _isCountriesLoaded = true;
    } catch (e) {
      print('Error loading countries data: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Load states data from JSON file
  Future<void> loadStatesData() async {
    if (_isStatesLoaded || _isLoading) return;

    _isLoading = true;
    try {
      // Load JSON file from assets
      final String jsonString = await rootBundle.loadString(
        'assets/data/connectinghearts.states.json',
      );

      final List<dynamic> jsonData = json.decode(jsonString);

      // Build lookup maps
      final Map<String, List<LookupOption>> statesByCountry = {};
      final Map<String, String> stateValueToLabel = {};
      final Map<String, String> stateLabelToValue = {};

      for (final item in jsonData) {
        if (item is Map<String, dynamic>) {
          final countryId = item['country_id']?.toString();
          final states = item['states'] as List<dynamic>?;

          if (countryId != null && states != null) {
            final stateOptions = states
                .map((state) {
                  if (state is Map<String, dynamic>) {
                    final label = state['label']?.toString() ?? '';
                    final value = state['value']?.toString() ?? '';

                    // Build lookup maps
                    if (value.isNotEmpty && label.isNotEmpty) {
                      stateValueToLabel[value] = label;
                      stateLabelToValue[label] = value;
                    }

                    return LookupOption(label: label, value: value);
                  }
                  return null;
                })
                .whereType<LookupOption>()
                .toList();

            // Group states by country_id
            if (statesByCountry.containsKey(countryId)) {
              statesByCountry[countryId]!.addAll(stateOptions);
            } else {
              statesByCountry[countryId] = stateOptions;
            }
          }
        }
      }

      _statesByCountryCache = statesByCountry;
      _stateValueToLabelCache = stateValueToLabel;
      _stateLabelToValueCache = stateLabelToValue;
      _isStatesLoaded = true;
    } catch (e) {
      print('Error loading states data: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Load lookups data from JSON file (for casts and other lookup data)
  Future<void> loadLookupsData() async {
    if (_isLookupsLoaded || _isLoading) return;

    _isLoading = true;
    try {
      // Load JSON file from assets
      final String jsonString = await rootBundle.loadString(
        'assets/data/connectinghearts.lookups.json',
      );

      final List<dynamic> jsonData = json.decode(jsonString);

      // Build cast lookup map
      final Map<String, String> castValueToLabel = {};

      // The JSON is an array, get first item which contains all lookup data
      if (jsonData.isNotEmpty && jsonData[0] is Map<String, dynamic>) {
        final lookupData = jsonData[0] as Map<String, dynamic>;
        final casts = lookupData['casts'] as List<dynamic>?;

        if (casts != null) {
          for (final castItem in casts) {
            if (castItem is Map<String, dynamic>) {
              final label = castItem['label']?.toString() ?? '';
              final value = castItem['value']?.toString() ?? '';

              if (value.isNotEmpty && label.isNotEmpty) {
                castValueToLabel[value] = label;
              }
            }
          }
        }
      }

      _castValueToLabelCache = castValueToLabel;
      _isLookupsLoaded = true;
    } catch (e) {
      print('Error loading lookups data: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Get cities for a specific state_id
  List<LookupOption> getCitiesByState(String stateId) {
    if (!_isCitiesLoaded) {
      return [];
    }
    return _citiesByStateCache?[stateId] ?? [];
  }

  /// Get city label from value
  String? getCityLabel(String? cityValue) {
    if (cityValue == null || !_isCitiesLoaded) return null;
    return _cityValueToLabelCache?[cityValue];
  }

  /// Get city value from label
  String? getCityValue(String? cityLabel) {
    if (cityLabel == null || !_isCitiesLoaded) return null;
    return _cityLabelToValueCache?[cityLabel];
  }

  /// Get all countries
  List<LookupOption> getCountries() {
    if (!_isCountriesLoaded) return [];
    return _countriesCache ?? [];
  }

  /// Get country label from value
  String? getCountryLabel(String? countryValue) {
    if (countryValue == null || countryValue.isEmpty || !_isCountriesLoaded)
      return null;

    // Normalize value (trim whitespace)
    final normalizedValue = countryValue.trim();

    // Try exact match first
    final label = _countryValueToLabelCache?[normalizedValue];
    if (label != null && label.isNotEmpty) return label;

    // Try case-insensitive match
    if (_countryValueToLabelCache != null) {
      for (final entry in _countryValueToLabelCache!.entries) {
        if (entry.key.trim().toLowerCase() == normalizedValue.toLowerCase()) {
          return entry.value;
        }
      }
    }
    return null;
  }

  /// Get country value from label
  String? getCountryValue(String? countryLabel) {
    if (countryLabel == null || !_isCountriesLoaded) return null;
    return _countryLabelToValueCache?[countryLabel];
  }

  /// Get states for a specific country_id
  List<LookupOption> getStatesByCountry(String countryId) {
    if (!_isStatesLoaded) {
      return [];
    }
    return _statesByCountryCache?[countryId] ?? [];
  }

  /// Get state label from value
  String? getStateLabel(String? stateValue) {
    if (stateValue == null || stateValue.isEmpty || !_isStatesLoaded)
      return null;

    // Normalize value (trim whitespace)
    final normalizedValue = stateValue.trim();

    // Try exact match first
    final label = _stateValueToLabelCache?[normalizedValue];
    if (label != null && label.isNotEmpty) return label;

    // Try case-insensitive match
    if (_stateValueToLabelCache != null) {
      for (final entry in _stateValueToLabelCache!.entries) {
        if (entry.key.trim().toLowerCase() == normalizedValue.toLowerCase()) {
          return entry.value;
        }
      }
    }
    return null;
  }

  /// Get state value from label
  String? getStateValue(String? stateLabel) {
    if (stateLabel == null || !_isStatesLoaded) return null;
    return _stateLabelToValueCache?[stateLabel];
  }

  /// Get cast label from value
  String? getCastLabel(String? castValue) {
    if (castValue == null || castValue.isEmpty || !_isLookupsLoaded)
      return null;

    // Normalize value (trim whitespace)
    final normalizedValue = castValue.trim();

    // Try exact match first
    final label = _castValueToLabelCache?[normalizedValue];
    if (label != null && label.isNotEmpty) return label;

    // Try case-insensitive match
    if (_castValueToLabelCache != null) {
      for (final entry in _castValueToLabelCache!.entries) {
        if (entry.key.trim().toLowerCase() == normalizedValue.toLowerCase()) {
          return entry.value;
        }
      }
    }
    return null;
  }

  /// Check if all data is loaded
  bool get isLoaded =>
      _isCitiesLoaded &&
      _isCountriesLoaded &&
      _isStatesLoaded &&
      _isLookupsLoaded;

  /// Check if cities data is loaded
  bool get isCitiesLoaded => _isCitiesLoaded;

  /// Check if countries data is loaded
  bool get isCountriesLoaded => _isCountriesLoaded;

  /// Check if states data is loaded
  bool get isStatesLoaded => _isStatesLoaded;

  /// Check if lookups data is loaded
  bool get isLookupsLoaded => _isLookupsLoaded;

  /// Clear cache (useful for testing or reloading)
  void clearCache() {
    _citiesByStateCache = null;
    _cityValueToLabelCache = null;
    _cityLabelToValueCache = null;
    _countriesCache = null;
    _countryValueToLabelCache = null;
    _countryLabelToValueCache = null;
    _statesByCountryCache = null;
    _stateValueToLabelCache = null;
    _stateLabelToValueCache = null;
    _castValueToLabelCache = null;
    _isCitiesLoaded = false;
    _isCountriesLoaded = false;
    _isStatesLoaded = false;
    _isLookupsLoaded = false;
    _isLoading = false;
  }

  /// Get all state IDs that have cities
  List<String> getAllStateIds() {
    if (!_isCitiesLoaded) return [];
    return _citiesByStateCache?.keys.toList() ?? [];
  }

  /// Get all country IDs that have states
  List<String> getAllCountryIds() {
    if (!_isStatesLoaded) return [];
    return _statesByCountryCache?.keys.toList() ?? [];
  }

  /// Get total number of cities
  int getTotalCitiesCount() {
    if (!_isCitiesLoaded) return 0;
    return _cityValueToLabelCache?.length ?? 0;
  }

  /// Get total number of countries
  int getTotalCountriesCount() {
    if (!_isCountriesLoaded) return 0;
    return _countriesCache?.length ?? 0;
  }

  /// Get total number of states
  int getTotalStatesCount() {
    if (!_isStatesLoaded) return 0;
    return _stateValueToLabelCache?.length ?? 0;
  }
}

