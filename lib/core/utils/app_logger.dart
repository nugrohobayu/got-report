import 'dart:developer' as developer;

/// Thin wrapper around `dart:developer`'s `log` so call sites don't need to
/// pass a `name` every time and output is easy to filter in DevTools/console.
class AppLogger {
  AppLogger._();

  static void routing(String message) => _log(message, name: 'Routing');

  static void api(String message) => _log(message, name: 'Api');

  static void _log(String message, {required String name}) {
    developer.log(message, name: name);
  }
}
