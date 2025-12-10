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

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/lookup/getLookup',
    );
    
    final Map<String, List<LookupOption>> result = {};
    
    response.forEach((key, value) {
      if (value is List) {
        result[key] = value.map((item) => LookupOption.fromJson(item)).toList();
      }
    });
    
    _lookupCache = result;
    return result;
  }

  Future<List<LookupOption>> fetchCountries() async {
    if (_countriesCache != null) {
      return _countriesCache!;
    }

    final response = await _apiClient.get<List<dynamic>>(
      '/lookup/getCountries',
    );
    
    _countriesCache = response.map((item) => LookupOption.fromJson(item)).toList();
    return _countriesCache!;
  }

  Future<List<LookupOption>> fetchStates(String countryId) async {
    if (_statesCache.containsKey(countryId)) {
      return _statesCache[countryId]!;
    }

    final response = await _apiClient.get<List<dynamic>>(
      '/lookup/getStates/$countryId',
    );
    
    final states = response.map((item) => LookupOption.fromJson(item)).toList();
    _statesCache[countryId] = states;
    return states;
  }

  Future<List<LookupOption>> fetchCities(String stateId) async {
    if (_citiesCache.containsKey(stateId)) {
      return _citiesCache[stateId]!;
    }

    final response = await _apiClient.get<List<dynamic>>(
      '/lookup/getCities/$stateId',
    );
    
    final cities = response.map((item) => LookupOption.fromJson(item)).toList();
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

