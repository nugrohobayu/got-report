import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/auth/session_cubit.dart';
import 'package:got_report/core/error/failures.dart';
import 'package:got_report/features/login/domain/repositories/auth_repository.dart';

enum LoginStatus { idle, loading, success, failure }

class LoginState extends Equatable {
  final LoginStatus status;
  final bool forgotLoading;

  /// One-shot messages shown as a snackbar; reset on the next action.
  final String? errorMessage;
  final String? infoMessage;

  const LoginState({
    this.status = LoginStatus.idle,
    this.forgotLoading = false,
    this.errorMessage,
    this.infoMessage,
  });

  bool get isLoading => status == LoginStatus.loading;

  @override
  List<Object?> get props => [status, forgotLoading, errorMessage, infoMessage];
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

  Future<void> forgotPassword({required String email}) async {
    if (state.forgotLoading || state.isLoading) return;
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      emit(const LoginState(
        errorMessage:
            'Isi email terlebih dahulu, lalu tekan "Lupa kata sandi?".',
      ));
      return;
    }

    emit(const LoginState(forgotLoading: true));
    try {
      await authRepository.forgotPassword(email: trimmedEmail);
      emit(const LoginState(
        infoMessage:
            'Jika email terdaftar, link atur ulang kata sandi sudah dikirim. '
            'Periksa kotak masuk email Anda.',
      ));
    } on Failure catch (f) {
      emit(LoginState(errorMessage: f.message));
    }
  }
}
