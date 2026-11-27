import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ada_tugas/core/error/failures.dart';
import 'package:ada_tugas/core/location/location_service.dart';
import 'package:ada_tugas/features/form_dinamis/data/models/task_form_model.dart';
import 'package:ada_tugas/features/form_dinamis/domain/entities/task_form.dart';
import 'package:ada_tugas/features/form_dinamis/domain/repositories/task_form_repository.dart';
import 'package:ada_tugas/features/form_dinamis/presentation/bloc/task_form_cubit.dart';
import 'package:ada_tugas/features/tugas_hari_ini/domain/entities/task_summary.dart';

/// "Contoh response" of GET /api/v1/field/tasks/{id} (template part).
Map<String, dynamic> _detail({String myRole = 'LEADER'}) => {
      'id': 'task-1',
      'title': 'Instalasi mesin antrean cabang Asia Afrika',
      'status': 'DIKERJAKAN',
      'myRole': myRole,
      'template': {
        'name': 'Instalasi mesin antrean',
        'requireQr': true,
        'requireSignature': true,
        'schema': {
          'lockOrder': true,
          'steps': [
            {
              'id': 's1',
              'title': 'Foto lokasi',
              'fields': [
                {
                  'id': 'f1',
                  'type': 'photo',
                  'label': 'Lokasi sebelum pemasangan',
                  'required': true,
                  'pair': {'group': 'p1', 'role': 'before'},
                  'hint': {'text': 'Tampak depan, meja terlihat'},
                },
              ],
            },
            {
              'id': 's2',
              'title': 'Pasang mesin',
              'fields': [
                {
                  'id': 'f2',
                  'type': 'checklist',
                  'label': 'Pemasangan',
                  'required': true,
                  'options': ['Mesin terpasang', 'Kabel rapi'],
                },
                {
                  'id': 'f3',
                  'type': 'photo',
                  'label': 'Mesin terpasang',
                  'required': true,
                  'pair': {'group': 'p1', 'role': 'after'},
                },
              ],
            },
            {
              'id': 's3',
              'title': 'Tes fungsi',
              'fields': [
                {
                  'id': 'f4',
                  'type': 'choice',
                  'label': 'Cetak tiket',
                  'required': true,
                  'options': ['Berhasil', 'Gagal'],
                },
                {
                  'id': 'f5',
                  'type': 'number',
                  'label': 'Jumlah tiket uji',
                  'required': false,
                  'min': 1,
                  'max': 20,
                },
                {
                  'id': 'f6',
                  'type': 'text',
                  'label': 'Catatan',
                  'required': false,
                },
              ],
            },
            {
              'id': 's4',
              'title': 'TTD klien',
              'fields': [
                {
                  'id': 'f7',
                  'type': 'signature',
                  'label': 'Tanda tangan klien',
                  'required': true,
                },
              ],
            },
          ],
        },
      },
    };

class _FakeRepo implements TaskFormRepository {
  final TaskForm form;
  Submission submission;
  final saved = <String, Map<String, dynamic>>{};
  Failure? saveError;
  Failure? submitError;
  String submitStatus = TaskStatus.menungguTtd;
  int submits = 0;
  List<String> mediaStatuses = ['PROCESSING', 'READY'];
  String? signedBy;

  _FakeRepo(this.form, {Submission? submission})
      : submission = submission ?? const Submission(status: 'DIKERJAKAN');

  @override
  Future<TaskForm> getForm(String taskId) async => form;

  @override
  Future<Submission> getSubmission(String taskId) async => submission;

  @override
  Future<StepSnapshot> saveAnswers(
    String taskId,
    String stepId,
    Map<String, dynamic> answers,
    GpsEvidence evidence,
  ) async {
    final error = saveError;
    if (error != null) throw error;
    saved[stepId] = answers;
    return StepSnapshot(stepId: stepId, complete: true, answers: answers);
  }

  int _poll = 0;

  @override
  Future<MediaInfo> uploadPhoto(
    String taskId, {
    required String stepId,
    required String fieldId,
    required Uint8List jpeg,
    required GpsEvidence evidence,
  }) async {
    _poll = 0;
    return MediaInfo(mediaId: 'm-$fieldId', status: mediaStatuses.first);
  }

  @override
  Future<MediaInfo> getMedia(String taskId, String mediaId) async {
    _poll = (_poll + 1).clamp(0, mediaStatuses.length - 1);
    final status = mediaStatuses[_poll];
    return MediaInfo(
      mediaId: mediaId,
      status: status,
      fileId: status == 'READY' ? 'file-$mediaId' : null,
    );
  }

  @override
  Future<TaskSummary> submit(String taskId) async {
    submits++;
    final error = submitError;
    if (error != null) throw error;
    return TaskSummary(id: taskId, title: 't', status: submitStatus);
  }

  @override
  Future<TaskSummary> sign(
    String taskId, {
    required String signerName,
    String? signerTitle,
    required Uint8List png,
    required GpsEvidence evidence,
  }) async {
    signedBy = signerName;
    return TaskSummary(id: taskId, title: 't', status: TaskStatus.selesai);
  }

  @override
  Future<Uint8List> fileBytes(String fileId) async => Uint8List(0);
}

class _Gps implements LocationService {
  bool mock = false;
  @override
  Future<LocationAccess> access() async => LocationAccess.granted;
  @override
  Future<LocationAccess> requestAccess() async => LocationAccess.granted;
  @override
  Future<DeviceLocation> current() async => DeviceLocation(
        latitude: -6.914744,
        longitude: 107.60981,
        accuracyM: 7,
        mock: mock,
        readAt: DateTime.now(),
      );
  @override
  Future<void> openSettings(LocationAccess access) async {}
  @override
  double distanceM(double a, double b, double c, double d) => 0;
}

void main() {
  late _FakeRepo repo;
  late _Gps gps;

  TaskFormCubit cubit() => TaskFormCubit(
        repository: repo,
        locationService: gps,
        taskId: 'task-1',
        mediaPollInterval: Duration.zero,
      );

  setUp(() {
    repo = _FakeRepo(TaskFormModel.formFromJson(_detail()));
    gps = _Gps();
  });

  test('fake GPS: camera check and photo upload are rejected', () async {
    gps.mock = true;
    final c = cubit();
    await c.load();

    expect(await c.checkPhotoLocation('s1', 'f1'), isFalse);
    expect(c.state.fieldErrors['s1.f1'], mockLocationMessage);

    await c.uploadPhoto('s1', 'f1', Uint8List(4));
    expect(c.state.media['s1.f1'], isNull);
    expect(c.state.fieldErrors['s1.f1'], mockLocationMessage);

    // Fake GPS off: the next check reads the GPS again and passes.
    gps.mock = false;
    expect(await c.checkPhotoLocation('s1', 'f1'), isTrue);
    expect(c.state.fieldErrors['s1.f1'], isNull);
    await c.uploadPhoto('s1', 'f1', Uint8List(4));
    expect(c.state.media['s1.f1']!.isReady, isTrue);
    await c.close();
  });

  test('parses the template schema from the API example', () {
    final form = TaskFormModel.formFromJson(_detail());
    expect(form.lockOrder, isTrue);
    expect(form.requireSignature, isTrue);
    expect(form.steps.map((s) => s.id), ['s1', 's2', 's3', 's4']);
    final f1 = form.steps[0].fields.single;
    expect(f1.type, FieldType.photo);
    expect(f1.pairRole, 'before');
    expect(f1.hint, 'Tampak depan, meja terlihat');
    expect(form.steps[2].fields[1].max, 20);
  });

  test('restores progress and opens the first incomplete step', () async {
    repo.submission = TaskFormModel.submissionFromJson({
      'status': 'DIKERJAKAN',
      'steps': [
        {
          'stepId': 's1',
          'complete': true,
          'fields': [
            {
              'fieldId': 'f1',
              'answer': null,
              'media': {
                'mediaId': 'm1',
                'status': 'READY',
                'fileId': 'file1',
              },
            },
          ],
        },
        {
          'stepId': 's2',
          'complete': false,
          'fields': [
            {
              'fieldId': 'f2',
              'answer': {
                'value': ['Kabel rapi'],
              },
              'media': null,
            },
          ],
        },
      ],
    });
    final c = cubit();
    await c.load();
    expect(c.state.status, TaskFormStatus.ready);
    expect(c.state.stepIndex, 1);
    expect(c.state.answers['s2.f2'], ['Kabel rapi']);
    expect(c.state.media['s1.f1']!.isReady, isTrue);
    await c.close();
  });

  test('Lanjut is enabled only when required fields are filled', () async {
    final c = cubit();
    await c.load();
    expect(c.state.stepIndex, 0);
    expect(c.state.canProceed, isFalse); // photo f1 missing

    await c.uploadPhoto('s1', 'f1', Uint8List(4));
    expect(c.state.media['s1.f1']!.isReady, isTrue);
    expect(c.state.media['s1.f1']!.fileId, 'file-m-f1');
    expect(c.state.uploading, isEmpty);
    expect(c.state.canProceed, isTrue);
    await c.close();
  });

  test('a photo whose watermark fails asks to retake', () async {
    repo.mediaStatuses = ['PROCESSING', 'FAILED'];
    final c = cubit();
    await c.load();
    await c.uploadPhoto('s1', 'f1', Uint8List(4));
    expect(c.state.fieldErrors['s1.f1'], contains('Ambil ulang'));
    expect(c.state.canProceed, isFalse);
    await c.close();
  });

  test('saves answers per step in the API shape, then moves on', () async {
    final c = cubit();
    await c.load();
    await c.uploadPhoto('s1', 'f1', Uint8List(4));
    await c.next(); // s1 has only a photo: nothing to save
    expect(repo.saved, isEmpty);
    expect(c.state.stepIndex, 1);

    // Checked out of order: sent in template order.
    c.setAnswer('s2', 'f2', ['Kabel rapi', 'Mesin terpasang']);
    expect(c.state.canProceed, isFalse); // photo f3 missing
    await c.uploadPhoto('s2', 'f3', Uint8List(4));
    await c.next();
    expect(repo.saved['s2'], {
      'f2': ['Mesin terpasang', 'Kabel rapi'],
    });
    expect(c.state.stepIndex, 2);

    c.setAnswer('s3', 'f4', 'Berhasil');
    c.setAnswer('s3', 'f5', '12');
    await c.next();
    expect(repo.saved['s3'], {'f4': 'Berhasil', 'f5': 12, 'f6': null});
    expect(c.state.stepIndex, 3);
    await c.close();
  });

  test('leader: last step submits, then asks for the signature', () async {
    final c = cubit();
    await c.load();
    await _fillAll(c);
    expect(c.state.isLastStep, isTrue);
    expect(c.state.canProceed, isTrue); // signature field never blocks

    await c.next();
    expect(repo.submits, 1);
    expect(c.state.status, TaskFormStatus.awaitingSignature);

    final ok = await c.sign(signerName: 'Ibu Rina', png: Uint8List(4));
    expect(ok, isTrue);
    expect(repo.signedBy, 'Ibu Rina');
    expect(c.state.status, TaskFormStatus.finished);
    await c.close();
  });

  test('member: last step saves without submitting', () async {
    repo = _FakeRepo(TaskFormModel.formFromJson(_detail(myRole: 'MEMBER')));
    final c = cubit();
    await c.load();
    await _fillAll(c);
    await c.next();
    expect(repo.submits, 0);
    expect(c.state.status, TaskFormStatus.finished);
    await c.close();
  });

  test('member of a template without signature: no signature mentioned',
      () async {
    final json = _detail(myRole: 'MEMBER');
    final template = Map<String, dynamic>.from(json['template'] as Map);
    final schema = Map<String, dynamic>.from(template['schema'] as Map);
    schema['steps'] = (schema['steps'] as List).take(3).toList();
    template['schema'] = schema;
    template['requireSignature'] = false;
    repo =
        _FakeRepo(TaskFormModel.formFromJson({...json, 'template': template}));
    expect(repo.form.requireSignature, isFalse);

    final c = cubit();
    await c.load();
    await _fillAll(c); // s3 is the last step here: it finishes
    expect(c.state.status, TaskFormStatus.finished);
    expect(repo.submits, 0);
    expect(c.state.doneMessage, isNot(contains('tanda tangan')));
    await c.close();
  });

  test('a signature field in the schema means a signature is required', () {
    final json = _detail();
    final template = Map<String, dynamic>.from(json['template'] as Map)
      ..remove('requireSignature');
    final form = TaskFormModel.formFromJson({...json, 'template': template});
    expect(form.requireSignature, isTrue);
  });

  test('VALIDATION_ERROR details mark the right field', () async {
    final c = cubit();
    await c.load();
    await c.uploadPhoto('s1', 'f1', Uint8List(4));
    await c.next();
    await c.uploadPhoto('s2', 'f3', Uint8List(4));
    await c.next(); // s2 with f2 empty is blocked client side
    expect(c.state.stepIndex, 1);

    c.setAnswer('s2', 'f2', ['Kabel rapi']);
    await c.next();
    c.setAnswer('s3', 'f4', 'Mungkin');
    repo.saveError = const ServerFailure(
      'Data yang dikirim tidak valid',
      code: 'VALIDATION_ERROR',
      details: {'answers[0].value': '"Mungkin" bukan pilihan yang tersedia'},
    );
    await c.next();
    expect(c.state.stepIndex, 2);
    expect(
      c.state.fieldErrors['s3.f4'],
      '"Mungkin" bukan pilihan yang tersedia',
    );
    await c.close();
  });

  test('TASK_INCOMPLETE on submit opens the step with the missing field',
      () async {
    final c = cubit();
    await c.load();
    await _fillAll(c);
    repo.submitError = const ServerFailure(
      'Masih ada isian wajib yang kosong',
      code: 'TASK_INCOMPLETE',
      details: {'s2.f3': 'wajib diisi'},
    );
    await c.next();
    expect(c.state.stepIndex, 1);
    expect(c.state.fieldErrors['s2.f3'], 'wajib diisi');
    expect(c.state.error, 'Masih ada isian wajib yang kosong');
    await c.close();
  });

  test('fromFirstStep opens step 1 even when steps are complete', () async {
    repo.submission = const Submission(status: 'DIKERJAKAN', steps: [
      StepSnapshot(stepId: 's1', complete: true),
      StepSnapshot(stepId: 's2', complete: true),
    ]);
    final c = cubit();
    await c.load();
    expect(c.state.stepIndex, 2);
    await c.load(fromFirstStep: true);
    expect(c.state.stepIndex, 0);
    await c.close();
  });

  test('leader resumes a task filled by a member: submits without resaving',
      () async {
    repo.submission = TaskFormModel.submissionFromJson({
      'status': 'DIKERJAKAN',
      'steps': [
        for (final id in ['s1', 's2'])
          {'stepId': id, 'complete': true, 'lockedBy': 'member-b'},
        {
          'stepId': 's3',
          'complete': true,
          'lockedBy': 'member-b',
          'fields': [
            {
              'fieldId': 'f4',
              'answer': {'value': 'Berhasil'},
            },
            {
              'fieldId': 'f5',
              'answer': {'value': 12},
            },
          ],
        },
      ],
    });
    // The server rejects any save on the member's steps.
    repo.saveError = const ServerFailure(
      'Langkah sedang dikerjakan anggota lain',
      code: 'TASK_STEP_LOCKED',
      details: {'lockedBy': 'member-b'},
    );
    final c = cubit();
    await c.load();
    expect(c.state.stepIndex, 3);

    // Back to the member's step and on again: unchanged, so not saved.
    c.back();
    await c.next();
    expect(c.state.error, isNull);
    expect(c.state.stepIndex, 3);

    await c.next();
    expect(repo.submits, 1);
    expect(c.state.status, TaskFormStatus.awaitingSignature);
    await c.close();
  });

  test('changing a step locked by a member names that member', () async {
    repo = _FakeRepo(TaskFormModel.formFromJson({
      ..._detail(),
      'team': [
        {'staffId': 'leader-a', 'fullName': 'Teknisi A', 'role': 'LEADER'},
        {'staffId': 'member-b', 'fullName': 'Teknisi B', 'role': 'MEMBER'},
      ],
    }));
    repo.submission = const Submission(status: 'DIKERJAKAN', steps: [
      StepSnapshot(stepId: 's1', complete: true),
      StepSnapshot(stepId: 's2', complete: true),
      StepSnapshot(
        stepId: 's3',
        complete: true,
        lockedBy: 'member-b',
        answers: {'f4': 'Berhasil'},
      ),
    ]);
    repo.saveError = const ServerFailure(
      'Langkah sedang dikerjakan anggota lain',
      code: 'TASK_STEP_LOCKED',
      details: {'lockedBy': 'member-b'},
    );
    final c = cubit();
    await c.load();
    c.back();
    c.setAnswer('s3', 'f4', 'Gagal');
    await c.next();
    expect(c.state.stepIndex, 2);
    expect(
      c.state.error,
      'Langkah sedang dikerjakan anggota lain (Teknisi B)',
    );
    await c.close();
  });

  test('a task waiting for signature opens on the signature', () async {
    repo.submission = const Submission(status: 'MENUNGGU_TTD');
    final c = cubit();
    await c.load();
    expect(c.state.status, TaskFormStatus.awaitingSignature);
    await c.close();
  });
}

/// Fills every step and stops on the last one.
Future<void> _fillAll(TaskFormCubit c) async {
  await c.uploadPhoto('s1', 'f1', Uint8List(4));
  await c.next();
  c.setAnswer('s2', 'f2', ['Mesin terpasang']);
  await c.uploadPhoto('s2', 'f3', Uint8List(4));
  await c.next();
  c.setAnswer('s3', 'f4', 'Berhasil');
  await c.next();
}
