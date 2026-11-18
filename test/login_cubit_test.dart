import 'package:flutter_test/flutter_test.dart';
import 'package:got_report/core/auth/session_cubit.dart';
import 'package:got_report/core/error/failures.dart';
import 'package:got_report/features/login/domain/repositories/auth_repository.dart';
import 'package:got_report/features/login/presentation/bloc/login_cubit.dart';

class _FakeAuthRepository implements AuthRepository {
  Failure? loginFailure;
  String? lastEmail;

  @override
  Future<void> login({required String email, required String password}) async {
    lastEmail = email;
    if (loginFailure != null) throw loginFailure!;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> forgotPassword({required String email}) async {
    lastEmail = email;
  }
}

void main() {
  late _FakeAuthRepository repo;
  late SessionCubit session;
  late LoginCubit cubit;

  setUp(() {
    repo = _FakeAuthRepository();
    session = SessionCubit(SessionStatus.unauthenticated);
    cubit = LoginCubit(authRepository: repo, sessionCubit: session);
  });

  tearDown(() async {
    await cubit.close();
    await session.close();
  });

  test('successful login trims email and authenticates the session', () async {
    await cubit.login(email: '  teknisi@contoh.id ', password: 'Rahasia-123');

    expect(repo.lastEmail, 'teknisi@contoh.id');
    expect(cubit.state.status, LoginStatus.success);
    expect(session.state, SessionStatus.authenticated);
  });

  test('backend error message is shown as-is', () async {
    repo.loginFailure = const ServerFailure(
      'Email atau password salah',
      code: 'AUTH_INVALID_CREDENTIALS',
    );

    await cubit.login(email: 'a@b.id', password: 'salah');

    expect(cubit.state.status, LoginStatus.failure);
    expect(cubit.state.errorMessage, 'Email atau password salah');
    expect(session.state, SessionStatus.unauthenticated);
  });

  test('empty fields are rejected without calling the API', () async {
    await cubit.login(email: ' ', password: '');

    expect(repo.lastEmail, isNull);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('forgot password requires an email', () async {
    await cubit.forgotPassword(email: '');
    expect(repo.lastEmail, isNull);
    expect(cubit.state.errorMessage, isNotNull);

    await cubit.forgotPassword(email: 'teknisi@contoh.id');
    expect(repo.lastEmail, 'teknisi@contoh.id');
    expect(cubit.state.infoMessage, isNotNull);
  });
}
