import 'package:flutter/foundation.dart';
import '../services/lookup_service.dart';
import '../models/profile_models.dart';

class LookupProvider with ChangeNotifier {
  final LookupService _lookupService = LookupService();
  
  Map<String, List<LookupOption>> _lookupData = {};
  List<LookupOption> _countries = [];
  bool _isLoading = false;
  String? _error;

  Map<String, List<LookupOption>> get lookupData => _lookupData;
  List<LookupOption> get countries => _countries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Convenience getters
  List<LookupOption> get religions => _lookupData['religion'] ?? [];
  List<LookupOption> get motherTongues => _lookupData['motherTongue'] ?? [];
  List<LookupOption> get maritalStatuses => _lookupData['maritalStatus'] ?? [];
  List<LookupOption> get castes => _lookupData['casts'] ?? [];
  List<LookupOption> get qualifications => _lookupData['qualification'] ?? [];
  List<LookupOption> get occupations => _lookupData['occupation'] ?? [];
  List<LookupOption> get ageOptions => _lookupData['age'] ?? [];
  List<LookupOption> get heightOptions => _lookupData['height'] ?? [];
  List<LookupOption> get incomeOptions => _lookupData['income'] ?? [];

  Future<void> loadLookupData() async {
    if (_lookupData.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lookupData = await _lookupService.fetchLookup();
      _countries = await _lookupService.fetchCountries();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<LookupOption>> getStates(String countryId) async {
    return await _lookupService.fetchStates(countryId);
  }

  Future<List<LookupOption>> getCities(String stateId) async {
    return await _lookupService.fetchCities(stateId);
  }

  String? getLabelFromValue(String lookupKey, dynamic value) {
    final options = _lookupData[lookupKey] ?? [];
    return _lookupService.getLabelFromValue(options, value);
  }

  String? getCountryLabel(dynamic value) {
    return _lookupService.getLabelFromValue(_countries, value);
  }

  void clearCache() {
    _lookupService.clearCache();
    _lookupData = {};
    _countries = [];
    notifyListeners();
  }
}

