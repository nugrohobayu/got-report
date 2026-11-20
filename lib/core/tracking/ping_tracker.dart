import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/constants/app_constants.dart';
import 'package:got_report/core/error/exceptions.dart';
import 'package:got_report/core/location/location_service.dart';
import 'package:got_report/core/network/api_client.dart';
import 'package:got_report/core/utils/app_logger.dart';
import 'package:got_report/features/tugas_hari_ini/data/models/task_summary_model.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';

/// One GPS point for `POST /api/v1/field/pings`.
class Ping {
  final double latitude;
  final double longitude;
  final double accuracyM;
  final bool mock;

  /// UTC.
  final DateTime recordedAt;

  const Ping({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    required this.mock,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracyM': accuracyM,
        'mock': mock,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
      };
}

/// Periodic GPS trail (monitoring dinas luar).
///
/// Privacy rule: points are only read and sent while the user has a task in
/// `DIKERJAKAN`, the app is in the foreground and the user is logged in.
/// Every [interval] one fix is queued and the queue is sent as a batch;
/// points that fail to send (no signal) are retried on the next tick.
///
/// Whether a task is running is checked on login, on app resume, after
/// [refresh] (start / submit / signature) and every [recheckEvery] ticks,
/// so a task cancelled or finished elsewhere stops the trail too.
///
/// Best effort: errors are only logged, never shown.
class PingTracker with WidgetsBindingObserver {
  final ApiClient apiClient;
  final LocationService locationService;
  final Duration interval;
  final int recheckEvery;
  final DateTime Function() _now;

  /// Server limits: 1–100 points per batch, none older than 24 hours.
  static const maxBatch = 100;
  static const maxAge = Duration(hours: 24);

  PingTracker({
    required this.apiClient,
    required this.locationService,
    this.interval = const Duration(minutes: 1),
    this.recheckEvery = 5,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final List<Ping> _queue = [];
  Timer? _timer;
  bool _loggedIn = false;
  bool _foreground = true;
  bool _taskRunning = false;
  bool _ticking = false;
  int _ticks = 0;

  /// Bumped on every [refresh] / [stop] so a slow status check can't
  /// restart the trail after logout.
  int _generation = 0;

  /// Whether points are being collected right now.
  bool get isTracking => _timer != null;

  @visibleForTesting
  List<Ping> get queue => List.unmodifiable(_queue);

  /// The tracker from the widget tree, or `null` when none is provided
  /// (e.g. pages pumped alone in widget tests).
  static PingTracker? maybeOf(BuildContext context) {
    try {
      return context.read<PingTracker>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  /// Call after login (and on app start while logged in).
  Future<void> start() async {
    _loggedIn = true;
    await refresh();
  }

  /// Call on logout: stops at once and drops unsent points.
  void stop() {
    _loggedIn = false;
    _generation++;
    _taskRunning = false;
    _cancelTimer();
    _queue.clear();
  }

  /// Re-checks whether a task is running and starts / stops the trail.
  /// Call after a task status changes on this phone.
  Future<void> refresh() async {
    if (!_loggedIn) return;
    final generation = ++_generation;
    final running = await _hasRunningTask();
    if (generation != _generation || running == null) return;
    _taskRunning = running;
    if (!running) {
      // Points taken while the task was running still count.
      await _flush();
      _queue.clear();
    }
    _apply();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    if (foreground) {
      // The task may have changed while away (e.g. finished on the web).
      refresh();
    } else {
      _cancelTimer();
    }
  }

  void dispose() {
    _generation++;
    _cancelTimer();
  }

  void _apply() {
    final shouldTrack = _loggedIn && _foreground && _taskRunning;
    if (!shouldTrack) {
      _cancelTimer();
      return;
    }
    if (_timer != null) return;
    AppLogger.api('Pings: started');
    _ticks = 0;
    _timer = Timer.periodic(interval, (_) => tick());
    tick();
  }

  void _cancelTimer() {
    if (_timer == null) return;
    AppLogger.api('Pings: stopped');
    _timer!.cancel();
    _timer = null;
  }

  @visibleForTesting
  Future<void> tick() async {
    if (_ticking || !isTracking) return;
    _ticking = true;
    try {
      _ticks++;
      if (_ticks > 1 && _ticks % recheckEvery == 1) {
        await refresh();
        if (!isTracking) return;
      }
      await _record();
      await _flush();
    } finally {
      _ticking = false;
    }
  }

  /// `null` when the check failed (keep the current state).
  Future<bool?> _hasRunningTask() async {
    try {
      final data = await apiClient.get(
        ApiEndpoints.fieldTasks,
        queryParameters: {
          'status': [TaskStatus.dikerjakan],
        },
      );
      return TaskSummaryModel.listFromJson(data)
          .any((t) => t.status == TaskStatus.dikerjakan);
    } catch (e) {
      AppLogger.api('Pings: task check failed: $e');
      return null;
    }
  }

  Future<void> _record() async {
    // Never prompt from the background loop; the start screen asks.
    if (await locationService.access() != LocationAccess.granted) return;
    try {
      final fix = await locationService.current();
      _queue.add(Ping(
        latitude: fix.latitude,
        longitude: fix.longitude,
        accuracyM: fix.accuracyM,
        mock: fix.mock,
        recordedAt: _now().toUtc(),
      ));
    } on LocationUnavailable catch (e) {
      AppLogger.api('Pings: no fix: ${e.message}');
    }
  }

  Future<void> _flush() async {
    final oldest = _now().toUtc().subtract(maxAge);
    _queue.removeWhere((p) => p.recordedAt.isBefore(oldest));
    if (_queue.length > maxBatch) {
      _queue.removeRange(0, _queue.length - maxBatch);
    }
    if (_queue.isEmpty) return;

    final batch = List<Ping>.of(_queue);
    try {
      final data = await apiClient.post(
        ApiEndpoints.fieldPings,
        body: {'pings': batch.map((p) => p.toJson()).toList()},
      );
      AppLogger.api('Pings: sent ${batch.length}, response $data');
      _removeSent(batch);
    } on ServerException catch (e) {
      // 4xx: the batch itself is rejected, retrying won't help.
      final status = e.statusCode ?? 0;
      if (status >= 400 && status < 500) _removeSent(batch);
      AppLogger.api('Pings: send failed: $e');
    } catch (e) {
      // No signal / timeout: keep the points for the next tick.
      AppLogger.api('Pings: send failed, will retry: $e');
    }
  }

  void _removeSent(List<Ping> batch) {
    final sent = batch.toSet();
    _queue.removeWhere(sent.contains);
  }
}
