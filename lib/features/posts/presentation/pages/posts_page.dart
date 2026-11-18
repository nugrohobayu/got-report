import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:got_report/core/auth/session_cubit.dart';
import 'package:got_report/core/theme/theme_cubit.dart';
import 'package:got_report/features/login/domain/repositories/auth_repository.dart';
import 'package:got_report/core/widgets/error_view.dart';
import 'package:got_report/features/posts/domain/repositories/posts_repository.dart';
import 'package:got_report/features/posts/domain/usecases/get_posts.dart';
import 'package:got_report/features/posts/presentation/bloc/posts_bloc.dart';
import 'package:got_report/features/posts/presentation/bloc/posts_event.dart';
import 'package:got_report/features/posts/presentation/bloc/posts_state.dart';
import 'package:got_report/features/posts/presentation/widgets/post_list_item.dart';

class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PostsBloc(getPosts: GetPosts(context.read<PostsRepository>()))
            ..add(const PostsRequested()),
      child: const _PostsView(),
    );
  }
}

class _PostsView extends StatelessWidget {
  const _PostsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Test download',
            onPressed: () => context.push('/download-test'),
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6_outlined),
            tooltip: 'Toggle theme',
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () async {
              final session = context.read<SessionCubit>();
              await context.read<AuthRepository>().logout();
              session.setUnauthenticated();
            },
          ),
        ],
      ),
      body: BlocBuilder<PostsBloc, PostsState>(
        builder: (context, state) {
          switch (state.status) {
            case PostsStatus.initial:
            case PostsStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case PostsStatus.error:
              return ErrorView(
                message: state.errorMessage ?? 'Something went wrong',
                onRetry: () =>
                    context.read<PostsBloc>().add(const PostsRequested()),
              );
            case PostsStatus.success:
              return RefreshIndicator(
                onRefresh: () async {
                  final bloc = context.read<PostsBloc>();
                  bloc.add(const PostsRefreshed());
                  await bloc.stream.firstWhere(
                    (s) => s.status != PostsStatus.loading,
                  );
                },
                child: ListView.builder(
                  itemCount: state.posts.length,
                  itemBuilder: (context, index) {
                    final post = state.posts[index];
                    return PostListItem(
                      post: post,
                      onTap: () =>
                          context.push('/posts/${post.id}', extra: post),
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}
