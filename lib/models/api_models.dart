class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, [
    T Function(dynamic)? fromJsonT,
  ]) {
    // Handle both formats: 'success' field or 'status'/'code' format
    bool success = false;
    if (json['success'] != null) {
      success = json['success'] == true;
    } else if (json['status'] != null && json['code'] != null) {
      success = json['status'] == 'success' && json['code'] == 'CH200';
    } else if (json['status'] != null) {
      success = json['status'] == 'success';
    }

    // Extract message - check for 'err' field first (like webapp error format)
    String? message = json['message'];
    if (message == null || message.isEmpty) {
      // Check for 'err' field (can be string or object with 'msg')
      if (json['err'] != null) {
        if (json['err'] is String) {
          message = json['err'] as String;
        } else if (json['err'] is Map && json['err']['msg'] != null) {
          message = json['err']['msg'] as String;
        }
      }
    }

    return ApiResponse<T>(
      success: success,
      message: message,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
    );
  }
}

class LoginResponse {
  final String? token;
  final String? userId;
  final String? screenName;
  final String? message;
  final String? code;
  final String? status;

  LoginResponse({
    this.token,
    this.userId,
    this.screenName,
    this.message,
    this.code,
    this.status,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      userId: json['userId'] ?? json['id'], // Handle both 'userId' and 'id'
      screenName: json['screenName'],
      message: json['message'],
      code: json['code'],
      status: json['status'],
    );
  }
}

class VerifyOtpResponse {
  final String? token;
  final String? userId;
  final String? message;
  final String? status;
  final bool success;

  VerifyOtpResponse({
    this.token,
    this.userId,
    this.message,
    this.status,
    this.success = false,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? '';
    return VerifyOtpResponse(
      token: json['token'],
      userId: json['userId'],
      message: json['message'],
      status: status,
      success: status == 'success' || json['code'] == 'CH200',
    );
  }
}

class ValidateTokenResponse {
  final String? id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? screenName;

  ValidateTokenResponse({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.screenName,
  });

  factory ValidateTokenResponse.fromJson(Map<String, dynamic> json) {
    return ValidateTokenResponse(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      screenName: json['screenName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }
}

class UserProfileData {
  final String? id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? heartsId;
  final String? planName;
  final int? heartCoins;
  final String? avatarUrl;

  UserProfileData({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.heartsId,
    this.planName,
    this.heartCoins,
    this.avatarUrl,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
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
