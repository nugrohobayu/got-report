import 'package:flutter_bloc/flutter_bloc.dart';

enum SessionStatus { authenticated, unauthenticated }

/// App-wide login state. The router listens to it to guard routes, so
/// flipping it is enough to move the user to / away from the login screen.
class SessionCubit extends Cubit<SessionStatus> {
  SessionCubit(super.initialState);

  bool get isAuthenticated => state == SessionStatus.authenticated;

  void setAuthenticated() => emit(SessionStatus.authenticated);

  void setUnauthenticated() => emit(SessionStatus.unauthenticated);
}
