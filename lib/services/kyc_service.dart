import '../models/kyc_models.dart';
import 'api_client.dart';

class KYCService {
  final ApiClient _apiClient = ApiClient();

  Future<GetUserResponse> getUser() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/auth/getUser');
    return GetUserResponse.fromJson(response);
  }

  Future<KYCGenerateOtpResponse> generateOtp(String aadhaarNumber) async {
    final request = KYCGenerateOtpRequest(aadhaarNumber: aadhaarNumber);
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/kyc/generate-otp',
      body: request.toJson(),
    );
    return KYCGenerateOtpResponse.fromJson(response);
  }

  Future<KYCVerifyOtpResponse> verifyOtp(String referenceId, String otp) async {
    final request = KYCVerifyOtpRequest(referenceId: referenceId, otp: otp);
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/kyc/verify-otp',
      body: request.toJson(),
    );
    return KYCVerifyOtpResponse.fromJson(response);
  }
}