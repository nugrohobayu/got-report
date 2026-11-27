import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ada_tugas/core/utils/preference_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runtime environment. Values come from the bundled `.env`, unless changed
/// on the device via the hidden env form (Profil → tap the app version 3×).
/// The override is kept in [SharedPreferences] across app restarts.
class EnvConfig {
  EnvConfig._();

  static const String _fallbackBaseUrl = 'https://jsonplaceholder.typicode.com';

  static SharedPreferences? _preferences;

  /// Call once in `main`, after `dotenv.load`.
  static void init(SharedPreferences preferences) {
    _preferences = preferences;
  }

  /// `BASE_URL` from the bundled `.env`.
  static String get defaultBaseUrl =>
      dotenv.maybeGet('BASE_URL') ?? _fallbackBaseUrl;

  /// `BASE_URL` set on this device, or `null`.
  static String? get baseUrlOverride {
    final value = _preferences?.getString(PreferenceKeys.baseUrlOverride);
    return (value == null || value.isEmpty) ? null : value;
  }

  static String get baseUrl => baseUrlOverride ?? defaultBaseUrl;

  /// Saves [url] as this device's `BASE_URL`; `null` or the default value
  /// goes back to the `.env` value.
  static Future<void> setBaseUrl(String? url) async {
    final prefs = _preferences ??= await SharedPreferences.getInstance();
    final normalized = url == null ? null : normalizeBaseUrl(url);
    if (normalized == null || normalized == normalizeBaseUrl(defaultBaseUrl)) {
      await prefs.remove(PreferenceKeys.baseUrlOverride);
    } else {
      await prefs.setString(PreferenceKeys.baseUrlOverride, normalized);
    }
  }

  /// Trims spaces and trailing slashes (endpoints start with `/`).
  static String normalizeBaseUrl(String url) =>
      url.trim().replaceFirst(RegExp(r'/+$'), '');

  /// Indonesian error message, or `null` when [url] is a usable base URL.
  static String? validateBaseUrl(String? url) {
    final value = normalizeBaseUrl(url ?? '');
    if (value.isEmpty) return 'BASE_URL wajib diisi';
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      return 'Format URL tidak valid, contoh: https://api.contoh.com';
    }
    return null;
  }
}
