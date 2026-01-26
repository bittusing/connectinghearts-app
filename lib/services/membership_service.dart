import 'api_client.dart';
import '../models/profile_models.dart';

class MembershipService {
  final ApiClient _apiClient = ApiClient();

  Future<List<MembershipPlanApi>> getMembershipPlans() async {
    final response = await _apiClient.get<dynamic>(
      '/dashboard/getMembershipList',
    );
    // Handle array response
    if (response is List) {
      return response.map((plan) => MembershipPlanApi.fromJson(plan)).toList();
    }
    // Handle object with data field
    if (response is Map<String, dynamic>) {
      final data = response['data'] as List<dynamic>? ?? [];
      return data.map((plan) => MembershipPlanApi.fromJson(plan)).toList();
    }
    return [];
  }

  Future<MembershipDetailsResponse> getMyMembershipDetails() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/getMyMembershipDetails',
    );
    return MembershipDetailsResponse.fromJson(response);
  }

  Future<PaymentOrderResponse> buyMembership(String planId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/buyMembership/$planId',
    );
    return PaymentOrderResponse.fromJson(response);
  }

  Future<PaymentVerificationResponse> verifyPayment(String orderId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/verifyPayment/$orderId',
    );
    return PaymentVerificationResponse.fromJson(response);
  }
}
