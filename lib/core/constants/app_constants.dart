import 'package:got_report/core/config/env_config.dart';

class AppConstants {
  AppConstants._();

  /// `.env` value, or the one set on the device (see [EnvConfig]).
  static String get baseUrl => EnvConfig.baseUrl;

  /// Sent as `X-App-Version`; keep in sync with `version:` in pubspec.yaml.
  static const String appVersion = '1.0.1';

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

  /// `GET` without login: branding, optional features
  /// (`features["notification-push"]`), minimum app versions.
  static const String publicConfig = '/api/v1/public/config';

  // Account (all staff, also used by mobile)
  /// `PUT`; revokes every session, including the current one.
  static const String changePassword = '/api/v1/admin/account/password';

  // Field (petugas di HP)
  /// `GET ?status=&dueFrom=&dueTo=`; without `status` only unfinished tasks.
  static const String fieldTasks = '/api/v1/field/tasks';

  /// `GET`: detail + template (requireQr, schema).
  static String fieldTask(String id) => '$fieldTasks/$id';

  /// `POST {latitude, longitude, accuracyM, mock, deviceTime, qrCode?}`.
  static String fieldTaskStart(String id) => '$fieldTasks/$id/start';

  /// `POST {answers: [{fieldId, value}], latitude, longitude, ...}`.
  static String fieldStepAnswers(String id, String stepId) =>
      '$fieldTasks/$id/steps/$stepId/answers';

  /// `POST` multipart photo: stepId, fieldId, file, GPS, deviceTime.
  static String fieldMedia(String id) => '$fieldTasks/$id/media';

  /// `GET`: watermark status (PROCESSING / READY / FAILED).
  static String fieldMediaItem(String id, String mediaId) =>
      '$fieldTasks/$id/media/$mediaId';

  /// `POST` (leader): → MENUNGGU_TTD, or SELESAI without signature.
  static String fieldSubmit(String id) => '$fieldTasks/$id/submit';

  /// `POST` multipart (leader): signerName, signerTitle?, file, GPS.
  static String fieldSignature(String id) => '$fieldTasks/$id/signature';

  /// `GET`: current answers, photos, step locks, signature.
  static String fieldSubmission(String id) => '$fieldTasks/$id/submission';

  /// `GET`: file bytes (photo, signature, PDF) with access check.
  static String file(String id) => '/api/v1/files/$id';

  /// `POST {fid, platform, appVersion}`: register this device for push;
  /// `DELETE ?fid=`: stop pushing to it.
  /// 404 when the server's notification-push profile is off.
  static const String fieldDevices = '/api/v1/field/devices';

  /// `POST {pings: [{latitude, longitude, accuracyM?, mock?, recordedAt}]}`
  /// (1–100 points) → `{accepted, dropped}`. Only kept while the user has a
  /// DIKERJAKAN task; send only then.
  static const String fieldPings = '/api/v1/field/pings';
}
