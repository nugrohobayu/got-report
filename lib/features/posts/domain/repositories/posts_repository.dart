import 'package:got_report/features/posts/domain/entities/post.dart';

abstract class PostsRepository {
  Future<List<Post>> getPosts();
}
