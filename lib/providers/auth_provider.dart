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

  UserData({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.heartsId,
    this.planName,
    this.heartCoins,
    this.avatarUrl,
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
        if (response.success) {
          _isAuthenticated = true;
          // If response has user data, use it; otherwise fetch profile
          if (response.data != null) {
            _user = UserData.fromJson(response.data!.toJson());
          } else {
            // Fetch user profile if validateToken doesn't return user data
            await _fetchUserProfile();
          }
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

  Future<bool> login(String phoneNumber, String password) async {
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

        // Fetch user profile
        await _fetchUserProfile();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
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
        );
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> logout() async {
    await _storageService.clearAll();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
