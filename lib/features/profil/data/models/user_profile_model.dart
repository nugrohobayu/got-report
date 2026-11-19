import 'package:got_report/core/error/exceptions.dart';
import 'package:got_report/features/profil/domain/entities/user_profile.dart';

class UserProfileModel {
  UserProfileModel._();

  static UserProfile fromJson(dynamic json) {
    if (json is! Map || json['id'] is! String) {
      throw const ParsingException();
    }
    final roles = json['roles'];
    return UserProfile(
      id: json['id'] as String,
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roleNames: roles is List
          ? [
              for (final r in roles)
                if (r is Map && r['name'] != null) r['name'].toString(),
            ]
          : const [],
    );
  }
}
