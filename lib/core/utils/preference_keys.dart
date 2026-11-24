class PreferenceKeys {
  PreferenceKeys._();

  static const String themeMode = 'theme_mode';

  /// `false` when the user turned push notifications off in Profil.
  static const String pushEnabled = 'push_enabled';

  /// `BASE_URL` set from the hidden env form (3 taps on the app version);
  /// overrides the bundled `.env`.
  static const String baseUrlOverride = 'env_base_url';
}
