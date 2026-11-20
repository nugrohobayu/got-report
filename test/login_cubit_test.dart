import 'package:flutter_test/flutter_test.dart';
import 'package:got_report/core/auth/session_cubit.dart';
import 'package:got_report/core/error/failures.dart';
import 'package:got_report/features/change_password/presentation/bloc/change_password_cubit.dart';
import 'package:got_report/features/login/domain/repositories/auth_repository.dart';
import 'package:got_report/features/login/presentation/bloc/forgot_password_cubit.dart';
import 'package:got_report/features/login/presentation/bloc/login_cubit.dart';

class _FakeAuthRepository implements AuthRepository {
  Failure? loginFailure;
  Failure? changePasswordFailure;
  Failure? forgotFailure;
  bool mustChangePassword = false;
  String? lastEmail;
  String? lastNewPassword;

  @override
  Future<bool> login({required String email, required String password}) async {
    lastEmail = email;
    if (loginFailure != null) throw loginFailure!;
    return mustChangePassword;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    lastNewPassword = newPassword;
    if (changePasswordFailure != null) throw changePasswordFailure!;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> forgotPassword({required String email}) async {
    lastEmail = email;
    if (forgotFailure != null) throw forgotFailure!;
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

  test('mustChangePassword sends the session to change password', () async {
    repo.mustChangePassword = true;

    await cubit.login(email: 'teknisi@contoh.id', password: 'Sementara-1');

    expect(cubit.state.status, LoginStatus.success);
    expect(session.state, SessionStatus.passwordChangeRequired);
    expect(session.isAuthenticated, isFalse);
  });

  group('ChangePasswordCubit', () {
    late ChangePasswordCubit changeCubit;

    setUp(() {
      session.setPasswordChangeRequired();
      changeCubit =
          ChangePasswordCubit(authRepository: repo, sessionCubit: session);
    });

    tearDown(() => changeCubit.close());

    Future<void> submit(String current, String next, String confirm) =>
        changeCubit.submit(
          currentPassword: current,
          newPassword: next,
          confirmPassword: confirm,
        );

    test('success sends the user back to login', () async {
      await submit('Sementara-1', 'Baru-12345', 'Baru-12345');

      expect(repo.lastNewPassword, 'Baru-12345');
      expect(changeCubit.state.errorMessage, isNull);
      expect(changeCubit.state.successMessage, isNotNull);
      // The server revokes every session after a password change.
      expect(session.state, SessionStatus.unauthenticated);
    });

    test('invalid input is rejected without calling the API', () async {
      await submit('Sementara-1', 'pendek', 'pendek');
      expect(changeCubit.state.errorMessage, contains('minimal'));

      await submit('Sementara-1', 'Baru-12345', 'Beda-12345');
      expect(changeCubit.state.errorMessage, contains('tidak sama'));

      await submit('Sama-12345', 'Sama-12345', 'Sama-12345');
      expect(changeCubit.state.errorMessage, contains('berbeda'));

      expect(repo.lastNewPassword, isNull);
      expect(session.state, SessionStatus.passwordChangeRequired);
    });

    test('backend error keeps the user on change password', () async {
      repo.changePasswordFailure = const ServerFailure('Kata sandi lama salah');

      await submit('salah', 'Baru-12345', 'Baru-12345');

      expect(changeCubit.state.errorMessage, 'Kata sandi lama salah');
      expect(session.state, SessionStatus.passwordChangeRequired);
    });
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

  group('ForgotPasswordCubit', () {
    late ForgotPasswordCubit forgot;

    setUp(() => forgot = ForgotPasswordCubit(authRepository: repo));
    tearDown(() => forgot.close());

    test('empty or malformed email is rejected without calling the API',
        () async {
      await forgot.submit(email: ' ');
      expect(forgot.state.errorMessage, isNotNull);

      await forgot.submit(email: 'bukan-email');
      expect(forgot.state.errorMessage, contains('tidak valid'));

      expect(repo.lastEmail, isNull);
      expect(forgot.state.sent, isFalse);
    });

    test('success trims the email and shows the sent state', () async {
      await forgot.submit(email: '  teknisi@contoh.id ');

      expect(repo.lastEmail, 'teknisi@contoh.id');
      expect(forgot.state.sentTo, 'teknisi@contoh.id');
      expect(forgot.state.errorMessage, isNull);

      forgot.reset();
      expect(forgot.state.sent, isFalse);
    });

    test('backend error message is shown as-is', () async {
      repo.forgotFailure = const ServerFailure('Terlalu banyak permintaan');

      await forgot.submit(email: 'teknisi@contoh.id');

      expect(forgot.state.errorMessage, 'Terlalu banyak permintaan');
      expect(forgot.state.sent, isFalse);
    });
  });
}
