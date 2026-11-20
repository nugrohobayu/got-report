import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:got_report/core/utils/app_logger.dart';
import 'package:got_report/core/utils/preference_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Called with the push `data.route` (e.g. `/tasks/<id>`) when the user
/// opens a notification. `null` when the push carried no route.
typedef PushOpenedCallback = void Function(String? route);

/// Shows FCM pushes and handles taps on them.
///
/// - App in the background / closed: Android shows `notification` pushes by
///   itself on the [channel] (set as default in AndroidManifest). Data-only
///   pushes are shown by [_onBackgroundMessage].
/// - App in the foreground: FCM shows nothing, so [_onForegroundMessage]
///   shows a local notification instead.
class PushNotifications {
  PushNotifications._();

  /// Must match `default_notification_channel_id` in AndroidManifest.xml.
  static const channel = AndroidNotificationChannel(
    'tugas',
    'Tugas',
    description: 'Tugas baru, permintaan revisi, dan tugas terlambat',
    importance: Importance.high,
  );

  static final _local = FlutterLocalNotificationsPlugin();

  /// Call once after `Firebase.initializeApp()`. Does nothing when Firebase
  /// is not available (e.g. missing google-services.json, tests).
  static Future<void> init({
    required PushOpenedCallback onOpened,
    required bool Function() isEnabled,
  }) async {
    if (!Platform.isAndroid || Firebase.apps.isEmpty) return;
    _isEnabled = isEnabled;
    try {
      await _initLocal(onOpened: onOpened);
      if (kDebugMode) {
        // Only for "Send test message" in the Firebase console, which asks
        // for a registration token. The app itself registers by FID
        // (PushService). Never logged in release builds.
        // ignore: deprecated_member_use
        final token = await FirebaseMessaging.instance.getToken();
        debugPrint('Push: FCM token (debug only): $token');
      }
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Tapped an FCM notification while the app was in the background.
      FirebaseMessaging.onMessageOpenedApp
          .listen((m) => onOpened(_routeOf(m.data)));
      // Tapped an FCM notification that launched the app.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) onOpened(_routeOf(initial.data));
      // Tapped one of our local notifications that launched the app.
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        onOpened(launch!.notificationResponse?.payload);
      }
    } catch (e) {
      AppLogger.api('Push: notification setup failed: $e');
    }
  }

  static Future<void> _initLocal({PushOpenedCallback? onOpened}) async {
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse:
          onOpened == null ? null : (response) => onOpened(response.payload),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// The user's Notifikasi switch in Profil.
  static bool Function() _isEnabled = () => true;

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    // Turned off in Profil, but the server may still push (e.g. the
    // unregister call failed): don't show it.
    if (!_isEnabled()) return;
    await _show(message);
  }

  static Future<void> _show(RemoteMessage message) async {
    final n = message.notification;
    await _local.show(
      message.messageId.hashCode,
      n?.title ?? 'Pembaruan tugas',
      n?.body ?? 'Ketuk untuk melihat tugas Anda.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: _routeOf(message.data),
    );
  }

  static String? _routeOf(Map<String, dynamic> data) =>
      data['route']?.toString();
}

/// Runs in a separate isolate while the app is in the background / closed.
/// Only data-only pushes need showing here; Android already shows pushes
/// that have a `notification` part.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  if (message.notification != null) return;
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(PreferenceKeys.pushEnabled) == false) return;
  await Firebase.initializeApp();
  await PushNotifications._initLocal();
  await PushNotifications._show(message);
  debugPrint('Push: shown data-only message in background');
}
