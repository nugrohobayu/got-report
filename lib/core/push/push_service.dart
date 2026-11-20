import 'dart:async';
import 'dart:io';

import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:got_report/core/constants/app_constants.dart';
import 'package:got_report/core/error/exceptions.dart';
import 'package:got_report/core/network/api_client.dart';
import 'package:got_report/core/utils/app_logger.dart';
import 'package:got_report/core/utils/preference_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the Notifikasi switch in Profil shows.
enum PushStatus {
  /// Push cannot work here (no Firebase, unsupported platform).
  unavailable,

  /// On, and the OS allows notifications.
  on,

  /// Turned off by the user in the app.
  off,

  /// On in the app, but notifications are blocked in the phone settings.
  blocked,
}

/// Push notifications (FCM). The backend sends to this device by its
/// Firebase Installation ID (FID): FCM's direct-send target, available after
/// `FirebaseMessaging.register()` (see [FirebaseMessaging.onRegistered]).
///
/// The user can turn push off in Profil ([setEnabled]); the device is then
/// removed on the server (`DELETE /api/v1/field/devices`) and not
/// registered again until turned back on.
///
/// The server can turn push off (`GET /api/v1/public/config` →
/// `features["notification-push"]`); then nothing is registered and the
/// switch in Profil is hidden ([PushStatus.unavailable]).
///
/// Every network call is best effort: push is optional, so failures are
/// only logged and never block login, logout or the UI.
class PushService {
  final ApiClient apiClient;
  final SharedPreferences preferences;

  PushService(this.apiClient, this.preferences);

  StreamSubscription<String>? _registeredSub;

  /// `features["notification-push"]` from `GET /api/v1/public/config`;
  /// `null` until read (or when the read failed: then we still try, and a
  /// 404 from `/field/devices` is handled by [_guard]).
  bool? _serverPush;
  Future<void>? _configLoad;

  bool get _deviceSupported =>
      (Platform.isAndroid || Platform.isIOS) && Firebase.apps.isNotEmpty;

  /// Push can work here: the device has Firebase and the server has not
  /// turned push off.
  bool get isSupported => _deviceSupported && _serverPush != false;

  /// Reads the server's push switch once per app run (retried on the next
  /// call if the read failed). Skipped where push cannot work anyway.
  Future<void> loadServerConfig() {
    if (!_deviceSupported || _serverPush != null) return Future.value();
    return _configLoad ??= _readServerConfig().whenComplete(() {
      _configLoad = null;
    });
  }

  Future<void> _readServerConfig() async {
    try {
      final data = await apiClient.get(ApiEndpoints.publicConfig);
      final features = data is Map ? data['features'] : null;
      _serverPush = features is Map && features['notification-push'] == true;
      if (_serverPush == false) {
        AppLogger.api('Push: turned off on this server (public config)');
      }
    } catch (e) {
      AppLogger.api('Push: failed to read public config: $e');
    }
  }

  /// The user's choice in Profil (default on).
  bool get isEnabled => preferences.getBool(PreferenceKeys.pushEnabled) ?? true;

  /// This device's FID, or `null` when Firebase is not available.
  Future<String?> deviceFid() async {
    if (!isSupported) return null;
    try {
      return await FirebaseInstallations.instance.getId();
    } catch (e) {
      AppLogger.api('Push: failed to read FID: $e');
      return null;
    }
  }

  Future<PushStatus> status() async {
    await loadServerConfig();
    if (!isSupported) return PushStatus.unavailable;
    if (!isEnabled) return PushStatus.off;
    return await _osAllows() ? PushStatus.on : PushStatus.blocked;
  }

  /// Turns push on or off for this device and returns the new [status].
  Future<PushStatus> setEnabled(bool enabled) async {
    await loadServerConfig();
    if (!isSupported) return PushStatus.unavailable;
    await preferences.setBool(PreferenceKeys.pushEnabled, enabled);
    if (enabled) {
      await registerDevice();
    } else {
      await _unregisterDevice();
    }
    return status();
  }

  /// Asks for notification permission (Android 13+ / iOS), registers this
  /// app instance with FCM, then sends the FID to
  /// `POST /api/v1/field/devices`. Call after login and on every app start
  /// while logged in. Does nothing while the user has push turned off or
  /// the OS blocks notifications.
  Future<void> registerDevice() async {
    await loadServerConfig();
    if (!isSupported || !isEnabled) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        AppLogger.api('Push: notifications blocked in phone settings');
        return;
      }
      AppLogger.api('Push: permission ${settings.authorizationStatus.name}');
      // FCM reports a new FID here when registration completes or changes.
      _registeredSub ??= messaging.onRegistered.listen((fid) {
        AppLogger.api('Push: FCM registered${_fidForLog(fid)}');
        _sendFid(fid);
      });
      await messaging.register();
      // Also send the current FID: the backend wants it on every app start,
      // and onRegistered may not fire again for an already registered app.
      final fid = await deviceFid();
      if (fid != null) await _sendFid(fid);
    } catch (e) {
      AppLogger.api('Push: register failed: $e');
    }
  }

  Future<bool> _osAllows() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      // notDetermined: not asked yet; registerDevice() will ask.
      return settings.authorizationStatus != AuthorizationStatus.denied;
    } catch (e) {
      AppLogger.api('Push: failed to read permission: $e');
      return true;
    }
  }

  Future<void> _sendFid(String fid) async {
    if (!isEnabled) return;
    await _guard('register', () async {
      await apiClient.post(
        ApiEndpoints.fieldDevices,
        body: {
          'fid': fid,
          'platform': Platform.isIOS ? 'IOS' : 'ANDROID',
          'appVersion': AppConstants.appVersion,
        },
      );
      AppLogger.api('Push: device registered${_fidForLog(fid)}');
    });
  }

  /// The FID only in debug builds, to match it with the backend's device
  /// list; release builds never log it.
  static String _fidForLog(String fid) => kDebugMode ? ' (fid $fid)' : '';

  Future<void> _unregisterDevice() async {
    final fid = await deviceFid();
    if (fid == null) return;
    await _guard('unregister', () async {
      await apiClient.delete(
        ApiEndpoints.fieldDevices,
        queryParameters: {'fid': fid},
      );
      AppLogger.api('Push: device unregistered');
    });
  }

  Future<void> _guard(String action, Future<void> Function() call) async {
    try {
      await call();
    } on ServerException catch (e) {
      // The endpoint only exists when the server's notification-push
      // profile is on; on the dev server it is off (404 NOT_FOUND).
      if (e.statusCode == 404) {
        AppLogger.api('Push: disabled on this server');
      } else {
        AppLogger.api('Push: $action failed: $e');
      }
    } catch (e) {
      AppLogger.api('Push: $action failed: $e');
    }
  }
}
