import 'package:got_report/core/error/exceptions.dart';

/// `data` of `POST /api/v1/auth/staff-app/login` and `/refresh`.
class AuthTokenModel {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final bool mustChangePassword;

  const AuthTokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.mustChangePassword,
  });

  factory AuthTokenModel.fromJson(dynamic json) {
    if (json is! Map ||
        json['accessToken'] is! String ||
        json['refreshToken'] is! String) {
      throw const ParsingException();
    }
    return AuthTokenModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      mustChangePassword: json['mustChangePassword'] == true,
    );
  }
}
