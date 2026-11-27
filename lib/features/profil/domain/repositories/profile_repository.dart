import 'package:ada_tugas/features/profil/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  /// The logged-in user's profile. Throws a `Failure` on error.
  Future<UserProfile> getMe();
}
