import 'api_client.dart';
import '../models/profile_models.dart';

class MembershipService {
  final ApiClient _apiClient = ApiClient();

  Future<List<MembershipPlanApi>> getMembershipPlans() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/membership/getPlans',
    );
    final data = response['data'] as List<dynamic>? ?? [];
    return data.map((plan) => MembershipPlanApi.fromJson(plan)).toList();
  }

  Future<MembershipDetailsResponse> getMyMembershipDetails() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/membership/getMyMembershipDetails',
    );
    return MembershipDetailsResponse.fromJson(response);
  }

  Future<PaymentOrderResponse> buyMembership(String planId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/membership/buyMembership',
      body: {'planId': planId},
    );
    return PaymentOrderResponse.fromJson(response);
  }

  Future<PaymentVerificationResponse> verifyPayment(String orderId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/membership/verifyPayment',
      body: {'orderId': orderId},
    );
    return PaymentVerificationResponse.fromJson(response);
  }
}
