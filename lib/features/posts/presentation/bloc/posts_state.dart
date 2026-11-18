import 'package:equatable/equatable.dart';
import 'package:got_report/features/posts/domain/entities/post.dart';

enum PostsStatus { initial, loading, success, error }

class PostsState extends Equatable {
  final PostsStatus status;
  final List<Post> posts;
  final String? errorMessage;

  const PostsState({
    this.status = PostsStatus.initial,
    this.posts = const [],
    this.errorMessage,
  });

  PostsState copyWith({
    PostsStatus? status,
    List<Post>? posts,
    String? errorMessage,
  }) {
    return PostsState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, posts, errorMessage];
}
