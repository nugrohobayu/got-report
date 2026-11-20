import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/auth/session_cubit.dart';
import 'package:got_report/core/error/failures.dart';
import 'package:got_report/features/login/domain/repositories/auth_repository.dart';

enum LoginStatus { idle, loading, success, failure }

class LoginState extends Equatable {
  final LoginStatus status;

  /// One-shot error shown as a snackbar; reset on the next action.
  final String? errorMessage;

  const LoginState({
    this.status = LoginStatus.idle,
    this.errorMessage,
  });

  bool get isLoading => status == LoginStatus.loading;

  @override
  List<Object?> get props => [status, errorMessage];
}

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository authRepository;
  final SessionCubit sessionCubit;

  LoginCubit({required this.authRepository, required this.sessionCubit})
      : super(const LoginState());

  Future<void> login({required String email, required String password}) async {
    if (state.isLoading) return;
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      emit(const LoginState(
        status: LoginStatus.failure,
        errorMessage: 'Email dan kata sandi wajib diisi.',
      ));
      return;
    }

    emit(const LoginState(status: LoginStatus.loading));
    try {
      final mustChangePassword = await authRepository.login(
        email: trimmedEmail,
        password: password,
      );
      emit(const LoginState(status: LoginStatus.success));
      // The router then shows /change-password or home.
      if (mustChangePassword) {
        sessionCubit.setPasswordChangeRequired();
      } else {
        sessionCubit.setAuthenticated();
      }
    } on Failure catch (f) {
      emit(LoginState(status: LoginStatus.failure, errorMessage: f.message));
    }
  }

}
