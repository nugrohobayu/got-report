import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:got_report/core/auth/session_cubit.dart';
import 'package:got_report/core/location/location_service.dart';
import 'package:got_report/core/network/api_client.dart';
import 'package:got_report/core/push/push_service.dart';
import 'package:got_report/core/theme/theme_cubit.dart';
import 'package:got_report/features/home/presentation/pages/home_page.dart';
import 'package:got_report/features/login/domain/repositories/auth_repository.dart';
import 'package:got_report/features/profil/domain/entities/user_profile.dart';
import 'package:got_report/features/profil/domain/repositories/profile_repository.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:got_report/features/tugas_hari_ini/domain/repositories/task_repository.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_location_service.dart';

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<UserProfile> getMe() async => const UserProfile(
        id: 'u1',
        fullName: 'Teknisi A',
        email: 'teknisi@contoh.id',
        roleNames: ['Petugas'],
      );
}

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

class _EmptyTaskRepository implements TaskRepository {
  @override
  Future<List<TaskSummary>> getMyTasks({
    required DateTime from,
    required DateTime to,
  }) async =>
      const [];
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  late _FakeAuthRepository repo;
  late SessionCubit session;

  setUp(() {
    repo = _FakeAuthRepository();
    session = SessionCubit(SessionStatus.authenticated);
  });

  tearDown(() => session.close());

  Future<void> openLogoutConfirm(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: repo),
          RepositoryProvider<TaskRepository>.value(
            value: _EmptyTaskRepository(),
          ),
          RepositoryProvider<LocationService>.value(
            value: FakeLocationService(),
          ),
          RepositoryProvider<ProfileRepository>.value(
            value: _FakeProfileRepository(),
          ),
          // No Firebase in tests: push is "unavailable", row hidden.
          RepositoryProvider<PushService>.value(
            value: PushService(ApiClient(baseUrl: 'http://localhost'), prefs),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: session),
            BlocProvider(create: (_) => ThemeCubit(prefs)),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      ),
    );
    // Logout lives in the Profil tab of the bottom navbar.
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Teknisi A'), findsOneWidget);
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
