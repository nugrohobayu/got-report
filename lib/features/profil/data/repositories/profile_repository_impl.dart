import 'package:ada_tugas/core/error/exceptions.dart';
import 'package:ada_tugas/core/error/failures.dart';
import 'package:ada_tugas/features/profil/data/datasources/profile_remote_data_source.dart';
import 'package:ada_tugas/features/profil/domain/entities/user_profile.dart';
import 'package:ada_tugas/features/profil/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  const ProfileRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserProfile> getMe() async {
    try {
      return await remoteDataSource.getMe();
    } on ServerException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ApiTimeoutException catch (e) {
      throw TimeoutFailure(e.message);
    } on ParsingException catch (e) {
      throw ParsingFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }
}
