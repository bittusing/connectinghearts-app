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

  bool _isLoading = false;
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

  // Fetch fresh data from API
  Future<void> _fetchFreshData(
    Map<String, List<LookupOption>> lookupData,
    List<LookupOption> countries,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load static data FIRST (cities, states, countries) before transforming profiles
      final staticDataService = StaticDataService.instance;
      await staticDataService.loadAllData();
      
      // Verify static data is loaded
      print('🔍 Static Data Status:');
      print('   Cities loaded: ${staticDataService.isCitiesLoaded}');
      print('   States loaded: ${staticDataService.isStatesLoaded}');
      print('   Countries loaded: ${staticDataService.isCountriesLoaded}');

      // Load stats
      final statsFuture = Future.wait([
        _profileService.getProfilesByEndpoint(
          'dashboard/getAcceptanceProfiles/acceptedMe',
        ),
        _profileService.getJustJoinedProfiles(),
      ]);

      final stats = await statsFuture;
      final acceptanceResponse = stats[0];
      final justJoinedResponse = stats[1];

      // Load sections in parallel (limit to 5 profiles each)
      final sectionsFuture = Future.wait([
        _profileService.getInterestsReceived().then((response) {
          return ApiProfileResponse(
            status: response.status,
            data: response.data.take(5).toList(),
          );
        }),
        _profileService.getDailyRecommendations().then((response) {
          return ApiProfileResponse(
            status: response.status,
            data: response.data.take(5).toList(),
          );
        }),
        _profileService.getProfileVisitors().then((response) {
          return ApiProfileResponse(
            status: response.status,
            data: response.data.take(5).toList(),
          );
        }),
        _profileService.getAllProfiles().then((response) {
          return ApiProfileResponse(
            status: response.status,
            data: response.data.take(5).toList(),
          );
        }),
      ]);

      final sections = await sectionsFuture;
      final interestReceived = sections[0];
      final dailyRecs = sections[1];
      final visitors = sections[2];
      final allProfiles = sections[3];

      // Update state - transform profiles with static data loaded
      _acceptanceCount = acceptanceResponse.data.length;
      _justJoinedCount = justJoinedResponse.data.length;
      
      // Transform profiles and log first profile to verify location mapping
      _interestReceived = interestReceived.data
          .map((p) => transformProfile(p, lookupData: lookupData, countries: countries))
          .toList();
      if (_interestReceived.isNotEmpty) {
        print('📍 Sample location: ${_interestReceived.first['location']}');
      }
      
      _dailyRecommendations = dailyRecs.data
          .map((p) => transformProfile(p, lookupData: lookupData, countries: countries))
          .toList();
      _profileVisitors = visitors.data
          .map((p) => transformProfile(p, lookupData: lookupData, countries: countries))
          .toList();
      _allProfiles = allProfiles.data
          .map((p) => transformProfile(p, lookupData: lookupData, countries: countries))
          .toList();

      _hasLoadedOnce = true;
      _lastRefreshTime = DateTime.now();

      // Save to cache
      await _saveToCache();

      print('✅ Dashboard: Fresh data loaded');
    } catch (e) {
      print('❌ Dashboard: Fetch failed: $e');
    } finally {
      _isLoading = false;
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
