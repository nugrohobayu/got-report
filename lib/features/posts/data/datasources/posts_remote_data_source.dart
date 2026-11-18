import 'package:got_report/core/constants/app_constants.dart';
import 'package:got_report/core/network/api_client.dart';
import 'package:got_report/features/posts/data/models/post_model.dart';

abstract class PostsRemoteDataSource {
  Future<List<PostModel>> getPosts();
}

class PostsRemoteDataSourceImpl implements PostsRemoteDataSource {
  final ApiClient apiClient;

  const PostsRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<PostModel>> getPosts() async {
    final response = await apiClient.get(ApiEndpoints.posts);
    return (response as List)
        .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
