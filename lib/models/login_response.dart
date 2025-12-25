import 'auth_user.dart';

class LoginResponse {
  final AuthUser user;
  final String accessToken;
  final String refreshToken;
  final String? message;

  LoginResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'message': message,
    };
  }
}
