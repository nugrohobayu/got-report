/// Thrown by data sources when the server responds with an error, either a
/// non-2xx status code or a `{success: false, error: {code, message}}` body.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  /// Backend error code, e.g. `AUTH_INVALID_CREDENTIALS`, `VALIDATION_ERROR`.
  final String? code;

  const ServerException({required this.message, this.statusCode, this.code});

  @override
  String toString() => 'ServerException($statusCode, $code): $message';
}

/// Thrown by data sources when the device has no network connectivity
/// or the request otherwise fails to reach the server.
class NetworkException implements Exception {
  final String message;

  const NetworkException([
    this.message = 'Tidak dapat terhubung ke server. Periksa koneksi internet.',
  ]);

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown by data sources when a request exceeds its allotted time.
///
/// Named `ApiTimeoutException` (rather than `TimeoutException`) to avoid
/// colliding with `dart:async`'s `TimeoutException`, which `Future.timeout`
/// throws and which is in scope wherever this exception is caught.
class ApiTimeoutException implements Exception {
  final String message;

  const ApiTimeoutException([
    this.message = 'Server terlalu lama merespons. Coba lagi.',
  ]);

  @override
  String toString() => 'ApiTimeoutException: $message';
}

/// Thrown when a successful response body cannot be parsed into the
/// expected model shape.
class ParsingException implements Exception {
  final String message;

  const ParsingException([
    this.message = 'Respons server tidak dapat dibaca.',
  ]);

  @override
  String toString() => 'ParsingException: $message';
}
