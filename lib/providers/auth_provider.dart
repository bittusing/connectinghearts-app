import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class UserData {
  final String? id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? heartsId;
  final String? planName;
  final int? heartCoins;
  final String? avatarUrl;
  final String? screenName;

  UserData({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.heartsId,
    this.planName,
    this.heartCoins,
    this.avatarUrl,
    this.screenName,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      heartsId: json['heartsId']?.toString(),
      planName: json['planName'],
      heartCoins: json['heartCoins'],
      avatarUrl: json['avatarUrl'],
      screenName: json['screenName'],
    );
  }
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  bool _isLoading = false;
  bool _isCheckingAuth = true; // Track initial auth check
  bool _isAuthenticated = false;
  String? _error;
  UserData? _user;

  bool get isLoading => _isLoading;
  bool get isCheckingAuth => _isCheckingAuth;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  UserData? get user => _user;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isCheckingAuth = true;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        final response = await _authService.validateToken();
        // Check if token is valid (status == 'success' && code == 'CH200')
        // validateToken response: { code, status, screenName, message }
        if (response.success) {
          _isAuthenticated = true;
          // Extract screenName from validateToken response (at root level in data)
          final screenName = response.data?.screenName;
          if (screenName != null) {
            _user = UserData(screenName: screenName);
          }
          // Fetch full user profile (which will also get screenName from getUser)
          await _fetchUserProfile();
        } else {
          // Token is invalid, clear it
          await _storageService.deleteToken();
          _isAuthenticated = false;
          _user = null;
        }
      } else {
        _isAuthenticated = false;
        _user = null;
      }
    } catch (e) {
      // Token validation failed, clear auth state
      _isAuthenticated = false;
      _user = null;
      // Only delete token if it's clearly invalid (not network errors)
      try {
        await _storageService.deleteToken();
      } catch (_) {
        // Ignore errors when deleting token
      }
    } finally {
      _isCheckingAuth = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> login(
      String phoneNumber, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(phoneNumber, password);

      if (response.token != null) {
        await _storageService.setToken(response.token!);
        if (response.userId != null) {
          await _storageService.setUserId(response.userId!);
        }
        _isAuthenticated = true;

        // Store screenName from login response (like webapp - screenName comes directly in login response)
        // Don't fetch user profile yet - use screenName from login response for navigation
        if (response.screenName != null) {
          _user = UserData(
            id: response.userId,
            screenName: response.screenName,
          );
        }

        _isLoading = false;
        notifyListeners();
        // Return success with screenName for immediate navigation
        return {
          'success': true,
          'screenName': response.screenName,
        };
      } else {
        _error = 'Login failed';
        _isLoading = false;
        notifyListeners();
        return {'success': false};
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return {'success': false};
    }
  }

  Future<bool> generateOtp(String phoneNumber, String countryCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.generateOtp(phoneNumber, countryCode);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.verifyOtp(phoneNumber, otp);

      if (response.token != null) {
        await _storageService.setToken(response.token!);
        if (response.userId != null) {
          await _storageService.setUserId(response.userId!);
        }
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      // First try to get screenName from getUser API (like webapp)
      // Response structure: { code, status, message, data: { screenName, ... } }
      try {
        final userResponse = await _authService.getUser();
        final userData = userResponse['data'] as Map<String, dynamic>?;
        final screenName = userData?['screenName'] as String?;
        if (screenName != null && _user != null) {
          _user = UserData(
            id: _user!.id,
            name: _user!.name,
            email: _user!.email,
            phoneNumber: _user!.phoneNumber,
            heartsId: _user!.heartsId,
            planName: _user!.planName,
            heartCoins: _user!.heartCoins,
            avatarUrl: _user!.avatarUrl,
            screenName: screenName,
          );
        } else if (screenName != null) {
          _user = UserData(screenName: screenName);
        }
      } catch (e) {
        // Silently fail, continue to get profile
      }

      // Then fetch full profile
      final response = await _authService.getUserProfile();
      if (response.success && response.data != null) {
        _user = UserData(
          id: response.data!.id,
          name: response.data!.name,
          email: response.data!.email,
          phoneNumber: response.data!.phoneNumber,
          heartsId: response.data!.heartsId,
          planName: response.data!.planName,
          heartCoins: response.data!.heartCoins,
          avatarUrl: response.data!.avatarUrl,
          screenName: _user?.screenName, // Preserve screenName
        );
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> logout() async {
    // Clear all storage including profile data
    await _storageService.clearAll();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
