import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ada_tugas/core/auth/session_cubit.dart';
import 'package:ada_tugas/core/error/failures.dart';
import 'package:ada_tugas/features/login/domain/repositories/auth_repository.dart';

class ChangePasswordState extends Equatable {
  final bool loading;

  /// One-shot messages shown as a snackbar; reset on the next action.
  final String? errorMessage;
  final String? successMessage;

  const ChangePasswordState({
    this.loading = false,
    this.errorMessage,
    this.successMessage,
  });

  @override
  List<Object?> get props => [loading, errorMessage, successMessage];
}

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  static const minLength = 8;

  final AuthRepository authRepository;
  final SessionCubit sessionCubit;

  ChangePasswordCubit(
      {required this.authRepository, required this.sessionCubit})
      : super(const ChangePasswordState());

  Future<void> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (state.loading) return;

    final error = _validate(currentPassword, newPassword, confirmPassword);
    if (error != null) {
      emit(ChangePasswordState(errorMessage: error));
      return;
    }

    emit(const ChangePasswordState(loading: true));
    try {
      await authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      emit(const ChangePasswordState(
        successMessage:
            'Kata sandi berhasil diubah. Silakan masuk dengan kata sandi baru.',
      ));
      // The server revoked every session: the router goes back to /login.
      sessionCubit.setUnauthenticated();
    } on Failure catch (f) {
      emit(ChangePasswordState(errorMessage: f.message));
    }
  }

  static String? _validate(String current, String next, String confirm) {
    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      return 'Semua kolom wajib diisi.';
    }
    if (next.length < minLength) {
      return 'Kata sandi baru minimal $minLength karakter.';
    }
    if (next == current) {
      return 'Kata sandi baru harus berbeda dari kata sandi lama.';
    }
    if (next != confirm) {
      return 'Konfirmasi kata sandi tidak sama.';
    }
    return null;
  }
}
