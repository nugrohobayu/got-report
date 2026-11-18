import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/utils/preference_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's chosen [ThemeMode] to disk via [SharedPreferences]
/// so the preference survives app restarts.
class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences _preferences;

  ThemeCubit(this._preferences)
    : super(_modeFromString(_preferences.getString(PreferenceKeys.themeMode)));

  Future<void> toggleTheme() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    emit(next);
    await _preferences.setString(PreferenceKeys.themeMode, next.name);
  }

  static ThemeMode _modeFromString(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }
}
