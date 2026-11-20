import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/error/failures.dart';
import 'package:got_report/core/location/location_service.dart';
import 'package:got_report/features/form_dinamis/domain/entities/task_form.dart';
import 'package:got_report/features/form_dinamis/domain/repositories/task_form_repository.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';

enum TaskFormStatus {
  loading,
  loadFailed,
  ready,

  /// Leader submitted; the client's signature is next.
  awaitingSignature,

  /// Nothing left to do on this device (SELESAI, or a team member whose
  /// part is saved).
  finished,
}

class TaskFormState extends Equatable {
  final TaskFormStatus status;
  final TaskForm? form;
  final String taskStatus;
  final int stepIndex;

  /// Current answer values, `stepId.fieldId` → value.
  final Map<String, dynamic> answers;

  /// Photos, `stepId.fieldId` → media.
  final Map<String, MediaInfo> media;

  /// Photo fields being uploaded / watermarked.
  final Set<String> uploading;

  /// Steps the server reports complete.
  final Set<String> completeSteps;

  /// Per-field errors from the server, `stepId.fieldId` → message.
  final Map<String, String> fieldErrors;

  /// Saving answers / submitting / signing.
  final bool saving;
  final String? error;

  /// Shown when finished, e.g. "Tugas selesai".
  final String? doneMessage;

  const TaskFormState({
    this.status = TaskFormStatus.loading,
    this.form,
    this.taskStatus = '',
    this.stepIndex = 0,
    this.answers = const {},
    this.media = const {},
    this.uploading = const {},
    this.completeSteps = const {},
    this.fieldErrors = const {},
    this.saving = false,
    this.error,
    this.doneMessage,
  });

  List<FormStepDef> get steps => form?.steps ?? const [];

  FormStepDef? get step => stepIndex < steps.length ? steps[stepIndex] : null;

  bool get isLastStep => stepIndex >= steps.length - 1;

  bool get busy => saving || uploading.isNotEmpty;

  /// A required field counts as filled when it has a non-empty value, or
  /// for photos an upload that did not fail. Section and signature fields
  /// never block (the client signs after submit).
  bool isFilled(String stepId, FormFieldDef field) {
    final key = fieldKey(stepId, field.id);
    switch (field.type) {
      case FieldType.photo:
        final m = media[key];
        return m != null && !m.isFailed;
      case FieldType.section:
      case FieldType.signature:
        return true;
      default:
        return !_isEmpty(answers[key]);
    }
  }

  /// "Lanjut" is enabled only when every required field of the current
  /// step is filled.
  bool get canProceed {
    final s = step;
    if (s == null || busy) return false;
    return s.fields.where((f) => f.required).every((f) => isFilled(s.id, f));
  }

  TaskFormState copyWith({
    TaskFormStatus? status,
    TaskForm? form,
    String? taskStatus,
    int? stepIndex,
    Map<String, dynamic>? answers,
    Map<String, MediaInfo>? media,
    Set<String>? uploading,
    Set<String>? completeSteps,
    Map<String, String>? fieldErrors,
    bool? saving,
    String? error,
    bool clearError = false,
    String? doneMessage,
  }) {
    return TaskFormState(
      status: status ?? this.status,
      form: form ?? this.form,
      taskStatus: taskStatus ?? this.taskStatus,
      stepIndex: stepIndex ?? this.stepIndex,
      answers: answers ?? this.answers,
      media: media ?? this.media,
      uploading: uploading ?? this.uploading,
      completeSteps: completeSteps ?? this.completeSteps,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
      doneMessage: doneMessage ?? this.doneMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        form,
        taskStatus,
        stepIndex,
        answers,
        media,
        uploading,
        completeSteps,
        fieldErrors,
        saving,
        error,
        doneMessage,
      ];
}

bool _isEmpty(dynamic v) =>
    v == null || (v is String && v.trim().isEmpty) || (v is List && v.isEmpty);

/// Dynamic form of a started task: steps in order, answers saved per step,
/// camera photos watermarked by the server, then submit and the client's
/// signature.
class TaskFormCubit extends Cubit<TaskFormState> {
  final TaskFormRepository repository;
  final LocationService locationService;
  final String taskId;
  final DateTime Function() _now;

  /// How long to wait for the server watermark before giving up.
  final Duration mediaPollInterval;
  final int mediaPollAttempts;

  /// A GPS fix is reused for this long between saves.
  static const maxFixAge = Duration(seconds: 60);
  DeviceLocation? _fix;

  TaskFormCubit({
    required this.repository,
    required this.locationService,
    required this.taskId,
    DateTime Function()? now,
    this.mediaPollInterval = const Duration(seconds: 1),
    this.mediaPollAttempts = 20,
  })  : _now = now ?? DateTime.now,
        super(const TaskFormState());

  Future<void> load({bool fromFirstStep = false}) async {
    emit(const TaskFormState());
    try {
      final results = await Future.wait([
        repository.getForm(taskId),
        repository.getSubmission(taskId),
      ]);
      if (isClosed) return;
      final form = results[0] as TaskForm;
      final submission = results[1] as Submission;
      _restore(form, submission, fromFirstStep: fromFirstStep);
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(status: TaskFormStatus.loadFailed, error: f.message));
    }
  }

  void _restore(
    TaskForm form,
    Submission submission, {
    bool fromFirstStep = false,
  }) {
    final answers = <String, dynamic>{};
    final media = <String, MediaInfo>{};
    final complete = <String>{};
    for (final s in submission.steps) {
      s.answers.forEach((id, v) => answers[fieldKey(s.stepId, id)] = v);
      s.media.forEach((id, m) => media[fieldKey(s.stepId, id)] = m);
      if (s.complete) complete.add(s.stepId);
    }
    // Open the first step that is not complete yet, or step 1 when asked
    // (a revision redoes the work from the photos; old answers and photos
    // are kept and can be replaced).
    var index = fromFirstStep
        ? 0
        : form.steps.indexWhere((s) => !complete.contains(s.id));
    if (index < 0) index = form.steps.isEmpty ? 0 : form.steps.length - 1;

    final taskStatus =
        submission.status.isEmpty ? form.task.status : submission.status;
    emit(TaskFormState(
      status: switch (taskStatus) {
        TaskStatus.menungguTtd => TaskFormStatus.awaitingSignature,
        TaskStatus.selesai => TaskFormStatus.finished,
        _ => TaskFormStatus.ready,
      },
      form: form,
      taskStatus: taskStatus,
      stepIndex: index,
      answers: answers,
      media: media,
      completeSteps: complete,
      doneMessage:
          taskStatus == TaskStatus.selesai ? 'Tugas ini sudah selesai.' : null,
    ));
  }

  void setAnswer(String stepId, String fieldId, dynamic value) {
    final key = fieldKey(stepId, fieldId);
    final errors = Map.of(state.fieldErrors)..remove(key);
    emit(state.copyWith(
      answers: {...state.answers, key: value},
      fieldErrors: errors,
    ));
  }

  void back() {
    if (state.stepIndex == 0 || state.busy) return;
    emit(state.copyWith(stepIndex: state.stepIndex - 1, clearError: true));
  }

  /// Uploads a camera photo and waits for the server watermark.
  Future<void> uploadPhoto(
    String stepId,
    String fieldId,
    Uint8List jpeg,
  ) async {
    final key = fieldKey(stepId, fieldId);
    final errors = Map.of(state.fieldErrors)..remove(key);
    emit(state.copyWith(
      uploading: {...state.uploading, key},
      fieldErrors: errors,
      clearError: true,
    ));
    try {
      final evidence = await _evidence();
      var media = await repository.uploadPhoto(
        taskId,
        stepId: stepId,
        fieldId: fieldId,
        jpeg: jpeg,
        evidence: evidence,
      );
      _setMedia(key, media);
      for (var i = 0;
          i < mediaPollAttempts && !media.isReady && !media.isFailed;
          i++) {
        await Future<void>.delayed(mediaPollInterval);
        if (isClosed) return;
        media = await repository.getMedia(taskId, media.mediaId);
        _setMedia(key, media);
      }
      if (media.isFailed) {
        _fieldError(key, 'Foto tidak terbaca. Ambil ulang foto.');
      }
    } on Failure catch (f) {
      _fieldError(key, _message(f));
    } on LocationUnavailable catch (e) {
      _fieldError(key, e.message);
    } finally {
      if (!isClosed) {
        emit(state.copyWith(uploading: {...state.uploading}..remove(key)));
      }
    }
  }

  /// Saves the current step, then opens the next one; on the last step the
  /// leader submits (→ signature or finished).
  Future<void> next() async {
    final step = state.step;
    if (step == null || !state.canProceed) return;
    emit(state.copyWith(saving: true, clearError: true));
    try {
      final answerFields = step.fields.where((f) => f.isAnswer).toList();
      if (answerFields.isNotEmpty) {
        final sent = {
          for (final f in answerFields)
            f.id: _normalize(f, state.answers[fieldKey(step.id, f.id)]),
        };
        final saved = await repository.saveAnswers(
          taskId,
          step.id,
          sent,
          await _evidence(),
        );
        if (isClosed) return;
        _applyStep(saved);
      }
      if (!state.isLastStep) {
        emit(state.copyWith(stepIndex: state.stepIndex + 1, saving: false));
        return;
      }
      await _finish();
    } on Failure catch (f) {
      if (isClosed) return;
      _handleSaveFailure(f, step);
    } on LocationUnavailable catch (e) {
      if (isClosed) return;
      emit(state.copyWith(saving: false, error: e.message));
    }
  }

  Future<void> _finish() async {
    final form = state.form!;
    if (!form.isLeader) {
      emit(state.copyWith(
        saving: false,
        status: TaskFormStatus.finished,
        doneMessage: 'Bagian Anda tersimpan. Ketua tim akan mengirim hasil '
            'dan meminta tanda tangan klien.',
      ));
      return;
    }
    final task = await repository.submit(taskId);
    if (isClosed) return;
    final signature = task.status == TaskStatus.menungguTtd;
    emit(state.copyWith(
      saving: false,
      taskStatus: task.status,
      status: signature
          ? TaskFormStatus.awaitingSignature
          : TaskFormStatus.finished,
      doneMessage: signature ? null : 'Tugas selesai. Terima kasih!',
    ));
  }

  /// Sends the client's signature; the task becomes SELESAI.
  Future<bool> sign({
    required String signerName,
    String? signerTitle,
    required Uint8List png,
  }) async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      final task = await repository.sign(
        taskId,
        signerName: signerName,
        signerTitle: signerTitle,
        png: png,
        evidence: await _evidence(),
      );
      if (isClosed) return false;
      emit(state.copyWith(
        saving: false,
        taskStatus: task.status,
        status: TaskFormStatus.finished,
        doneMessage: 'Tugas selesai. Laporan BAST dibuat otomatis.',
      ));
      return true;
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(saving: false, error: _message(f)));
      return false;
    } on LocationUnavailable catch (e) {
      if (!isClosed) emit(state.copyWith(saving: false, error: e.message));
      return false;
    }
  }

  Future<Uint8List> fileBytes(String fileId) => repository.fileBytes(fileId);

  // ---------------------------------------------------------------------

  /// Values in the shape the API expects per type.
  dynamic _normalize(FormFieldDef f, dynamic v) {
    if (_isEmpty(v)) return null;
    if (f.type == FieldType.number && v is String) {
      return num.tryParse(v.replaceAll(',', '.'));
    }
    if (f.type == FieldType.checklist && v is List) {
      // Keep the template order.
      return f.options.where(v.contains).toList();
    }
    return v is String ? v.trim() : v;
  }

  void _applyStep(StepSnapshot s) {
    final complete = {...state.completeSteps};
    s.complete ? complete.add(s.stepId) : complete.remove(s.stepId);
    final media = {...state.media};
    s.media.forEach((id, m) => media[fieldKey(s.stepId, id)] = m);
    emit(state.copyWith(completeSteps: complete, media: media));
  }

  void _handleSaveFailure(Failure f, FormStepDef step) {
    final errors = <String, String>{};
    var index = state.stepIndex;
    if (f is ServerFailure) {
      if (f.code == 'VALIDATION_ERROR') {
        // details: {"answers[i].value": "..."} → i-th sent answer field.
        final answerFields = step.fields.where((x) => x.isAnswer).toList();
        f.details.forEach((k, v) {
          final m = RegExp(r'answers\[(\d+)\]').firstMatch(k);
          final i = m == null ? null : int.tryParse(m.group(1)!);
          if (i != null && i < answerFields.length) {
            errors[fieldKey(step.id, answerFields[i].id)] = v.toString();
          }
        });
      } else if (f.code == 'TASK_INCOMPLETE') {
        // details: {"s2.f3": "wajib diisi"} → open the first such step.
        f.details.forEach((k, v) => errors[k] = v.toString());
        final first = state.steps.indexWhere(
          (s) => f.details.keys.any((k) => k.startsWith('${s.id}.')),
        );
        if (first >= 0) index = first;
      }
    }
    emit(state.copyWith(
      saving: false,
      stepIndex: index,
      fieldErrors: {...state.fieldErrors, ...errors},
      error: _message(f),
    ));
  }

  String _message(Failure f) {
    if (f is ServerFailure) {
      switch (f.code) {
        case 'TASK_STEP_LOCKED':
          return 'Langkah ini sedang dikerjakan anggota tim lain.';
        case 'TASK_LEADER_ONLY':
          return 'Hanya ketua tim yang dapat mengirim hasil.';
        case 'VALIDATION_ERROR':
          return 'Periksa kembali isian yang ditandai.';
      }
    }
    return f.message;
  }

  void _setMedia(String key, MediaInfo media) {
    if (!isClosed) emit(state.copyWith(media: {...state.media, key: media}));
  }

  void _fieldError(String key, String message) {
    if (!isClosed) {
      emit(state.copyWith(fieldErrors: {...state.fieldErrors, key: message}));
    }
  }

  Future<GpsEvidence> _evidence() async {
    var fix = _fix;
    if (fix == null || _now().difference(fix.readAt) > maxFixAge) {
      fix = _fix = await locationService.current();
    }
    return GpsEvidence(
      latitude: fix.latitude,
      longitude: fix.longitude,
      accuracyM: fix.accuracyM,
      mock: fix.mock,
      deviceTime: _now().toUtc(),
    );
  }
}
