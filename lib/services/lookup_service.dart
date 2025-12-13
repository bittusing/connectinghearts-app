import 'api_client.dart';
import '../models/profile_models.dart';

class LookupService {
  final ApiClient _apiClient = ApiClient();

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
    if (_statesCache.containsKey(countryId)) {
      return _statesCache[countryId]!;
    }

    // Match webapp endpoint: GET /lookup/getStateLookup/{countryId}
    final response = await _apiClient.get<dynamic>(
      '/lookup/getStateLookup/$countryId',
    );

    // Handle response: array or { data: [...] }
    List<dynamic> statesList = [];
    if (response is List) {
      statesList = response;
    } else if (response is Map<String, dynamic>) {
      statesList = response['data'] ?? [];
    }

    final states =
        statesList.map((item) => LookupOption.fromJson(item)).toList();
    _statesCache[countryId] = states;
    return states;
  }

  Future<List<LookupOption>> fetchCities(String stateId) async {
    if (stateId.isEmpty) return [];
    if (_citiesCache.containsKey(stateId)) {
      return _citiesCache[stateId]!;
    }

    // Match webapp endpoint: GET /lookup/getCityLookup/{stateId}
    final response = await _apiClient.get<dynamic>(
      '/lookup/getCityLookup/$stateId',
    );

    // Handle response: array or { data: [...] }
    List<dynamic> citiesList = [];
    if (response is List) {
      citiesList = response;
    } else if (response is Map<String, dynamic>) {
      citiesList = response['data'] ?? [];
    }

    final cities =
        citiesList.map((item) => LookupOption.fromJson(item)).toList();
    _citiesCache[stateId] = cities;
    return cities;
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
}
