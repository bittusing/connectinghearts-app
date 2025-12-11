import 'api_client.dart';
import '../models/api_models.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<LoginResponse> login(String phoneNumber, String password) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      body: {
        'phoneNumber': phoneNumber,
        'password': password,
      },
    );
    return LoginResponse.fromJson(response);
  }

  Future<ApiResponse> generateOtp(
      String phoneNumber, String countryCode) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/generateOTP',
      body: {
        'phoneNumber': phoneNumber,
        'countryCode': countryCode,
      },
    );
    return ApiResponse.fromJson(response);
  }

  Future<VerifyOtpResponse> verifyOtp(String phoneNumber, String otp) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/verifyOTP',
      body: {
        'phoneNumber': phoneNumber,
        'otp': otp,
      },
    );
    return VerifyOtpResponse.fromJson(response);
  }

  Future<ApiResponse<ValidateTokenResponse?>> validateToken() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/auth/validateToken',
    );
    // Handle response - validateToken may return success without data field
    // If data exists and is not null, parse it; otherwise return null
    ValidateTokenResponse? Function(dynamic)? fromJson = (data) {
      if (data != null && data is Map<String, dynamic>) {
        return ValidateTokenResponse.fromJson(data);
      }
      return null;
    };
    return ApiResponse<ValidateTokenResponse?>.fromJson(
      response,
      fromJson,
    );
  }

  Future<ApiResponse<UserProfileData>> getUserProfile() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/profile/getMyProfileData',
    );
    return ApiResponse<UserProfileData>.fromJson(
      response,
      (data) => UserProfileData.fromJson(data),
    );
  }

  Future<ApiResponse> changePassword(
      String oldPassword, String newPassword) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/changePassword',
      body: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
    return ApiResponse.fromJson(response);
  }

  Future<ApiResponse> signup({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required String countryCode,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/signup',
      body: {
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'countryCode': countryCode,
      },
    );
    return ApiResponse.fromJson(response);
  }

  Future<ApiResponse> deleteProfile({
    required String password,
    String? reason,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/profile/deleteProfile',
      body: {
        'password': password,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return ApiResponse.fromJson(response);
  }

  Future<ApiResponse> forgotPassword(String phoneNumber) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/forgotPassword',
      body: {
        'phoneNumber': phoneNumber,
      },
    );
    return ApiResponse.fromJson(response);
  }

  Future<ApiResponse> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/resetPassword',
      body: {
        'phoneNumber': phoneNumber,
        'otp': otp,
        'newPassword': newPassword,
      },
    );
    return ApiResponse.fromJson(response);
  }

  // Get user data with screenName for onboarding flow
  Future<Map<String, dynamic>> getUser() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/auth/getUser',
    );
    return response;
  }

  // Update last active screen for onboarding flow
  Future<ApiResponse> updateLastActiveScreen(String screenName) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/auth/updateLastActiveScreen/$screenName',
      body: {},
    );
    return ApiResponse.fromJson(response);
  }
}
