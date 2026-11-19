import 'package:got_report/core/constants/app_constants.dart';
import 'package:got_report/core/network/api_client.dart';
import 'package:got_report/features/login/data/models/auth_token_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthTokenModel> login({
    required String email,
    required String password,
  });

  /// [deviceFid] detaches this device from push notifications.
  Future<void> logout({required String refreshToken, String? deviceFid});

  Future<void> forgotPassword({required String email});

  /// The server revokes every session afterwards.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
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
  Future<void> logout({required String refreshToken, String? deviceFid}) async {
    await apiClient.post(
      ApiEndpoints.logout,
      body: {
        'refreshToken': refreshToken,
        if (deviceFid != null) 'deviceFid': deviceFid,
      },
    );
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await apiClient.post(
      ApiEndpoints.forgotPassword,
      body: {'accountType': 'STAFF', 'email': email},
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await apiClient.put(
      ApiEndpoints.changePassword,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }
}
