import 'package:equatable/equatable.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';

/// Field types of `template.schema` (see the API tab, template versions).
class FieldType {
  FieldType._();

  static const section = 'section';
  static const photo = 'photo';
  static const checklist = 'checklist';
  static const number = 'number';
  static const choice = 'choice';
  static const text = 'text';
  static const qr = 'qr';
  static const signature = 'signature';

  /// Types whose value is sent with `POST .../steps/{stepId}/answers`.
  static const answerTypes = {checklist, number, choice, text, qr};
}

class FormFieldDef extends Equatable {
  final String id;
  final String type;
  final String label;
  final bool required;

  /// `checklist` / `choice` options.
  final List<String> options;

  /// `number` limits (out of range is flagged by the server, not refused).
  final num? min;
  final num? max;

  /// Photo pair role: `before` / `after`.
  final String? pairRole;
  final String? hint;

  const FormFieldDef({
    required this.id,
    required this.type,
    required this.label,
    this.required = false,
    this.options = const [],
    this.min,
    this.max,
    this.pairRole,
    this.hint,
  });

  bool get isAnswer => FieldType.answerTypes.contains(type);

  @override
  List<Object?> get props =>
      [id, type, label, required, options, min, max, pairRole, hint];
}

class FormStepDef extends Equatable {
  final String id;
  final String title;
  final List<FormFieldDef> fields;

  const FormStepDef({
    required this.id,
    required this.title,
    required this.fields,
  });

  @override
  List<Object?> get props => [id, title, fields];
}

/// `GET /api/v1/field/tasks/{id}`: the task and its form schema.
class TaskForm extends Equatable {
  final TaskSummary task;

  /// Steps unlock in order.
  final bool lockOrder;
  final bool requireSignature;
  final List<FormStepDef> steps;

  /// Team mode: staffId → full name (to name who holds a step lock).
  final Map<String, String> team;

  const TaskForm({
    required this.task,
    required this.lockOrder,
    required this.requireSignature,
    required this.steps,
    this.team = const {},
  });

  /// Only the leader submits and asks for the client's signature.
  bool get isLeader => task.myRole == null || task.myRole == 'LEADER';

  @override
  List<Object?> get props => [task, lockOrder, requireSignature, steps, team];
}

/// Key of a field across steps: `stepId.fieldId` (as in TASK_INCOMPLETE).
String fieldKey(String stepId, String fieldId) => '$stepId.$fieldId';

/// An uploaded photo; the watermark is made by the server.
class MediaInfo extends Equatable {
  final String mediaId;

  /// `PROCESSING`, `READY` or `FAILED`.
  final String status;
  final String? fileId;
  final List<String> flags;

  const MediaInfo({
    required this.mediaId,
    required this.status,
    this.fileId,
    this.flags = const [],
  });

  bool get isReady => status == 'READY' && fileId != null;
  bool get isFailed => status == 'FAILED';

  @override
  List<Object?> get props => [mediaId, status, fileId, flags];
}

/// One step as stored on the server (submission / save answers response).
class StepSnapshot extends Equatable {
  final String stepId;
  final bool complete;

  /// Team mode: who is working on this step.
  final String? lockedBy;

  /// fieldId → saved value.
  final Map<String, dynamic> answers;

  /// fieldId → photo.
  final Map<String, MediaInfo> media;

  const StepSnapshot({
    required this.stepId,
    required this.complete,
    this.lockedBy,
    this.answers = const {},
    this.media = const {},
  });

  @override
  List<Object?> get props => [stepId, complete, lockedBy, answers, media];
}

/// `GET /api/v1/field/tasks/{id}/submission`.
class Submission extends Equatable {
  final String status;
  final List<StepSnapshot> steps;
  final bool signed;

  const Submission({
    required this.status,
    this.steps = const [],
    this.signed = false,
  });

  @override
  List<Object?> get props => [status, steps, signed];
}

/// GPS + device time sent with answers, photos and the signature. The
/// server stamps its own time as the proof time.
class GpsEvidence extends Equatable {
  final double latitude;
  final double longitude;
  final double accuracyM;
  final bool mock;
  final DateTime deviceTime;

  const GpsEvidence({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    required this.mock,
    required this.deviceTime,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracyM': accuracyM,
        'mock': mock,
        'deviceTime': deviceTime.toUtc().toIso8601String(),
      };

  /// Same values as strings, for multipart forms.
  Map<String, String> toFormFields() =>
      toJson().map((k, v) => MapEntry(k, v.toString()));

  @override
  List<Object?> get props => [latitude, longitude, accuracyM, mock, deviceTime];
}
