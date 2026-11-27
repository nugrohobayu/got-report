import 'package:ada_tugas/core/error/exceptions.dart';
import 'package:ada_tugas/core/error/failures.dart';

/// Runs a data-source call and turns data-layer exceptions into [Failure]s,
/// keeping the backend error code and details.
Future<T> guardFailures<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on ServerException catch (e) {
    throw ServerFailure(e.message, code: e.code, details: e.details);
  } on NetworkException catch (e) {
    throw NetworkFailure(e.message);
  } on ApiTimeoutException catch (e) {
    throw TimeoutFailure(e.message);
  } on ParsingException catch (e) {
    throw ParsingFailure(e.message);
  } on Failure {
    rethrow;
  } catch (e) {
    throw UnknownFailure(e.toString());
  }
}
