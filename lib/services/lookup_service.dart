import 'api_client.dart';
import '../models/profile_models.dart';
import 'static_data_service.dart';

class LookupService {
  final ApiClient _apiClient = ApiClient();
  final StaticDataService _staticDataService = StaticDataService.instance;

  // Cache for lookup data
  Map<String, List<LookupOption>>? _lookupCache;
  List<LookupOption>? _countriesCache;
  final Map<String, List<LookupOption>> _statesCache = {};
  final Map<String, List<LookupOption>> _citiesCache = {};

  Future<Map<String, List<LookupOption>>> fetchLookup() async {
    if (_lookupCache != null) {
      return _lookupCache!;
    }

    // Match webapp endpoint: GET /lookup (returns { lookupData: {...} } or array)
    final response = await _apiClient.get<dynamic>(
      '/lookup',
    );

    final Map<String, List<LookupOption>> result = {};

    // Handle response structure: { lookupData: {...} } or array or direct object
    dynamic lookupData;
    if (response is Map<String, dynamic>) {
      lookupData = response['lookupData'] ?? response;
      if (lookupData is List) {
        lookupData = lookupData.isNotEmpty ? lookupData[0] : {};
      }
    } else if (response is List) {
      lookupData = response.isNotEmpty ? response[0] : {};
    } else {
      lookupData = response;
    }

    if (lookupData is Map<String, dynamic>) {
      lookupData.forEach((key, value) {
        if (value is List) {
          result[key] =
              value.map((item) => LookupOption.fromJson(item)).toList();
        }
      });
    }

    _lookupCache = result;
    return result;
  }

  Future<List<LookupOption>> fetchCountries() async {
    if (_countriesCache != null) {
      return _countriesCache!;
    }

    // Match webapp endpoint: GET /lookup/getCountryLookup
    final response = await _apiClient.get<dynamic>(
      '/lookup/getCountryLookup',
    );

    // Handle response: array or { data: [...] } or { countryLookup: [...] }
    List<dynamic> countriesList = [];
    if (response is List) {
      countriesList = response;
    } else if (response is Map<String, dynamic>) {
      countriesList = response['data'] ??
          response['countryLookup'] ??
          response['countries'] ??
          [];
    }

    _countriesCache =
        countriesList.map((item) => LookupOption.fromJson(item)).toList();
    return _countriesCache!;
  }

  Future<List<LookupOption>> fetchStates(String countryId) async {
    if (countryId.isEmpty) return [];

    // First check cache
    if (_statesCache.containsKey(countryId)) {
      return _statesCache[countryId]!;
    }

    // Try to load from static data first (no API call)
    await _staticDataService.loadStatesData();
    if (_staticDataService.isStatesLoaded) {
      final staticStates = _staticDataService.getStatesByCountry(countryId);
      if (staticStates.isNotEmpty) {
        _statesCache[countryId] = staticStates;
        return staticStates;
      }
    }

    // Fallback to API if static data doesn't have this country
    // Match webapp endpoint: GET /lookup/getStateLookup/{countryId}
    // Response structure: [{ country_id: "...", states: [{ label, value }, ...] }]
    try {
      final response = await _apiClient.get<dynamic>(
        '/lookup/getStateLookup/$countryId',
      );

      // Handle response structure: [{ country_id: "...", states: [...] }]
      List<dynamic> statesList = [];
      if (response is List && response.isNotEmpty) {
        final firstItem = response[0];
        if (firstItem is Map<String, dynamic> && firstItem['states'] != null) {
          statesList = firstItem['states'] as List<dynamic>;
        }
      } else if (response is Map<String, dynamic>) {
        if (response['states'] != null) {
          statesList = response['states'] as List<dynamic>;
        } else if (response['data'] != null) {
          statesList = response['data'] as List<dynamic>;
        }
      }

      final states =
          statesList.map((item) => LookupOption.fromJson(item)).toList();
      _statesCache[countryId] = states;
      return states;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  Future<List<LookupOption>> fetchCities(String stateId) async {
    if (stateId.isEmpty) return [];

    // First check cache
    if (_citiesCache.containsKey(stateId)) {
      return _citiesCache[stateId]!;
    }

    // Try to load from static data first (no API call)
    await _staticDataService.loadCitiesData();
    if (_staticDataService.isCitiesLoaded) {
      final staticCities = _staticDataService.getCitiesByState(stateId);
      if (staticCities.isNotEmpty) {
        _citiesCache[stateId] = staticCities;
        return staticCities;
      }
    }

    // Fallback to API if static data doesn't have this state
    // Match webapp endpoint: GET /lookup/getCityLookup/{stateId}
    // Response structure: [{ state_id: "...", cities: [{ label, value, _id }, ...] }]
    try {
      final response = await _apiClient.get<dynamic>(
        '/lookup/getCityLookup/$stateId',
      );

      // Handle response structure: [{ state_id: "...", cities: [...] }]
      List<dynamic> citiesList = [];
      if (response is List && response.isNotEmpty) {
        final firstItem = response[0];
        if (firstItem is Map<String, dynamic> && firstItem['cities'] != null) {
          citiesList = firstItem['cities'] as List<dynamic>;
        }
      } else if (response is Map<String, dynamic>) {
        if (response['cities'] != null) {
          citiesList = response['cities'] as List<dynamic>;
        } else if (response['data'] != null) {
          citiesList = response['data'] as List<dynamic>;
        }
      }

      final cities =
          citiesList.map((item) => LookupOption.fromJson(item)).toList();
      _citiesCache[stateId] = cities;
      return cities;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  // Get specific lookup options
  Future<List<LookupOption>> getReligions() async {
    final lookup = await fetchLookup();
    return lookup['religion'] ?? [];
  }

  Future<List<LookupOption>> getMotherTongues() async {
    final lookup = await fetchLookup();
    return lookup['motherTongue'] ?? [];
  }

  Future<List<LookupOption>> getMaritalStatuses() async {
    final lookup = await fetchLookup();
    return lookup['maritalStatus'] ?? [];
  }

  Future<List<LookupOption>> getCastes() async {
    final lookup = await fetchLookup();
    return lookup['casts'] ?? [];
  }

  Future<List<LookupOption>> getQualifications() async {
    final lookup = await fetchLookup();
    return lookup['qualification'] ?? [];
  }

  Future<List<LookupOption>> getOccupations() async {
    final lookup = await fetchLookup();
    return lookup['occupation'] ?? [];
  }

  Future<List<LookupOption>> getAgeOptions() async {
    final lookup = await fetchLookup();
    return lookup['age'] ?? [];
  }

  Future<List<LookupOption>> getHeightOptions() async {
    final lookup = await fetchLookup();
    return lookup['height'] ?? [];
  }

  Future<List<LookupOption>> getIncomeOptions() async {
    final lookup = await fetchLookup();
    return lookup['income'] ?? [];
  }

  // Clear cache
  void clearCache() {
    _lookupCache = null;
    _countriesCache = null;
    _statesCache.clear();
    _citiesCache.clear();
  }

  // Get label from value
  String? getLabelFromValue(List<LookupOption> options, dynamic value) {
    if (value == null) return null;
    final stringValue = value.toString();
    try {
      final option = options.firstWhere(
        (opt) => opt.value.toString() == stringValue,
      );
      return option.label;
    } catch (_) {
      return null;
    }
  }

  /// Get city label from value using static data (fast, no API call)
  Future<String?> getCityLabelFromValue(String? cityValue) async {
    if (cityValue == null || cityValue.isEmpty) return null;

    // Load static data if not loaded
    await _staticDataService.loadCitiesData();

    // Get from static data
    return _staticDataService.getCityLabel(cityValue);
  }

  /// Get city value from label using static data (fast, no API call)
  Future<String?> getCityValueFromLabel(String? cityLabel) async {
    if (cityLabel == null || cityLabel.isEmpty) return null;

    // Load static data if not loaded
    await _staticDataService.loadCitiesData();

    // Get from static data
    return _staticDataService.getCityValue(cityLabel);
  }
}
