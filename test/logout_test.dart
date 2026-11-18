import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:got_report/core/auth/session_cubit.dart';
import 'package:got_report/features/home/presentation/pages/home_page.dart';
import 'package:got_report/features/login/domain/repositories/auth_repository.dart';

class _FakeAuthRepository implements AuthRepository {
  int logoutCalls = 0;

  @override
  Future<bool> login({required String email, required String password}) async =>
      false;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> logout() async => logoutCalls++;

  @override
  Future<void> forgotPassword({required String email}) async {}
}

void main() {
  late _FakeAuthRepository repo;
  late SessionCubit session;

  setUp(() {
    repo = _FakeAuthRepository();
    session = SessionCubit(SessionStatus.authenticated);
  });

  tearDown(() => session.close());

  Future<void> openLogoutConfirm(WidgetTester tester) async {
    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: repo,
        child: BlocProvider.value(
          value: session,
          child: const MaterialApp(home: HomePage()),
        ),
      ),
    );
    // Settings is the second icon in the top bar (after menu).
    await tester.tap(find.byType(InkResponse).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari aplikasi?'), findsOneWidget);
  }

  testWidgets('confirming logout clears the session', (tester) async {
    await openLogoutConfirm(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Keluar'));
    await tester.pumpAndSettle();

    expect(repo.logoutCalls, 1);
    expect(session.state, SessionStatus.unauthenticated);
    expect(find.text('Sedang keluar...'), findsNothing);
  });

  testWidgets('cancelling keeps the user logged in', (tester) async {
    await openLogoutConfirm(tester);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(repo.logoutCalls, 0);
    expect(session.state, SessionStatus.authenticated);
  });
}
