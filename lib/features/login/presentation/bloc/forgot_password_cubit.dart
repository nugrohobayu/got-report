import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ada_tugas/core/error/failures.dart';
import 'package:ada_tugas/features/login/domain/repositories/auth_repository.dart';

class ForgotPasswordState extends Equatable {
  final bool loading;

  /// Email the reset link was sent to; non-null once the request succeeded.
  final String? sentTo;

  /// One-shot error shown as a snackbar; reset on the next action.
  final String? errorMessage;

  const ForgotPasswordState({
    this.loading = false,
    this.sentTo,
    this.errorMessage,
  });

  bool get sent => sentTo != null;

  @override
  List<Object?> get props => [loading, sentTo, errorMessage];
}

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository authRepository;

  ForgotPasswordCubit({required this.authRepository})
      : super(const ForgotPasswordState());

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> submit({required String email}) async {
    if (state.loading) return;
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      emit(const ForgotPasswordState(errorMessage: 'Email wajib diisi.'));
      return;
    }
    if (!_emailPattern.hasMatch(trimmedEmail)) {
      emit(const ForgotPasswordState(
        errorMessage: 'Format email tidak valid.',
      ));
      return;
    }

    emit(const ForgotPasswordState(loading: true));
    try {
      await authRepository.forgotPassword(email: trimmedEmail);
      emit(ForgotPasswordState(sentTo: trimmedEmail));
    } on Failure catch (f) {
      emit(ForgotPasswordState(errorMessage: f.message));
    }
  }

  /// Back to the form, e.g. to send the link to another email.
  void reset() => emit(const ForgotPasswordState());
}
