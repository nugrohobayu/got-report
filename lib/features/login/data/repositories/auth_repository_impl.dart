import 'package:got_report/core/auth/token_storage.dart';
import 'package:got_report/core/error/exceptions.dart';
import 'package:got_report/core/error/failures.dart';
import 'package:got_report/core/utils/app_logger.dart';
import 'package:got_report/features/login/data/datasources/auth_remote_data_source.dart';
import 'package:got_report/features/login/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenStorage tokenStorage;

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenStorage,
  });

  @override
  Future<bool> login({required String email, required String password}) {
    return _guard(() async {
      final token = await remoteDataSource.login(
        email: email,
        password: password,
      );
      await tokenStorage.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );
      await tokenStorage.saveMustChangePassword(token.mustChangePassword);
      return token.mustChangePassword;
    });
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _guard(() async {
      await remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      // The server revoked every session, so the stored tokens are dead.
      await tokenStorage.clear();
    });
  }

  @override
  Future<void> logout() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    try {
      if (refreshToken != null) {
        await remoteDataSource.logout(refreshToken: refreshToken);
      }
    } catch (e) {
      // Offline or already revoked: still log out locally.
      AppLogger.api('Logout request failed: $e');
    } finally {
      await tokenStorage.clear();
    }
  }

  @override
  Future<void> forgotPassword({required String email}) {
    return _guard(() => remoteDataSource.forgotPassword(email: email));
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ServerException catch (e) {
      throw ServerFailure(e.message, code: e.code);
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
}
