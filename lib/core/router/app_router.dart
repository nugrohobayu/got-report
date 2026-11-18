import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:got_report/core/auth/session_cubit.dart';
import 'package:got_report/core/utils/app_logger.dart';
import 'package:got_report/features/download_test/presentation/pages/download_test_page.dart';
import 'package:got_report/features/home/presentation/pages/home_page.dart';
import 'package:got_report/features/login/presentation/pages/login_page.dart';

class AppRouter {
  AppRouter._();

  /// Routes are guarded by [session]: logged-out users always land on
  /// `/login`, logged-in users never see it.
  static GoRouter create(SessionCubit session) => GoRouter(
        initialLocation: session.isAuthenticated ? '/' : '/login',
        refreshListenable: _StreamListenable(session.stream),
        observers: [_LoggingNavigatorObserver()],
        routes: [
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/download-test',
            name: 'downloadTest',
            builder: (context, state) => const DownloadTestPage(),
          ),
        ],
        redirect: (context, state) {
          AppLogger.routing('Navigating to ${state.uri}');
          final onLogin = state.matchedLocation == '/login';
          if (!session.isAuthenticated) return onLogin ? null : '/login';
          if (onLogin) return '/';
          return null;
        },
      );
}

/// Bridges a [Stream] to the [Listenable] that GoRouter re-evaluates
/// redirects on.
class _StreamListenable extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  _StreamListenable(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
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
