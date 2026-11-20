import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures. Repositories translate
/// data-layer exceptions into a [Failure] so the presentation layer never
/// depends on data-layer types.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  /// Backend error code, e.g. `AUTH_INVALID_CREDENTIALS`.
  final String? code;

  /// Backend `error.details`, e.g. `{radiusM: 150, distanceM: 498}`.
  final Map<String, dynamic> details;

  const ServerFailure(super.message, {this.code, this.details = const {}});

  @override
  List<Object?> get props => [message, code, details];
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message);
}

class ParsingFailure extends Failure {
  const ParsingFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
