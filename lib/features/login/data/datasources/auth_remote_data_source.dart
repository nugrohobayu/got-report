import 'package:got_report/core/constants/app_constants.dart';
import 'package:got_report/core/network/api_client.dart';
import 'package:got_report/features/login/data/models/auth_token_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthTokenModel> login({
    required String email,
    required String password,
  });

  Future<void> logout({required String refreshToken});

  Future<void> forgotPassword({required String email});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  const AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<AuthTokenModel> login({
    required String email,
    required String password,
  }) async {
    final data = await apiClient.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
    );
    return AuthTokenModel.fromJson(data);
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    // TODO: send deviceFid too once push notifications are registered.
    await apiClient.post(
      ApiEndpoints.logout,
      body: {'refreshToken': refreshToken},
    );
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await apiClient.post(
      ApiEndpoints.forgotPassword,
      body: {'accountType': 'STAFF', 'email': email},
    );
  }
}
