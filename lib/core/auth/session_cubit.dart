import 'package:flutter_bloc/flutter_bloc.dart';

enum SessionStatus {
  authenticated,

  /// Logged in, but the server requires a new password before the app can
  /// be used (`mustChangePassword` from login).
  passwordChangeRequired,

  unauthenticated,
}

/// App-wide login state. The router listens to it to guard routes, so
/// flipping it is enough to move the user to / away from the login screen.
class SessionCubit extends Cubit<SessionStatus> {
  SessionCubit(super.initialState);

  /// Fully logged in: every route is allowed.
  bool get isAuthenticated => state == SessionStatus.authenticated;

  void setAuthenticated() => emit(SessionStatus.authenticated);

  void setPasswordChangeRequired() =>
      emit(SessionStatus.passwordChangeRequired);

  void setUnauthenticated() => emit(SessionStatus.unauthenticated);
}
