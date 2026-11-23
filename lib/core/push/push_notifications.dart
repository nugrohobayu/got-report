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

final _taskRoute = RegExp(r'^/tasks/([A-Za-z0-9-]+)/?$');

/// The task id in a push route `/tasks/<taskId>`, or `null` for any other
/// route.
String? taskIdFromPushRoute(String? route) =>
    route == null ? null : _taskRoute.firstMatch(route.trim())?.group(1);

/// Shows FCM pushes and handles taps on them.
///
/// - App in the background / closed: Android shows `notification` pushes by
///   itself on the [channel] (set as default in AndroidManifest). Data-only
///   pushes are shown by [_onBackgroundMessage].
/// - App in the foreground: FCM shows nothing, so [_onForegroundMessage]
///   shows a local notification instead.
class PushNotifications {
  PushNotifications._();

  /// Notification sound saying "Ada tugas" (`res/raw/ada_tugas.wav`).
  static const _sound = RawResourceAndroidNotificationSound('ada_tugas');

  /// Must match `default_notification_channel_id` in AndroidManifest.xml.
  ///
  /// Android fixes a channel's sound when it is created, so changing the
  /// sound needs a new channel id (and deleting the old one in
  /// [_oldChannelIds]).
  static const channel = AndroidNotificationChannel(
    'tugas_suara',
    'Tugas',
    description: 'Tugas baru, permintaan revisi, dan tugas terlambat',
    importance: Importance.high,
    playSound: true,
    sound: _sound,
  );

  /// Channels from earlier versions, removed so Settings shows only one.
  static const _oldChannelIds = ['tugas'];

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
      // No getToken(): with firebase_messaging_installation_id_enabled in
      // the manifest the token API throws. The app is addressed by its FID
      // (logged by PushService in debug builds).
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
    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    for (final id in _oldChannelIds) {
      await android?.deleteNotificationChannel(id);
    }
    await android?.createNotificationChannel(channel);
  }

  /// The user's Notifikasi switch in Profil.
  static bool Function() _isEnabled = () => true;

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    AppLogger.api('Push: received in foreground ${_describe(message)}');
    // Turned off in Profil, but the server may still push (e.g. the
    // unregister call failed): don't show it.
    if (!_isEnabled()) {
      AppLogger.api('Push: not shown, turned off in Profil');
      return;
    }
    await _show(message);
  }

  /// One log line for a push: its id and whether it has a `notification`
  /// part, plus title and `data` in debug builds only (they hold task
  /// titles and ids).
  static String _describe(RemoteMessage message) {
    final n = message.notification;
    final kind = n == null ? 'data-only' : 'notification';
    final base = '[${message.messageId}] $kind';
    if (!kDebugMode) return base;
    return '$base title="${n?.title}" data=${message.data}';
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
          playSound: true,
          sound: _sound,
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
  // Separate isolate: debugPrint reaches `flutter run` / logcat.
  debugPrint(
    'Push: received in background ${PushNotifications._describe(message)}',
  );
  if (message.notification != null) return;
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(PreferenceKeys.pushEnabled) == false) return;
  await Firebase.initializeApp();
  await PushNotifications._initLocal();
  await PushNotifications._show(message);
  debugPrint('Push: shown data-only message in background');
}
