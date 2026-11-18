import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the access & refresh tokens in the platform keystore
/// (Android EncryptedSharedPreferences / iOS Keychain).
class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _mustChangePasswordKey = 'must_change_password';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<bool> hasSession() async => (await readRefreshToken()) != null;

  /// Set after a login that returned `mustChangePassword: true`, so the
  /// change-password screen is still enforced after an app restart.
  Future<bool> readMustChangePassword() async =>
      (await _storage.read(key: _mustChangePasswordKey)) == 'true';

  Future<void> saveMustChangePassword(bool value) async {
    if (value) {
      await _storage.write(key: _mustChangePasswordKey, value: 'true');
    } else {
      await _storage.delete(key: _mustChangePasswordKey);
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _mustChangePasswordKey);
  }
}
