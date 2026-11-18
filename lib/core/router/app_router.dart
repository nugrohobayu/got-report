import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:got_report/core/utils/app_logger.dart';
import 'package:got_report/features/download_test/presentation/pages/download_test_page.dart';
import 'package:got_report/features/login/presentation/pages/login_page.dart';
import 'package:got_report/features/posts/domain/entities/post.dart';
import 'package:got_report/features/posts/presentation/pages/post_detail_page.dart';
import 'package:got_report/features/posts/presentation/pages/posts_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    observers: [_LoggingNavigatorObserver()],
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        name: 'posts',
        builder: (context, state) => const PostsPage(),
      ),
      GoRoute(
        path: '/posts/:id',
        name: 'postDetail',
        builder: (context, state) {
          final post = state.extra as Post;
          return PostDetailPage(post: post);
        },
      ),
      GoRoute(
        path: '/download-test',
        name: 'downloadTest',
        builder: (context, state) => const DownloadTestPage(),
      ),
    ],
    redirect: (context, state) {
      AppLogger.routing('Navigating to ${state.uri}');
      return null;
    },
  );
}

class _LoggingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.routing(
      'didPush: ${_nameOf(route)} (from ${_nameOf(previousRoute)})',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.routing(
      'didPop: ${_nameOf(route)} (back to ${_nameOf(previousRoute)})',
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.routing('didRemove: ${_nameOf(route)}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AppLogger.routing(
      'didReplace: ${_nameOf(oldRoute)} -> ${_nameOf(newRoute)}',
    );
  }

  String _nameOf(Route<dynamic>? route) => route?.settings.name ?? 'unknown';
}
