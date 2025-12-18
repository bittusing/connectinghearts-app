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

  // Match webapp: POST /auth/generateOtp with extension (not countryCode)
  Future<ApiResponse> generateOtp(String phoneNumber, String extension) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/generateOtp',
      body: {
        'phoneNumber': phoneNumber,
        'extension': extension,
      },
    );
    return ApiResponse.fromJson(response);
  }

  // Match webapp: POST /auth/verifyOtp
  Future<VerifyOtpResponse> verifyOtp(String phoneNumber, String otp) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/verifyOtp',
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
    // validateToken response structure: { code, status, screenName, message }
    // screenName is at root level, not in data field
    ValidateTokenResponse? fromJson(data) {
      // The response itself contains screenName at root level
      // So we parse the entire response, not just data field
      if (response != null && response is Map<String, dynamic>) {
        return ValidateTokenResponse.fromJson(response);
      }
      return null;
    }

    // Create ApiResponse manually since screenName is at root, not in data
    final status = response['status']?.toString() ?? '';
    final success = status == 'success' || response['code'] == 'CH200';

    return ApiResponse<ValidateTokenResponse?>(
      success: success,
      message: response['message']?.toString(),
      data: ValidateTokenResponse.fromJson(response),
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
      String currentPassword, String newPassword) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/auth/changePassword',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
    return ApiResponse.fromJson(response);
  }

  // Match webapp: POST /auth/signup with source field
  Future<ApiResponse> signup({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String source = 'MOBILE',
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/signup',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
          'source': source,
        },
      );

      // Check if response indicates failure even with 200 status
      // Handle case: {"code":"CH400","status":"failed","err":"Profile already exists. Please login."}
      final status = response['status']?.toString() ?? '';
      final code = response['code']?.toString() ?? '';

      // If status is "failed" or code is error code, ensure ApiResponse reflects failure
      if (status == 'failed' || (code.isNotEmpty && code != 'CH200')) {
        // Extract err field if present
        String? errorMessage =
            response['err']?.toString() ?? response['message']?.toString();
        return ApiResponse(
          success: false,
          message: errorMessage ?? 'Registration failed',
        );
      }

      return ApiResponse.fromJson(response);
    } catch (e) {
      // If API throws exception (e.g., 400 status), extract error message
      String errorMsg = e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'^API\s+\d+:\s*'), '').trim();
      // Return ApiResponse with error
      return ApiResponse(
        success: false,
        message: errorMsg.isNotEmpty ? errorMsg : 'Registration failed',
      );
    }
  }

  Future<ApiResponse> deleteProfile({
    required int reasonForDeletion,
    required String deletionComment,
  }) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      '/auth/deleteProfile',
      body: {
        'reasonForDeletion': reasonForDeletion,
        'deletionComment': deletionComment,
      },
    );
    return ApiResponse.fromJson(response);
  }

  // Match webapp: GET /auth/forgetPassword/{phoneNumber}
  Future<ApiResponse> forgetPassword(String phoneNumber) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/auth/forgetPassword/$phoneNumber',
    );
    return ApiResponse.fromJson(response);
  }

  // Match webapp: POST /auth/verifyForgottenOTP
  // Returns response with token field (not nested in data)
  Future<Map<String, dynamic>> verifyForgottenOtp(
      String phoneNumber, String otp) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/verifyForgottenOTP',
      body: {
        'phoneNumber': phoneNumber,
        'otp': otp,
      },
    );
    return response;
  }

  // Match webapp: POST /auth/updateForgottenPassword
  Future<ApiResponse> updateForgottenPassword(String password) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/updateForgottenPassword',
      body: {
        'password': password,
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
