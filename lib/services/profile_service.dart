import 'dart:io';
import 'api_client.dart';
import '../models/profile_models.dart';

class ProfileService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiProfileResponse> getDailyRecommendations() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/interest/getDailyRecommendations',
    );
    return ApiProfileResponse.fromJson(response);
  }

  Future<ApiProfileResponse> getProfileVisitors() async {
    final response = await _apiClient.get<dynamic>(
      '/dashboard/getProfileVisitors',
    );
    // Handle array response
    if (response is List) {
      return ApiProfileResponse(
        status: 'success',
        data: response.map((e) => ApiProfile.fromJson(e)).toList(),
      );
    }
    return ApiProfileResponse.fromJson(response);
  }

  Future<ApiProfileResponse> getAllProfiles() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/getAllProfiles',
    );
    return ApiProfileResponse.fromJson(response);
  }

  // Get profile detail using getDetailView1 endpoint
  Future<Map<String, dynamic>> getDetailView1(String clientId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/getDetailView1/$clientId',
    );
    return response;
  }

  Future<ProfileDetailResponse> getProfileDetail(String profileId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/profile/getProfileDetail/$profileId',
    );
    return ProfileDetailResponse.fromJson(response);
  }

  Future<MyProfileResponse> getMyProfileData() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/profile/getMyProfileData',
    );
    return MyProfileResponse.fromJson(response);
  }

  // Get user profile data from personalDetails endpoint
  Future<Map<String, dynamic>> getUserProfileData() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/personalDetails/getUserProfileData/',
    );
    return response;
  }

  Future<ApiProfileResponse> searchProfiles(
      ProfileSearchPayload payload) async {
    // Match webapp endpoint: POST /dashboard/searchProfile
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/dashboard/searchProfile',
      body: payload.toJson(),
    );
    return ApiProfileResponse.fromJson(response);
  }

  Future<ApiProfileResponse> getJustJoinedProfiles() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/getjustJoined',
    );
    return ApiProfileResponse.fromJson(response);
  }

  // Generic endpoint method for dynamic profile lists
  Future<ApiProfileResponse> getProfilesByEndpoint(String endpoint) async {
    final response = await _apiClient.get<dynamic>(endpoint);
    // Handle array response
    if (response is List) {
      return ApiProfileResponse(
        status: 'success',
        data: response.map((e) => ApiProfile.fromJson(e)).toList(),
      );
    }
    return ApiProfileResponse.fromJson(response);
  }

  // Profile Actions
  Future<void> sendInterest(String targetId) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/interest/sendInterest',
      body: {'targetId': targetId},
    );
  }

  Future<void> unsendInterest(String targetId,
      {bool useReceiverId = false}) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/interest/unsendInterest',
      body: useReceiverId ? {'receiver_id': targetId} : {'targetId': targetId},
    );
  }

  Future<void> acceptInterest(String profileId) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/interest/updateInterest',
      body: {'_id': profileId, 'status': 'accept'},
    );
  }

  Future<void> declineInterest(String profileId) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/interest/updateInterest',
      body: {'_id': profileId, 'status': 'reject'},
    );
  }

  Future<void> shortlistProfile(String profileId) async {
    await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/shortlist/$profileId',
    );
  }

  Future<void> unshortlistProfile(String profileId) async {
    await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/unshortlist/$profileId',
    );
  }

  Future<void> ignoreProfile(String profileId) async {
    await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/ignoreProfile/$profileId',
    );
  }

  Future<void> unignoreProfile(String profileId) async {
    await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/unIgnoreProfile/$profileId',
    );
  }

  Future<void> blockProfile(String profileId) async {
    await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/blockprofile/$profileId',
    );
  }

  Future<void> unblockProfile(String profileId) async {
    await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/unblockprofile/$profileId',
    );
  }

  Future<UnlockProfileResponse> unlockProfile(String profileId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/profile/unlockProfile',
      body: {'profileId': profileId},
    );
    return UnlockProfileResponse.fromJson(response);
  }

  // Interest Lists
  Future<ApiProfileResponse> getInterestsReceived() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/interest/getInterests',
    );
    return ApiProfileResponse.fromJson(response);
  }

  Future<ApiProfileResponse> getInterestsSent() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/getMyInterestedProfiles',
    );
    return ApiProfileResponse.fromJson(response);
  }

  Future<ApiProfileResponse> getShortlistedProfiles() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/getMyShortlistedProfiles',
    );
    return ApiProfileResponse.fromJson(response);
  }

  Future<ApiProfileResponse> getBlockedProfiles() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/getMyBlockedProfiles',
    );
    return ApiProfileResponse.fromJson(response);
  }

  Future<ApiProfileResponse> getIgnoredProfiles() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/getAllIgnoredProfiles',
    );
    return ApiProfileResponse.fromJson(response);
  }

  // Acceptance
  Future<ApiProfileResponse> getAcceptedMe() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/getAcceptanceProfiles/acceptedMe',
    );
    return ApiProfileResponse.fromJson(response);
  }

  Future<ApiProfileResponse> getAcceptedByMe() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/getAcceptanceProfiles/acceptedByMe',
    );
    return ApiProfileResponse.fromJson(response);
  }

  // Declined
  Future<ApiProfileResponse> getMyDeclinedProfiles() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/getMyDeclinedProfiles',
    );
    return ApiProfileResponse.fromJson(response);
  }

  Future<ApiProfileResponse> getTheyDeclinedProfiles() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/getUsersWhoHaveDeclinedMe',
    );
    return ApiProfileResponse.fromJson(response);
  }

  // Unlocked
  Future<ApiProfileResponse> getUnlockedProfiles() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/getMyUnlockedProfiles',
    );
    return ApiProfileResponse.fromJson(response);
  }

  // Search by profile ID
  Future<Map<String, dynamic>> searchByProfileId(String heartsId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/auth/searchByProfileID/$heartsId',
    );
    return response;
  }

  // Update profile section (for edit pages)
  Future<Map<String, dynamic>> updateProfileSection(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/personalDetails/editProfile',
      body: payload,
    );
    return response;
  }

  // Update onboarding step (personalDetails endpoint)
  Future<Map<String, dynamic>> updateOnboardingStep(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/personalDetails',
      body: payload,
    );
    return response;
  }

  // Update SRCM details
  Future<Map<String, dynamic>> updateSrcmDetails(
      Map<String, dynamic> payload) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/srcmDetails/updateSrcmDetails',
      body: payload,
    );
    return response;
  }

  // Upload SRCM ID image (field name matches webapp: srcmPhoto)
  Future<Map<String, dynamic>> uploadSrcmIdImage(String filePath) async {
    final file = File(filePath);
    final response = await _apiClient.uploadFile<Map<String, dynamic>>(
      path: '/srcmDetails/uploadSrcmId',
      file: file,
      fieldName: 'srcmPhoto',
    );
    return response;
  }

  // Update family details
  Future<Map<String, dynamic>> updateFamilyDetails(
      Map<String, dynamic> payload) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/family',
      body: payload,
    );
    return response;
  }

  // Get partner preferences
  Future<Map<String, dynamic>> getPartnerPreferences() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/preference',
    );
    return response;
  }

  // Update partner preferences
  Future<Map<String, dynamic>> updatePartnerPreferences(
      Map<String, dynamic> payload) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/preference',
      body: payload,
    );
    return response;
  }

  // Upload profile image
  Future<Map<String, dynamic>> uploadProfileImage(String filePath) async {
    final file = File(filePath);
    final response = await _apiClient.uploadFile<Map<String, dynamic>>(
      path: '/personalDetails/uploadProfilePic',
      file: file,
      fieldName: 'profilePic',
    );
    return response;
  }
}
