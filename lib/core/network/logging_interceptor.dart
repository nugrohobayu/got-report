import 'package:dio/dio.dart';

import 'package:got_report/core/utils/app_logger.dart';

/// Logs every request/response (or error) pair through [AppLogger.api],
/// matching the ":: PROCESSING ::" / ":: FINALLY ::" format the app has
/// always used for API traffic.
class LoggingInterceptor extends Interceptor {
  static const _stopwatchKey = '_logging_interceptor_stopwatch';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_stopwatchKey] = Stopwatch()..start();
    AppLogger.api(
      (StringBuffer()
            ..writeln(':: PROCESSING ::')
            ..writeln('[${options.method}] : ${options.uri}')
            ..writeln('[Request Headers] : ')
            ..writeln('\t${options.headers}')
            ..writeln('[Request Body] : ')
            ..write('\t${options.data ?? '-'}'))
          .toString(),
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logFinally(
      response.requestOptions,
      responseCode: response.statusCode,
      responseHeaders: response.headers.map,
      responseBody: response.data,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logFinally(err.requestOptions, error: err.message ?? err.toString());
    handler.next(err);
  }

  void _logFinally(
    RequestOptions options, {
    int? responseCode,
    Map<String, List<String>>? responseHeaders,
    dynamic responseBody,
    String? error,
  }) {
    final stopwatch = options.extra[_stopwatchKey] as Stopwatch?;
    stopwatch?.stop();

    final buffer = StringBuffer()
      ..writeln(':: FINALLY ::')
      ..writeln('[${options.method}] : ${options.uri}')
      ..writeln('[Request Headers] : ')
      ..writeln('\t${options.headers}')
      ..writeln('[Request Body] : ')
      ..writeln('\t${options.data ?? '-'}');

    if (error != null) {
      buffer
        ..writeln('[Error] : ')
        ..writeln('\t$error');
    } else {
      buffer
        ..writeln('[Response Code] : ')
        ..writeln('\t$responseCode')
        ..writeln('[Response Headers] : ')
        ..writeln('\t$responseHeaders')
        ..writeln('[Response Body Raw] : ')
        ..writeln('\t${_truncate(responseBody?.toString() ?? '')}');
    }

    buffer.write('[TIME CALL] --> ${stopwatch?.elapsed.inMilliseconds ?? 0}ms');
    AppLogger.api(buffer.toString());
  }

  String _truncate(String body, {int maxLength = 1000}) {
    if (body.length <= maxLength) return body;
    return '${body.substring(0, maxLength)}... (truncated)';
  }
}
