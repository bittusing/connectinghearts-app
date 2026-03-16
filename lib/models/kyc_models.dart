class KYCGenerateOtpRequest {
  final String aadhaarNumber;

  KYCGenerateOtpRequest({required this.aadhaarNumber});

  Map<String, dynamic> toJson() {
    return {
      'aadhaarNumber': aadhaarNumber,
    };
  }
}

class KYCGenerateOtpResponse {
  final String code;
  final String status;
  final String message;
  final String? referenceId;
  final String? transactionId;

  KYCGenerateOtpResponse({
    required this.code,
    required this.status,
    required this.message,
    this.referenceId,
    this.transactionId,
  });

  factory KYCGenerateOtpResponse.fromJson(Map<String, dynamic> json) {
    return KYCGenerateOtpResponse(
      code: json['code'] ?? '',
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      referenceId: json['referenceId'],
      transactionId: json['transactionId'],
    );
  }

  bool get isSuccess => status == 'success';
}

class KYCVerifyOtpRequest {
  final String referenceId;
  final String otp;

  KYCVerifyOtpRequest({
    required this.referenceId,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'referenceId': referenceId,
      'otp': otp,
    };
  }
}

class KYCData {
  final String name;
  final String dateOfBirth;
  final String gender;
  final String address;

  KYCData({
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
  });

  factory KYCData.fromJson(Map<String, dynamic> json) {
    return KYCData(
      name: json['name'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      gender: json['gender'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

class KYCVerifyOtpResponse {
  final String code;
  final String status;
  final String message;
  final KYCData? kycData;

  KYCVerifyOtpResponse({
    required this.code,
    required this.status,
    required this.message,
    this.kycData,
  });

  factory KYCVerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return KYCVerifyOtpResponse(
      code: json['code'] ?? '',
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      kycData: json['kycData'] != null ? KYCData.fromJson(json['kycData']) : null,
    );
  }

  bool get isSuccess => status == 'success';
}

class GetUserResponse {
  final String code;
  final String status;
  final String message;
  final UserData? data;

  GetUserResponse({
    required this.code,
    required this.status,
    required this.message,
    this.data,
  });

  factory GetUserResponse.fromJson(Map<String, dynamic> json) {
    return GetUserResponse(
      code: json['code'] ?? '',
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null ? UserData.fromJson(json['data']) : null,
    );
  }

  bool get isSuccess => status == 'success';
}

class UserData {
  final String id;
  final String? screenName;
  final String? kycStatus;
  final String? countryCode;

  UserData({
    required this.id,
    this.screenName,
    this.kycStatus,
    this.countryCode,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['_id'] ?? json['id'] ?? '',
      screenName: json['screenName'],
      kycStatus: json['kycStatus'],
      countryCode: json['countryCode'],
    );
  }
}