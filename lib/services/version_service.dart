import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class VersionService {
  final ApiClient _apiClient = ApiClient();
  static const String _lastCheckKey = 'last_version_check';
  static const Duration _checkInterval = Duration(hours: 24); // Check once per day

  // Get app version from pubspec.yaml
  String getCurrentVersion() {
    return '1.0.0'; // This matches pubspec.yaml version
  }

  // Check if we should check for update (to avoid too many API calls)
  Future<bool> shouldCheckForUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckStr = prefs.getString(_lastCheckKey);
    
    if (lastCheckStr == null) return true;
    
    final lastCheck = DateTime.parse(lastCheckStr);
    final now = DateTime.now();
    
    return now.difference(lastCheck) >= _checkInterval;
  }

  // Save last check time
  Future<void> _saveLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
  }

  // Check for update from API
  Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      // Check if we should make API call
      if (!await shouldCheckForUpdate()) {
        return null; // Don't check too frequently
      }

      final currentVersion = getCurrentVersion();
      
      // Call API with current version
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/auth/checkUpdate/$currentVersion',
      );

      // Save last check time
      await _saveLastCheckTime();

      if (response['code'] == 'CH200' && response['status'] == 'success') {
        final message = response['message'] as Map<String, dynamic>?;
        
        if (message != null) {
          final forceUpgrade = message['forceUpgrade'] ?? false;
          final recommendUpgrade = message['recommendUpgrade'] ?? false;
          
          // Only return if update is needed
          if (forceUpgrade || recommendUpgrade) {
            return {
              'forceUpgrade': forceUpgrade,
              'recommendUpgrade': recommendUpgrade,
            };
          }
        }
      }
      
      return null; // No update needed
    } catch (e) {
      print('Version check failed: $e');
      return null; // Fail silently
    }
  }

  // Force check (ignore time interval) - useful for testing
  Future<Map<String, dynamic>?> forceCheckForUpdate() async {
    try {
      final currentVersion = getCurrentVersion();
      
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/auth/checkUpdate/$currentVersion',
      );

      await _saveLastCheckTime();

      if (response['code'] == 'CH200' && response['status'] == 'success') {
        final message = response['message'] as Map<String, dynamic>?;
        
        if (message != null) {
          final forceUpgrade = message['forceUpgrade'] ?? false;
          final recommendUpgrade = message['recommendUpgrade'] ?? false;
          
          if (forceUpgrade || recommendUpgrade) {
            return {
              'forceUpgrade': forceUpgrade,
              'recommendUpgrade': recommendUpgrade,
            };
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Version check failed: $e');
      return null;
    }
  }
}
