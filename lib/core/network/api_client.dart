import 'dart:io';

import 'package:dio/dio.dart';

import 'package:got_report/core/constants/app_constants.dart';
import 'package:got_report/core/error/exceptions.dart';
import 'package:got_report/core/network/logging_interceptor.dart';

/// Thin, reusable wrapper around [Dio] that centralizes the base URL,
/// timeouts, and error translation so that data sources never touch
/// `package:dio` directly.
class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? AppConstants.baseUrl,
                connectTimeout: AppConstants.connectTimeout,
                receiveTimeout: AppConstants.receiveTimeout,
              ),
            ) {
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

  Future<dynamic> _send(Future<Response> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      throw _translateError(e);
    }
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
        return NetworkException(e.message ?? 'Bad certificate');
      case DioExceptionType.cancel:
        return NetworkException(e.message ?? 'Request cancelled');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        return ServerException(
          message: _extractErrorMessage(e.response?.data, statusCode),
          statusCode: statusCode,
        );
      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return const NetworkException();
        }
        if (e.error is FormatException) {
          return const ParsingException();
        }
        return NetworkException(e.message ?? 'Unknown error');
    }
  }

  String _extractErrorMessage(dynamic data, int statusCode) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'Request failed with status code $statusCode';
  }

  void dispose() => _dio.close();
}
