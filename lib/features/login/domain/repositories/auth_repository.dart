abstract class AuthRepository {
  /// Logs in and stores the tokens. Throws a `Failure` on error.
  Future<void> login({required String email, required String password});

  /// Revokes the session on the server (best effort) and clears local tokens.
  Future<void> logout();

  /// Asks the server to email a reset link. Always succeeds for unknown emails.
  Future<void> forgotPassword({required String email});
}
