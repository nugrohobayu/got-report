import 'package:got_report/core/error/exceptions.dart';
import 'package:got_report/core/error/failures.dart';
import 'package:got_report/features/posts/data/datasources/posts_remote_data_source.dart';
import 'package:got_report/features/posts/domain/entities/post.dart';
import 'package:got_report/features/posts/domain/repositories/posts_repository.dart';

class PostsRepositoryImpl implements PostsRepository {
  final PostsRemoteDataSource remoteDataSource;

  const PostsRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Post>> getPosts() async {
    try {
      return await remoteDataSource.getPosts();
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
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
