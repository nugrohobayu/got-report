import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:got_report/core/auth/session_cubit.dart';
import 'package:got_report/core/utils/app_logger.dart';
import 'package:got_report/features/change_password/presentation/pages/change_password_page.dart';
import 'package:got_report/features/download_test/presentation/pages/download_test_page.dart';
import 'package:got_report/features/form_dinamis/presentation/pages/task_form_page.dart';
import 'package:got_report/features/home/presentation/pages/home_page.dart';
import 'package:got_report/features/login/presentation/pages/forgot_password_page.dart';
import 'package:got_report/features/login/presentation/pages/login_page.dart';
import 'package:got_report/features/mulai_tugas/presentation/pages/start_task_page.dart';

class AppRouter {
  AppRouter._();

  static const _login = '/login';
  static const _changePassword = '/change-password';
  static const forgotPasswordPath = '/forgot-password';

  /// Routes are guarded by [session]: logged-out users always land on
  /// `/login`, users who must change their password are kept on
  /// `/change-password`, and fully logged-in users never see either.
  static GoRouter create(SessionCubit session) => GoRouter(
        initialLocation: _startFor(session),
        refreshListenable: _StreamListenable(session.stream),
        observers: [_LoggingNavigatorObserver()],
        routes: [
          GoRoute(
            path: _login,
            name: 'login',
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: forgotPasswordPath,
            name: 'forgotPassword',
            builder: (context, state) => ForgotPasswordPage(
              initialEmail: state.extra is String ? state.extra! as String : null,
            ),
          ),
          GoRoute(
            path: _changePassword,
            name: 'changePassword',
            builder: (context, state) => const ChangePasswordPage(),
          ),
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/tasks/:id/start',
            name: startTaskRouteName,
            builder: (context, state) =>
                StartTaskPage(taskId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/tasks/:id/form',
            name: taskFormRouteName,
            builder: (context, state) => TaskFormPage(
              taskId: state.pathParameters['id']!,
              fromFirstStep: fromFirstStepQuery.entries.every(
                (e) => state.uri.queryParameters[e.key] == e.value,
              ),
            ),
          ),
          GoRoute(
            path: '/download-test',
            name: 'downloadTest',
            builder: (context, state) => const DownloadTestPage(),
          ),
        ],
        redirect: (context, state) {
          AppLogger.routing('Navigating to ${state.uri}');
          final location = state.matchedLocation;
          // Logged out / must change password: only the matching screen.
          if (!session.isAuthenticated) {
            final target = _startFor(session);
            // Forgot password is reachable from login while logged out.
            if (target == _login && location == forgotPasswordPath) {
              return null;
            }
            return location == target ? null : target;
          }
          if (location == _login ||
              location == _changePassword ||
              location == forgotPasswordPath) {
            return '/';
          }
          return null;
        },
      );

  static String _startFor(SessionCubit session) => switch (session.state) {
        SessionStatus.unauthenticated => _login,
        SessionStatus.passwordChangeRequired => _changePassword,
        SessionStatus.authenticated => '/',
      };
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
