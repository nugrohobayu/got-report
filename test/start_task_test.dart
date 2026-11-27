import 'package:flutter_test/flutter_test.dart';
import 'package:ada_tugas/core/error/failures.dart';
import 'package:ada_tugas/core/location/location_service.dart';
import 'package:ada_tugas/features/mulai_tugas/data/datasources/start_task_remote_data_source.dart';
import 'package:ada_tugas/features/mulai_tugas/domain/entities/task_start.dart';
import 'package:ada_tugas/features/mulai_tugas/domain/repositories/start_task_repository.dart';
import 'package:ada_tugas/features/mulai_tugas/presentation/bloc/start_task_cubit.dart';
import 'package:ada_tugas/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:ada_tugas/features/tugas_hari_ini/presentation/widgets/task_action.dart';

/// Trimmed "Contoh response" of GET /api/v1/field/tasks/{id}.
const _detailJson = {
  'id': '01a1ed87-f2b4-74a3-885e-627da3b5bf58',
  'title': 'Instalasi mesin antrean cabang Asia Afrika',
  'mode': 'TEAM',
  'status': 'DITUGASKAN',
  'overdue': false,
  'myRole': 'LEADER',
  'location': {
    'id': '01a1ed87-ea30-7a50-8212-9e1a102a3283',
    'name': 'Bank X Bandung 598c61',
    'address': 'Jl. Asia Afrika No. 1, Bandung',
    'latitude': -6.914744,
    'longitude': 107.60981,
    'radiusM': 150,
    'hasQr': true,
  },
  'template': {
    'name': 'Instalasi mesin antrean 598c61',
    'version': 1,
    'requireQr': true,
    'requireSignature': true,
  },
  'dueAt': '2026-11-18T12:21:12Z',
  'startedAt': null,
};

class _FakeRepo implements StartTaskRepository {
  final TaskStartInfo info;
  Failure? startError;
  StartEvidence? sent;

  _FakeRepo(this.info);

  @override
  Future<TaskStartInfo> getStartInfo(String taskId) async => info;

  @override
  Future<TaskSummary> start(String taskId, StartEvidence evidence) async {
    sent = evidence;
    final error = startError;
    if (error != null) throw error;
    final t = info.task;
    return TaskSummary(
      id: t.id,
      title: t.title,
      status: TaskStatus.dikerjakan,
      location: t.location,
    );
  }
}

class _FakeLocation implements LocationService {
  LocationAccess accessState = LocationAccess.granted;
  int reads = 0;
  bool mock = false;
  DateTime readAt;

  _FakeLocation({required this.readAt});

  @override
  Future<LocationAccess> access() async => accessState;

  @override
  Future<LocationAccess> requestAccess() async =>
      accessState = LocationAccess.granted;

  @override
  Future<DeviceLocation> current() async {
    reads++;
    return DeviceLocation(
      latitude: -6.914444,
      longitude: 107.60981,
      accuracyM: 8,
      mock: mock,
      readAt: readAt,
    );
  }

  @override
  Future<void> openSettings(LocationAccess access) async {}

  @override
  double distanceM(double lat1, double lng1, double lat2, double lng2) => 33;
}

void main() {
  final now = DateTime(2026, 11, 20, 9);
  late _FakeRepo repo;
  late _FakeLocation location;

  StartTaskCubit cubit() => StartTaskCubit(
        repository: repo,
        locationService: location,
        taskId: _detailJson['id'] as String,
        now: () => now,
      );

  setUp(() {
    repo = _FakeRepo(startInfoFromJson(_detailJson));
    location = _FakeLocation(readAt: now);
  });

  test('parses requireQr and the task from the detail example', () {
    final info = startInfoFromJson(_detailJson);
    expect(info.requireQr, isTrue);
    expect(info.task.status, TaskStatus.ditugaskan);
    expect(info.task.location!.radiusM, 150);
  });

  test('load reads the GPS when permission is granted', () async {
    final c = cubit();
    await c.load();
    expect(c.state.status, StartTaskStatus.ready);
    expect(c.state.location, isNotNull);
    expect(c.state.canStart, isTrue);
    expect(c.distanceToLocationM, 33);
    await c.close();
  });

  test('without permission: no GPS read until allowed', () async {
    location.accessState = LocationAccess.needsPermission;
    final c = cubit();
    await c.load();
    expect(location.reads, 0);
    expect(c.state.canStart, isFalse);

    await c.requestAccess();
    expect(location.reads, 1);
    expect(c.state.canStart, isTrue);
    await c.close();
  });

  test('start sends the fix, QR and UTC device time', () async {
    final c = cubit();
    await c.load();
    await c.start(qrCode: 'GRL-7Pg0PLxjtQArreow');

    expect(c.state.status, StartTaskStatus.started);
    expect(c.state.info!.task.status, TaskStatus.dikerjakan);
    final json = repo.sent!.toJson();
    expect(json['latitude'], -6.914444);
    expect(json['accuracyM'], 8);
    expect(json['mock'], false);
    expect(json['qrCode'], 'GRL-7Pg0PLxjtQArreow');
    expect(json['deviceTime'], endsWith('Z'));
    await c.close();
  });

  test('a stale fix is read again before starting', () async {
    final c = cubit();
    await c.load();
    expect(location.reads, 1);
    location.readAt = now;
    // Fix from 5 minutes ago.
    final old = StartTaskCubit(
      repository: repo,
      locationService: _FakeLocation(
        readAt: now.subtract(const Duration(minutes: 5)),
      ),
      taskId: 'x',
      now: () => now,
    );
    await old.load();
    final oldLocation = old.locationService as _FakeLocation;
    await old.start(qrCode: 'q');
    expect(oldLocation.reads, 2);
    await c.close();
    await old.close();
  });

  test('out of radius shows the distance from error.details', () async {
    repo.startError = const ServerFailure(
      'Posisi Anda di luar radius lokasi tugas',
      code: 'EVIDENCE_OUT_OF_RADIUS',
      details: {'radiusM': '150', 'distanceM': '498'},
    );
    final c = cubit();
    await c.load();
    await c.start(qrCode: 'q');

    expect(c.state.status, StartTaskStatus.ready);
    expect(
      c.state.error,
      'Anda 498 m dari lokasi (maks 150 m). '
      'Mendekatlah ke lokasi lalu coba lagi.',
    );
    await c.close();
  });

  test('other evidence errors keep the backend message', () {
    expect(
      startErrorMessage(const ServerFailure(
        'QR lokasi tidak cocok',
        code: 'EVIDENCE_QR_MISMATCH',
      )),
      'QR lokasi tidak cocok. Pindai QR yang tertempel di lokasi tugas ini.',
    );
    expect(
      startErrorMessage(const ServerFailure(
        'Akurasi GPS terlalu rendah',
        code: 'EVIDENCE_LOW_ACCURACY',
        details: {'accuracyM': '80', 'maxAccuracyM': '50'},
      )),
      'Akurasi GPS terlalu rendah. Akurasi GPS 80 m (maks 50 m). '
      'Pindah ke tempat terbuka lalu coba lagi.',
    );
    expect(
      startErrorMessage(const NetworkFailure('Tidak dapat terhubung')),
      'Tidak dapat terhubung',
    );
  });

  test('a PERLU_REVISI task is started again with POST start', () async {
    repo = _FakeRepo(
      startInfoFromJson({..._detailJson, 'status': 'PERLU_REVISI'}),
    );
    final c = cubit();
    await c.load();
    expect(c.state.canStart, isTrue);
    // A revision of a QR template scans the QR again (confirmed by BE).
    expect(c.state.needsQr, isTrue);
    await c.start(qrCode: 'q');
    expect(repo.sent!.qrCode, 'q');
    expect(c.state.status, StartTaskStatus.started);
    await c.close();
  });

  test('first start of a QR template needs the QR', () async {
    final c = cubit();
    await c.load();
    expect(c.state.needsQr, isTrue);
    await c.close();
  });

  test('card action per status', () {
    TaskAction? of(String status, {String role = 'LEADER'}) => TaskAction.of(
          TaskSummary(id: 'x', title: 'x', status: status, myRole: role),
        );
    expect(of(TaskStatus.ditugaskan), TaskAction.start);
    expect(of(TaskStatus.perluRevisi), TaskAction.startRevision);
    expect(of(TaskStatus.dikerjakan), TaskAction.resume);
    expect(of(TaskStatus.menungguTtd), TaskAction.sign);
    expect(of(TaskStatus.menungguTtd, role: 'MEMBER'), isNull);
    expect(of(TaskStatus.selesai), isNull);
  });

  test('DIKERJAKAN / SELESAI tasks cannot be started', () async {
    repo = _FakeRepo(startInfoFromJson({..._detailJson, 'status': 'SELESAI'}));
    final c = cubit();
    await c.load();
    expect(c.state.canStart, isFalse);
    await c.start();
    expect(repo.sent, isNull);
    await c.close();
  });

  test('fake GPS (mock location) blocks the start', () async {
    location.mock = true;
    final c = cubit();
    await c.load();
    expect(c.state.mockDetected, isTrue);
    expect(c.state.canStart, isFalse);
    expect(c.state.error, mockLocationMessage);

    await c.start(qrCode: 'q');
    expect(repo.sent, isNull);

    // Fake GPS turned off: checking again allows the start.
    location.mock = false;
    await c.locate();
    expect(c.state.error, isNull);
    expect(c.state.canStart, isTrue);
    await c.start(qrCode: 'q');
    expect(repo.sent!.mock, isFalse);
    expect(c.state.status, StartTaskStatus.started);
    await c.close();
  });

  test('ensureRealLocation rejects a mock fix', () {
    DeviceLocation fix({required bool mock}) => DeviceLocation(
          latitude: 0,
          longitude: 0,
          accuracyM: 5,
          mock: mock,
          readAt: now,
        );
    expect(() => ensureRealLocation(fix(mock: false)), returnsNormally);
    expect(
      () => ensureRealLocation(fix(mock: true)),
      throwsA(isA<LocationUnavailable>()),
    );
  });
}
