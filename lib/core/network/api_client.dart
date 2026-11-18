import 'dart:io';

import 'package:dio/dio.dart';

import 'package:got_report/core/auth/auth_interceptor.dart';
import 'package:got_report/core/constants/app_constants.dart';
import 'package:got_report/core/error/exceptions.dart';
import 'package:got_report/core/network/logging_interceptor.dart';

/// Thin, reusable wrapper around [Dio] that centralizes the base URL,
/// timeouts, and error translation so that data sources never touch
/// `package:dio` directly.
///
/// Backend responses use the envelope `{success, data, meta}` /
/// `{success: false, error: {code, message, details}}`; this client returns
/// `data` on success and throws [ServerException] on error.
class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio, String? baseUrl, AuthInterceptor? authInterceptor})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? AppConstants.baseUrl,
                connectTimeout: AppConstants.connectTimeout,
                receiveTimeout: AppConstants.receiveTimeout,
                headers: {
                  'X-App-Platform': Platform.isIOS ? 'ios' : 'android',
                  'X-App-Version': AppConstants.appVersion,
                },
              ),
            ) {
    if (authInterceptor != null) {
      authInterceptor.attach(_dio.options);
      _dio.interceptors.add(authInterceptor);
    }
    _dio.interceptors.add(LoggingInterceptor());
  }

  String get baseUrl => _dio.options.baseUrl;

  /// Exposes the underlying [Dio] instance so other network services (e.g.
  /// downloads) can share the same base configuration and interceptors.
  Dio get dio => _dio;

  Future<dynamic> get(String path, {Map<String, String>? queryParameters}) {
    return _send(() => _dio.get(path, queryParameters: queryParameters));
  }

  Future<dynamic> post(String path, {Object? body}) {
    return _send(() => _dio.post(path, data: body));
  }

  Future<dynamic> put(String path, {Object? body}) {
    return _send(() => _dio.put(path, data: body));
  }

  Future<dynamic> _send(Future<Response> Function() request) async {
    try {
      final response = await request();
      return _unwrap(response.data, response.statusCode);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  /// Returns `data` from the backend envelope; non-envelope bodies (e.g.
  /// third-party APIs) are returned as-is.
  dynamic _unwrap(dynamic body, int? statusCode) {
    if (body is Map && body['success'] is bool) {
      if (body['success'] == true) return body['data'];
      throw _serverException(body, statusCode ?? 0);
    }
    return body;
  }

  Exception _translateError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiTimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badCertificate:
        return NetworkException(e.message ?? 'Sertifikat server tidak valid');
      case DioExceptionType.cancel:
        return NetworkException(e.message ?? 'Permintaan dibatalkan');
      case DioExceptionType.badResponse:
        return _serverException(
          e.response?.data,
          e.response?.statusCode ?? 0,
        );
      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return const NetworkException();
        }
        if (e.error is FormatException) {
          return const ParsingException();
        }
        return NetworkException(e.message ?? 'Terjadi kesalahan');
    }
  }

  ServerException _serverException(dynamic data, int statusCode) {
    String? code;
    String? message;

    if (data is Map) {
      final error = data['error'];
      if (error is Map) {
        code = error['code']?.toString();
        message = error['message']?.toString();
        // VALIDATION_ERROR: append per-field details, e.g. "email: wajib diisi".
        final details = error['details'];
        if (details is Map && details.isNotEmpty) {
          final lines = details.entries.map((e) => '${e.key}: ${e.value}');
          message = '${message ?? ''}\n${lines.join('\n')}'.trim();
        }
      } else if (data['message'] != null) {
        message = data['message'].toString();
      }
    }

    return ServerException(
      message: message ?? 'Permintaan gagal (kode $statusCode)',
      statusCode: statusCode,
      code: code,
    );
  }

  void dispose() => _dio.close();
}
