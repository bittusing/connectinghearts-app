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
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'],
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

  LoginResponse({
    this.token,
    this.userId,
    this.screenName,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      userId: json['userId'],
      screenName: json['screenName'],
      message: json['message'],
    );
  }
}

class VerifyOtpResponse {
  final String? token;
  final String? userId;
  final String? message;

  VerifyOtpResponse({
    this.token,
    this.userId,
    this.message,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      token: json['token'],
      userId: json['userId'],
      message: json['message'],
    );
  }
}

class ValidateTokenResponse {
  final String? id;
  final String? name;
  final String? email;
  final String? phoneNumber;

  ValidateTokenResponse({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
  });

  factory ValidateTokenResponse.fromJson(Map<String, dynamic> json) {
    return ValidateTokenResponse(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
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
