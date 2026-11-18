abstract class AuthRepository {
  /// Logs in and stores the tokens. Throws a `Failure` on error.
  ///
  /// Returns `true` when the server requires the user to change the password
  /// before using the app (`mustChangePassword`).
  Future<bool> login({required String email, required String password});

  /// Changes the logged-in user's password. The server then revokes every
  /// session, so local tokens are cleared and the user must log in again.
  /// Throws a `Failure` on error.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Revokes the session on the server (best effort) and clears local tokens.
  Future<void> logout();

  /// Asks the server to email a reset link. Always succeeds for unknown emails.
  Future<void> forgotPassword({required String email});
}
