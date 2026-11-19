import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'https://jsonplaceholder.typicode.com';

  /// Sent as `X-App-Version`; keep in sync with `version:` in pubspec.yaml.
  static const String appVersion = '1.0.0';

  static Duration get connectTimeout => const Duration(seconds: 15);

  static Duration get receiveTimeout => const Duration(seconds: 15);
}

class ApiEndpoints {
  ApiEndpoints._();

  // Auth (staff app / mobile)
  static const String authPrefix = '/api/v1/auth/';
  static const String login = '/api/v1/auth/staff-app/login';
  static const String refresh = '/api/v1/auth/staff-app/refresh';
  static const String logout = '/api/v1/auth/staff-app/logout';
  static const String forgotPassword = '/api/v1/auth/password/forgot';

  /// `GET`; profile, roles and permissions of the logged-in user.
  static const String me = '/api/v1/me';

  // Account (all staff, also used by mobile)
  /// `PUT`; revokes every session, including the current one.
  static const String changePassword = '/api/v1/admin/account/password';

  // Field (petugas di HP)
  /// `GET ?status=&dueFrom=&dueTo=`; without `status` only unfinished tasks.
  static const String fieldTasks = '/api/v1/field/tasks';

  /// `POST {fid, platform, appVersion}`: register this device for push.
  /// 404 when the server's notification-push profile is off.
  static const String fieldDevices = '/api/v1/field/devices';
}
