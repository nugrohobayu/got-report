import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:got_report/core/constants/app_constants.dart';
import 'package:got_report/core/error/exceptions.dart';
import 'package:got_report/core/location/location_service.dart';
import 'package:got_report/core/network/api_client.dart';
import 'package:got_report/core/tracking/ping_tracker.dart';

import 'helpers/fake_location_service.dart';

Map<String, dynamic> _task(String status) => {
      'id': '01a1ed87-f2b4-74a3-885e-627da3b5bf58',
      'title': 'Instalasi mesin antrean',
      'status': status,
      'overdue': false,
    };

/// Answers `GET /field/tasks` with [tasks] and records `POST /field/pings`.
class _FakeApi extends ApiClient {
  List<Map<String, dynamic>> tasks;
  Exception? postError;
  final List<List<dynamic>> sent = [];
  final List<Map<String, dynamic>?> taskQueries = [];

  _FakeApi(this.tasks) : super(baseUrl: 'http://localhost');

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) {
    expect(path, ApiEndpoints.fieldTasks);
    taskQueries.add(queryParameters);
    return Future.value(tasks);
  }

  @override
  Future<dynamic> post(String path, {Object? body}) async {
    expect(path, ApiEndpoints.fieldPings);
    final error = postError;
    if (error != null) throw error;
    final pings = (body! as Map)['pings'] as List;
    sent.add(pings);
    return {'accepted': pings.length, 'dropped': 0};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeApi api;
  late FakeLocationService location;
  late PingTracker tracker;
  final now = DateTime.utc(2026, 11, 20, 3);

  setUp(() {
    api = _FakeApi([_task('DIKERJAKAN')]);
    location = FakeLocationService();
    tracker = PingTracker(
      apiClient: api,
      locationService: location,
      interval: const Duration(hours: 1), // ticks are driven by the test
      now: () => now,
    );
  });

  tearDown(() => tracker.dispose());

  test('sends a ping right away while a task is DIKERJAKAN', () async {
    await tracker.start();
    await pumpEventQueue();

    expect(api.taskQueries.single, {
      'status': ['DIKERJAKAN'],
    });
    expect(tracker.isTracking, isTrue);
    expect(api.sent, hasLength(1));
    expect(api.sent.single.single, {
      'latitude': -6.914744,
      'longitude': 107.60981,
      'accuracyM': 7.0,
      'mock': false,
      'recordedAt': '2026-11-20T03:00:00.000Z',
    });
    expect(tracker.queue, isEmpty);
  });

  test('sends nothing without a running task', () async {
    api.tasks = [_task('DITUGASKAN'), _task('MENUNGGU_TTD')];
    await tracker.start();
    await pumpEventQueue();

    expect(tracker.isTracking, isFalse);
    expect(api.sent, isEmpty);
  });

  test('stops after refresh once the task left DIKERJAKAN', () async {
    await tracker.start();
    await pumpEventQueue();
    api.tasks = [_task('SELESAI')];

    await tracker.refresh();

    expect(tracker.isTracking, isFalse);
  });

  test('keeps points that failed to send and retries them', () async {
    api.postError = const NetworkException();
    await tracker.start();
    await pumpEventQueue();
    expect(tracker.queue, hasLength(1));

    api.postError = null;
    await tracker.tick();

    expect(api.sent.single, hasLength(2));
    expect(tracker.queue, isEmpty);
  });

  test('drops a batch the server rejects (4xx)', () async {
    api.postError = const ServerException(message: 'bad', statusCode: 400);
    await tracker.start();
    await pumpEventQueue();

    expect(tracker.queue, isEmpty);
  });

  test('does not ask for permission or record without it', () async {
    location.accessState = LocationAccess.needsPermission;
    await tracker.start();
    await pumpEventQueue();

    expect(location.requests, 0);
    expect(api.sent, isEmpty);
  });

  test('logout stops and clears unsent points', () async {
    api.postError = const NetworkException();
    await tracker.start();
    await pumpEventQueue();

    tracker.stop();

    expect(tracker.isTracking, isFalse);
    expect(tracker.queue, isEmpty);
  });

  test('pauses in the background and resumes in the foreground', () async {
    await tracker.start();
    await pumpEventQueue();

    tracker.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(tracker.isTracking, isFalse);

    tracker.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(tracker.isTracking, isTrue);
    expect(api.taskQueries, hasLength(2));
  });
}
