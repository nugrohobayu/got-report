import 'package:got_report/core/constants/app_constants.dart';
import 'package:got_report/core/network/api_client.dart';
import 'package:got_report/features/profil/data/models/user_profile_model.dart';
import 'package:got_report/features/profil/domain/entities/user_profile.dart';

abstract class ProfileRemoteDataSource {
  /// `GET /api/v1/me`.
  Future<UserProfile> getMe();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient apiClient;

  const ProfileRemoteDataSourceImpl(this.apiClient);

  @override
  Future<UserProfile> getMe() async {
    final data = await apiClient.get(ApiEndpoints.me);
    return UserProfileModel.fromJson(data);
  }
}
