import 'package:dio/dio.dart';

import 'package:ada_tugas/core/auth/token_storage.dart';
import 'package:ada_tugas/core/constants/app_constants.dart';
import 'package:ada_tugas/core/utils/app_logger.dart';

/// Adds `Authorization: Bearer <accessToken>` to requests and, on a 401,
/// refreshes the token once via `/auth/staff-app/refresh` and retries.
///
/// If the refresh fails (expired, revoked, `AUTH_REFRESH_TOKEN_REUSED`, …)
/// the tokens are cleared and [onSessionExpired] is called so the app can
/// return to the login screen.
///
/// A [QueuedInterceptor] handles one error at a time, so several requests
/// failing with 401 together trigger only one refresh.
class AuthInterceptor extends QueuedInterceptor {
  final TokenStorage tokenStorage;
  final void Function() onSessionExpired;

  /// Bare client for refresh/retry so they don't loop through this
  /// interceptor. Shares base URL and default headers with the main client.
  late final Dio _plainDio;

  AuthInterceptor({
    required this.tokenStorage,
    required this.onSessionExpired,
  });

  /// Called by the owning client once its [BaseOptions] are known.
  void attach(BaseOptions options) {
    _plainDio = Dio(options.copyWith());
  }

  /// Follows the owning client when its base URL changes at runtime.
  void updateBaseUrl(String baseUrl) {
    _plainDio.options.baseUrl = baseUrl;
  }

  static bool _isPublicAuthPath(String path) =>
      path.endsWith(ApiEndpoints.login) ||
      path.endsWith(ApiEndpoints.refresh) ||
      path.endsWith(ApiEndpoints.forgotPassword);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublicAuthPath(options.path)) {
      final token = await tokenStorage.readAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    // A 401 from /auth/* (e.g. wrong password) is a real answer, not an
    // expired token.
    if (err.response?.statusCode != 401 ||
        request.path.contains(ApiEndpoints.authPrefix)) {
      return handler.next(err);
    }

    try {
      final sentToken = request.headers['Authorization'];
      final currentToken = await tokenStorage.readAccessToken();

      // Another queued request may have refreshed already.
      if (currentToken == null || sentToken == 'Bearer $currentToken') {
        final refreshed = await _refresh();
        if (!refreshed) {
          await _expireSession();
          return handler.next(err);
        }
      }

      final newToken = await tokenStorage.readAccessToken();
      request.headers['Authorization'] = 'Bearer $newToken';
      final response = await _plainDio.fetch<dynamic>(request);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  Future<bool> _refresh() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _plainDio.post<dynamic>(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );
      final data = (response.data as Map)['data'] as Map;
      await tokenStorage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } catch (e) {
      AppLogger.api('Token refresh failed: $e');
      return false;
    }
  }

  Future<void> _expireSession() async {
    await tokenStorage.clear();
    onSessionExpired();
  }
}
