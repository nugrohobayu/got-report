import 'dart:async';
import 'dart:io';

import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:got_report/core/constants/app_constants.dart';
import 'package:got_report/core/error/exceptions.dart';
import 'package:got_report/core/network/api_client.dart';
import 'package:got_report/core/utils/app_logger.dart';

/// Push notifications (FCM). The backend sends to this device by its
/// Firebase Installation ID (FID): FCM's direct-send target, available after
/// `FirebaseMessaging.register()` (see [FirebaseMessaging.onRegistered]).
///
/// Every method is best effort: push is optional, so failures are only
/// logged and never block login, logout or the UI.
class PushService {
  final ApiClient apiClient;

  PushService(this.apiClient);

  StreamSubscription<String>? _registeredSub;

  bool get _supported =>
      (Platform.isAndroid || Platform.isIOS) && Firebase.apps.isNotEmpty;

  /// This device's FID, or `null` when Firebase is not available.
  Future<String?> deviceFid() async {
    if (!_supported) return null;
    try {
      return await FirebaseInstallations.instance.getId();
    } catch (e) {
      AppLogger.api('Push: failed to read FID: $e');
      return null;
    }
  }

  /// Asks for notification permission (Android 13+ / iOS), registers this
  /// app instance with FCM, then sends the FID to
  /// `POST /api/v1/field/devices`. Call after login and on every app start
  /// while logged in.
  Future<void> registerDevice() async {
    if (!_supported) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      // FCM reports a new FID here when registration completes or changes.
      _registeredSub ??= messaging.onRegistered.listen(_sendFid);
      await messaging.register();
      // Also send the current FID: the backend wants it on every app start,
      // and onRegistered may not fire again for an already registered app.
      final fid = await deviceFid();
      if (fid != null) await _sendFid(fid);
    } catch (e) {
      AppLogger.api('Push: register failed: $e');
    }
  }

  Future<void> _sendFid(String fid) async {
    try {
      await apiClient.post(
        ApiEndpoints.fieldDevices,
        body: {
          'fid': fid,
          'platform': Platform.isIOS ? 'IOS' : 'ANDROID',
          'appVersion': AppConstants.appVersion,
        },
      );
      AppLogger.api('Push: device registered');
    } on ServerException catch (e) {
      // The endpoint only exists when the server's notification-push
      // profile is on; on the dev server it is off (404 NOT_FOUND).
      if (e.statusCode == 404) {
        AppLogger.api('Push: disabled on this server');
      } else {
        AppLogger.api('Push: register failed: $e');
      }
    } catch (e) {
      AppLogger.api('Push: register failed: $e');
    }
  }
}
