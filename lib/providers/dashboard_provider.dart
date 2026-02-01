import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../services/static_data_service.dart';
import '../models/profile_models.dart';
import '../utils/profile_utils.dart';

class DashboardProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final StorageService _storageService = StorageService();

  // Dashboard data
  int _acceptanceCount = 0;
  int _justJoinedCount = 0;
  List<Map<String, dynamic>> _interestReceived = [];
  List<Map<String, dynamic>> _dailyRecommendations = [];
  List<Map<String, dynamic>> _profileVisitors = [];
  List<Map<String, dynamic>> _allProfiles = [];

  bool _isLoading = true; // Start with true so loader shows immediately
  bool _hasLoadedOnce = false;
  DateTime? _lastRefreshTime;

  // Getters
  int get acceptanceCount => _acceptanceCount;
  int get justJoinedCount => _justJoinedCount;
  List<Map<String, dynamic>> get interestReceived => _interestReceived;
  List<Map<String, dynamic>> get dailyRecommendations => _dailyRecommendations;
  List<Map<String, dynamic>> get profileVisitors => _profileVisitors;
  List<Map<String, dynamic>> get allProfiles => _allProfiles;
  bool get isLoading => _isLoading;
  bool get hasData => _interestReceived.isNotEmpty || 
                      _dailyRecommendations.isNotEmpty || 
                      _profileVisitors.isNotEmpty || 
                      _allProfiles.isNotEmpty;

  // Load dashboard data
  // lookupData and countries should be passed from LookupProvider
  Future<void> loadDashboard({
    bool forceRefresh = false,
    Map<String, List<LookupOption>>? lookupData,
    List<LookupOption>? countries,
  }) async {
    // If already loaded and not force refresh, skip
    if (_hasLoadedOnce && !forceRefresh) {
      print('📦 Dashboard: Using cached data');
      return;
    }

    // If refreshed recently (within 30 seconds), skip
    if (!forceRefresh && _lastRefreshTime != null) {
      final timeSinceRefresh = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceRefresh.inSeconds < 30) {
        print('⏭️ Dashboard: Skipping refresh (refreshed ${timeSinceRefresh.inSeconds}s ago)');
        return;
      }
    }

    // First, try to load from cache
    if (!_hasLoadedOnce) {
      await _loadFromCache();
    }

    // Then fetch fresh data (only if lookupData and countries are provided)
    if (lookupData != null && countries != null) {
      await _fetchFreshData(lookupData, countries);
    }
  }

  // NEW: Load cache only (instant, non-blocking)
  Future<void> loadFromCacheOnly() async {
    await _loadFromCache();
  }

  // NEW: Load fresh data in background (non-blocking)
  Future<void> loadFreshDataInBackground({
    Map<String, List<LookupOption>>? lookupData,
    List<LookupOption>? countries,
  }) async {
    if (lookupData != null && countries != null) {
      // Don't set loading state if we already have cached data
      final hadData = hasData;
      if (!hadData) {
        _isLoading = true;
        notifyListeners();
      }
      
      await _fetchFreshData(lookupData, countries);
      
      if (!hadData) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Load from cache
  Future<void> _loadFromCache() async {
    try {
      final cachedData = await _storageService.getDashboardCache();
      if (cachedData != null) {
        // Check cache expiry (1 hour = 3600 seconds)
        final timestamp = cachedData['timestamp'] as String?;
        Duration? cacheAge;
        
        if (timestamp != null) {
          final cacheTime = DateTime.parse(timestamp);
          final now = DateTime.now();
          cacheAge = now.difference(cacheTime);
          
          // If cache is older than 1 hour, delete it and skip loading
          if (cacheAge.inSeconds > 3600) {
            print('🗑️ Dashboard: Cache expired (${cacheAge.inHours}h ${cacheAge.inMinutes % 60}m old), deleting...');
            await _storageService.deleteDashboardCache();
            return;
          }
        }
        
        _acceptanceCount = cachedData['acceptanceCount'] ?? 0;
        _justJoinedCount = cachedData['justJoinedCount'] ?? 0;
        _interestReceived = List<Map<String, dynamic>>.from(
          cachedData['interestReceived'] ?? [],
        );
        _dailyRecommendations = List<Map<String, dynamic>>.from(
          cachedData['dailyRecommendations'] ?? [],
        );
        _profileVisitors = List<Map<String, dynamic>>.from(
          cachedData['profileVisitors'] ?? [],
        );
        _allProfiles = List<Map<String, dynamic>>.from(
          cachedData['allProfiles'] ?? [],
        );
        _hasLoadedOnce = true;
        _isLoading = false; // Stop loading after cache is loaded
        notifyListeners();
        
        // Log cache age if available
        if (cacheAge != null) {
          print('✅ Dashboard: Loaded from cache (${cacheAge.inMinutes}m old)');
        } else {
          print('✅ Dashboard: Loaded from cache');
        }
      }
    } catch (e) {
      print('❌ Dashboard: Cache load failed: $e');
    }
  }

  // Fetch fresh data from API - FULLY PARALLEL like webapp
  Future<void> _fetchFreshData(
    Map<String, List<LookupOption>> lookupData,
    List<LookupOption> countries,
  ) async {
    try {
      // Load static data ONCE at the start (not multiple times)
      final staticDataService = StaticDataService.instance;
      if (!staticDataService.isLoaded) {
        await staticDataService.loadAllData();
      }
      
      print('🔍 Static Data Status: Cities=${staticDataService.isCitiesLoaded}, States=${staticDataService.isStatesLoaded}, Countries=${staticDataService.isCountriesLoaded}');

      // FULLY PARALLEL LOADING - All 6 API calls at once (like webapp Promise.all)
      final results = await Future.wait([
        _profileService.getProfilesByEndpoint('dashboard/getAcceptanceProfiles/acceptedMe'),
        _profileService.getJustJoinedProfiles(),
        _profileService.getInterestsReceived(),
        _profileService.getDailyRecommendations(),
        _profileService.getProfileVisitors(),
        _profileService.getAllProfiles(),
      ]);

      // Extract and transform all results at once
      _acceptanceCount = results[0].data.length;
      _justJoinedCount = results[1].data.length;
      
      _interestReceived = results[2].data
          .take(5)
          .map((p) => transformProfile(p, lookupData: lookupData, countries: countries))
          .toList();
      
      _dailyRecommendations = results[3].data
          .take(5)
          .map((p) => transformProfile(p, lookupData: lookupData, countries: countries))
          .toList();
      
      _profileVisitors = results[4].data
          .take(5)
          .map((p) => transformProfile(p, lookupData: lookupData, countries: countries))
          .toList();
      
      _allProfiles = results[5].data
          .take(5)
          .map((p) => transformProfile(p, lookupData: lookupData, countries: countries))
          .toList();

      // Log sample to verify
      if (_interestReceived.isNotEmpty) {
        print('📍 Sample location: ${_interestReceived.first['location']}');
      }

      _hasLoadedOnce = true;
      _lastRefreshTime = DateTime.now();

      // Save to cache (async, non-blocking)
      _saveToCache();

      print('✅ Dashboard: All data loaded in parallel (Promise.all style)');
    } catch (e) {
      print('❌ Dashboard: Fetch failed: $e');
    } finally {
      notifyListeners();
    }
  }

  // Save to cache
  Future<void> _saveToCache() async {
    try {
      final cacheData = {
        'acceptanceCount': _acceptanceCount,
        'justJoinedCount': _justJoinedCount,
        'interestReceived': _interestReceived,
        'dailyRecommendations': _dailyRecommendations,
        'profileVisitors': _profileVisitors,
        'allProfiles': _allProfiles,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _storageService.setDashboardCache(cacheData);
      print('💾 Dashboard: Saved to cache');
    } catch (e) {
      print('❌ Dashboard: Cache save failed: $e');
    }
  }

  // Force refresh
  Future<void> refresh({
    Map<String, List<LookupOption>>? lookupData,
    List<LookupOption>? countries,
  }) async {
    await loadDashboard(
      forceRefresh: true,
      lookupData: lookupData,
      countries: countries,
    );
  }

  // Clear cache
  Future<void> clearCache() async {
    await _storageService.deleteDashboardCache();
    _hasLoadedOnce = false;
    _lastRefreshTime = null;
    _interestReceived = [];
    _dailyRecommendations = [];
    _profileVisitors = [];
    _allProfiles = [];
    _acceptanceCount = 0;
    _justJoinedCount = 0;
    notifyListeners();
  }
}
