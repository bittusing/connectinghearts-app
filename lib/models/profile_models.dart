class ApiProfile {
  final String? id;
  final String? clientID;
  final String? heartsId;
  final String? name;
  final int? age;
  final String? dob;
  final String? height;
  final String? religion;
  final String? caste;
  final String? city;
  final String? state;
  final String? country;
  final String? occupation;
  final String? income;
  final String? qualification;
  final String? gender;
  final List<ProfilePic>? profilePic;

  ApiProfile({
    this.id,
    this.clientID,
    this.heartsId,
    this.name,
    this.age,
    this.dob,
    this.height,
    this.religion,
    this.caste,
    this.city,
    this.state,
    this.country,
    this.occupation,
    this.income,
    this.qualification,
    this.gender,
    this.profilePic,
  });

  factory ApiProfile.fromJson(Map<String, dynamic> json) {
    // Helper function to convert dynamic to String
    String? toString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      return value.toString();
    }

    // Helper to safely get ID (can be String or ObjectId)
    String? getId(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      if (value is Map) return value['\$oid']?.toString() ?? value.toString();
      return value.toString();
    }

    return ApiProfile(
      id: getId(json['_id'] ?? json['id']),
      clientID: toString(json['clientID']),
      heartsId: json['heartsId']?.toString(),
      name: toString(json['name']),
      age: json['age'] is int
          ? json['age']
          : (json['age'] is String
              ? int.tryParse(json['age'])
              : (json['age'] is num ? json['age'].toInt() : null)),
      dob: toString(json['dob']),
      // Try to get height from basic.height if available, otherwise from top level
      height: (json['basic'] is Map && json['basic']['height'] != null)
          ? json['basic']['height'].toString()
          : json['height']?.toString(), // Can be int or String
      religion: toString(json['religion']),
      caste: toString(json['caste'] ?? json['cast']),
      city: toString(json['city']),
      state: toString(json['state']),
      country: toString(json['country']),
      occupation: toString(json['occupation']),
      income: json['income']?.toString(), // Can be int, double, or String
      qualification: toString(json['qualification']),
      gender: toString(json['gender']),
      profilePic: (json['profilePic'] as List<dynamic>?)
          ?.map((pic) => ProfilePic.fromJson(pic))
          .toList(),
    );
  }
}

class ProfilePic {
  final String? id;
  final String? s3Link;

  ProfilePic({this.id, this.s3Link});

  factory ProfilePic.fromJson(Map<String, dynamic> json) {
    // Handle both int and String IDs
    String? idValue;
    if (json['id'] != null) {
      idValue = json['id'].toString();
    }

    return ProfilePic(
      id: idValue,
      s3Link: json['s3Link']?.toString(),
    );
  }
}

class ApiProfileResponse {
  final String status;
  final List<ApiProfile> data;
  final int? notificationCount;

  ApiProfileResponse({
    required this.status,
    required this.data,
    this.notificationCount,
  });

  bool get success => status == 'success';

  factory ApiProfileResponse.fromJson(Map<String, dynamic> json) {
    List<ApiProfile> profiles = [];

    // Handle different response formats
    if (json['filteredProfiles'] != null) {
      profiles = (json['filteredProfiles'] as List<dynamic>)
          .map((profile) => ApiProfile.fromJson(profile))
          .toList();
    } else if (json['shortlistedProfilesData'] != null) {
      profiles = (json['shortlistedProfilesData'] as List<dynamic>)
          .map((profile) => ApiProfile.fromJson(profile))
          .toList();
    } else if (json['ignoreListData'] != null) {
      profiles = (json['ignoreListData'] as List<dynamic>)
          .map((profile) => ApiProfile.fromJson(profile))
          .toList();
    } else if (json['data'] != null && json['data'] is List) {
      profiles = (json['data'] as List<dynamic>)
          .map((profile) => ApiProfile.fromJson(profile))
          .toList();
    }

    return ApiProfileResponse(
      status: json['status'] ?? 'success',
      data: profiles,
      notificationCount: json['notificationCount'],
    );
  }
}

class ProfileSearchPayload {
  List<String>? country;
  List<String>? state;
  List<String>? city;
  List<String>? religion;
  List<String>? motherTongue;
  List<String>? maritalStatus;
  Map<String, dynamic>? age;
  Map<String, dynamic>? height;
  Map<String, dynamic>? income;

  ProfileSearchPayload({
    this.country,
    this.state,
    this.city,
    this.religion,
    this.motherTongue,
    this.maritalStatus,
    this.age,
    this.height,
    this.income,
  });

  bool get hasFilters {
    return (country?.isNotEmpty ?? false) ||
        (state?.isNotEmpty ?? false) ||
        (city?.isNotEmpty ?? false) ||
        (religion?.isNotEmpty ?? false) ||
        (motherTongue?.isNotEmpty ?? false) ||
        (maritalStatus?.isNotEmpty ?? false) ||
        (age?.isNotEmpty ?? false) ||
        (height?.isNotEmpty ?? false) ||
        (income?.isNotEmpty ?? false);
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (country?.isNotEmpty ?? false) map['country'] = country;
    if (state?.isNotEmpty ?? false) map['state'] = state;
    if (city?.isNotEmpty ?? false) map['city'] = city;
    if (religion?.isNotEmpty ?? false) map['religion'] = religion;
    if (motherTongue?.isNotEmpty ?? false) map['motherTongue'] = motherTongue;
    if (maritalStatus?.isNotEmpty ?? false) {
      map['maritalStatus'] = maritalStatus;
    }
    if (age?.isNotEmpty ?? false) map['age'] = age;
    if (height?.isNotEmpty ?? false) map['height'] = height;
    if (income?.isNotEmpty ?? false) map['income'] = income;
    return map;
  }
}

class ProfileDetailData {
  final Map<String, dynamic>? basic;
  final Map<String, dynamic>? critical;
  final Map<String, dynamic>? about;
  final Map<String, dynamic>? education;
  final Map<String, dynamic>? career;
  final Map<String, dynamic>? family;
  final Map<String, dynamic>? kundali;
  final Map<String, dynamic>? lifeStyleData;
  final Map<String, dynamic>? miscellaneous;
  final List<dynamic>? matchData;
  final String? matchPercentage;

  ProfileDetailData({
    this.basic,
    this.critical,
    this.about,
    this.education,
    this.career,
    this.family,
    this.kundali,
    this.lifeStyleData,
    this.miscellaneous,
    this.matchData,
    this.matchPercentage,
  });

  factory ProfileDetailData.fromJson(Map<String, dynamic> json) {
    return ProfileDetailData(
      basic: json['basic'],
      critical: json['critical'],
      about: json['about'],
      education: json['education'],
      career: json['career'],
      family: json['family'],
      kundali: json['kundali'],
      lifeStyleData: json['lifeStyleData'],
      miscellaneous: json['miscellaneous'],
      matchData: json['matchData'],
      matchPercentage: json['matchPercentage']?.toString(),
    );
  }
}

class ProfileDetailResponse {
  final bool success;
  final Map<String, dynamic>? data;

  ProfileDetailResponse({
    required this.success,
    this.data,
  });

  factory ProfileDetailResponse.fromJson(Map<String, dynamic> json) {
    return ProfileDetailResponse(
      success: json['status'] == 'success' || json['success'] == true,
      data: json['profileData'] ?? json['data'],
    );
  }
}

class MyProfileResponse {
  final bool success;
  final Map<String, dynamic>? data;

  MyProfileResponse({
    required this.success,
    this.data,
  });

  factory MyProfileResponse.fromJson(Map<String, dynamic> json) {
    return MyProfileResponse(
      success: json['success'] ?? false,
      data: json['data'],
    );
  }
}

class UnlockProfileResponse {
  final bool success;
  final String? message;
  final String? code;
  final int? remainingCoins;
  final bool redirectToMembership;

  UnlockProfileResponse({
    required this.success,
    this.message,
    this.code,
    this.remainingCoins,
    this.redirectToMembership = false,
  });

  factory UnlockProfileResponse.fromJson(Map<String, dynamic> json) {
    final err = json['err'];
    final redirectToMembership =
        err is Map && err['redirectToMembership'] == true;

    return UnlockProfileResponse(
      success: json['code'] != 'CH400' && json['status'] == 'success',
      message: json['message'] ?? (err is Map ? err['msg'] : null),
      code: json['code'],
      remainingCoins: json['remainingCoins'],
      redirectToMembership: redirectToMembership,
    );
  }
}

class MembershipPlanApi {
  final String id;
  final String? planName;
  final int membershipAmount;
  final int duration;
  final int heartCoins;
  final String? currency;
  final List<String>? features;

  MembershipPlanApi({
    required this.id,
    this.planName,
    required this.membershipAmount,
    required this.duration,
    required this.heartCoins,
    this.currency,
    this.features,
  });

  factory MembershipPlanApi.fromJson(Map<String, dynamic> json) {
    // heartCoins can be a string or int from API
    int parseHeartCoins(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return MembershipPlanApi(
      id: json['_id'] ?? json['id'],
      planName: json['planName'],
      membershipAmount: json['membershipAmount'] ?? 0,
      duration: json['duration'] ?? 0,
      heartCoins: parseHeartCoins(json['heartCoins']),
      currency: json['currency'] ?? 'INR',
      features: (json['features'] as List<dynamic>?)
          ?.map((f) => f.toString())
          .toList(),
    );
  }
}

class MembershipDetailsResponse {
  final bool success;
  final MembershipData? membershipData;

  MembershipDetailsResponse({
    required this.success,
    this.membershipData,
  });

  factory MembershipDetailsResponse.fromJson(Map<String, dynamic> json) {
    final membershipData = json['membershipData'];
    // Check if membershipData exists and has at least one non-null field
    // If all fields are null, treat it as no membership
    if (membershipData != null && membershipData is Map<String, dynamic>) {
      final hasValidData = membershipData['planName'] != null ||
          membershipData['memberShipExpiryDate'] != null ||
          membershipData['membership_id'] != null;
      return MembershipDetailsResponse(
        success: json['status'] == 'success',
        membershipData:
            hasValidData ? MembershipData.fromJson(membershipData) : null,
      );
    }
    return MembershipDetailsResponse(
      success: json['status'] == 'success',
      membershipData: null,
    );
  }
}

class MembershipData {
  final String? planName;
  final String? memberShipExpiryDate;
  final int heartCoins;
  final String? membership_id;

  MembershipData({
    this.planName,
    this.memberShipExpiryDate,
    this.heartCoins = 0,
    this.membership_id,
  });

  factory MembershipData.fromJson(Map<String, dynamic> json) {
    // heartCoins can be null or a number from API
    int parseHeartCoins(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return MembershipData(
      planName: json['planName'],
      memberShipExpiryDate: json['memberShipExpiryDate'],
      heartCoins: parseHeartCoins(json['heartCoins']),
      membership_id: json['membership_id'],
    );
  }
}

class PaymentOrderResponse {
  final String orderId;
  final int amount;
  final String currency;
  final String? keyId;
  final String? message;

  PaymentOrderResponse({
    required this.orderId,
    required this.amount,
    required this.currency,
    this.keyId,
    this.message,
  });

  factory PaymentOrderResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return PaymentOrderResponse(
      orderId: data['orderId'] ?? '',
      amount: data['amount'] ?? 0,
      currency: data['currency'] ?? 'INR',
      keyId: data['keyId'] ?? data['key'],
      message: data['message'] ?? json['message'],
    );
  }
}

class PaymentVerificationResponse {
  final bool success;
  final String? message;

  PaymentVerificationResponse({
    required this.success,
    this.message,
  });

  factory PaymentVerificationResponse.fromJson(Map<String, dynamic> json) {
    // Handle both 'success' and 'status' fields (webapp uses 'status')
    final success = json['success'] ?? (json['status'] == 'success') ?? false;
    return PaymentVerificationResponse(
      success: success,
      message: json['message'],
    );
  }
}

class LookupOption {
  final String label;
  final dynamic value;

  LookupOption({
    required this.label,
    required this.value,
  });

  factory LookupOption.fromJson(Map<String, dynamic> json) {
    return LookupOption(
      label: json['label'] ?? json['name'] ?? '',
      value: json['value'] ?? json['_id'] ?? json['id'] ?? '',
    );
  }
}

class LookupDictionary {
  final Map<String, List<LookupOption>> data;

  LookupDictionary({required this.data});

  factory LookupDictionary.fromJson(Map<String, dynamic> json) {
    final Map<String, List<LookupOption>> result = {};
    json.forEach((key, value) {
      if (value is List) {
        result[key] = value.map((item) => LookupOption.fromJson(item)).toList();
      }
    });
    return LookupDictionary(data: result);
  }
}
