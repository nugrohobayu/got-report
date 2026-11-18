/// Thrown by data sources when the server responds with a non-2xx status code.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Thrown by data sources when the device has no network connectivity
/// or the request otherwise fails to reach the server.
class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'No internet connection']);

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

  const ApiTimeoutException([this.message = 'Request timed out']);

  @override
  String toString() => 'ApiTimeoutException: $message';
}

/// Thrown when a successful response body cannot be parsed into the
/// expected model shape.
class ParsingException implements Exception {
  final String message;

  const ParsingException([this.message = 'Failed to parse response']);

  @override
  String toString() => 'ParsingException: $message';
}
