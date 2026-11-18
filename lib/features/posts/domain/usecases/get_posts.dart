import 'package:got_report/features/posts/domain/entities/post.dart';
import 'package:got_report/features/posts/domain/repositories/posts_repository.dart';

class GetPosts {
  final PostsRepository repository;

  const GetPosts(this.repository);

  Future<List<Post>> call() => repository.getPosts();
}
