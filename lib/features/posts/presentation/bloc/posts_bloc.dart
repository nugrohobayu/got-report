import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/error/failures.dart';
import 'package:got_report/features/posts/domain/usecases/get_posts.dart';
import 'package:got_report/features/posts/presentation/bloc/posts_event.dart';
import 'package:got_report/features/posts/presentation/bloc/posts_state.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final GetPosts getPosts;

  PostsBloc({required this.getPosts}) : super(const PostsState()) {
    on<PostsRequested>(_onPostsRequested);
    on<PostsRefreshed>(_onPostsRequested);
  }

  Future<void> _onPostsRequested(
    PostsEvent event,
    Emitter<PostsState> emit,
  ) async {
    emit(state.copyWith(status: PostsStatus.loading));
    try {
      final posts = await getPosts();
      emit(state.copyWith(status: PostsStatus.success, posts: posts));
    } on Failure catch (failure) {
      emit(
        state.copyWith(
            status: PostsStatus.error, errorMessage: failure.message),
      );
    } catch (e) {
      emit(
        state.copyWith(status: PostsStatus.error, errorMessage: e.toString()),
      );
    }
  }
}
