import 'package:got_report/core/error/exceptions.dart';
import 'package:got_report/features/form_dinamis/domain/entities/task_form.dart';
import 'package:got_report/features/tugas_hari_ini/data/models/task_summary_model.dart';

/// Parsers for the form endpoints (shapes from the API tab examples).
class TaskFormModel {
  TaskFormModel._();

  /// `GET /api/v1/field/tasks/{id}` → task + `template.schema`.
  static TaskForm formFromJson(dynamic json) {
    if (json is! Map) throw const ParsingException();
    final template = json['template'];
    final schema = template is Map ? template['schema'] : null;
    final steps = schema is Map ? schema['steps'] : null;
    return TaskForm(
      task: TaskSummaryModel.fromJson(json),
      lockOrder: schema is Map && schema['lockOrder'] == true,
      requireSignature: template is Map && template['requireSignature'] == true,
      steps:
          steps is List ? steps.whereType<Map>().map(_step).toList() : const [],
    );
  }

  static FormStepDef _step(Map json) {
    final fields = json['fields'];
    return FormStepDef(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      fields: fields is List
          ? fields.whereType<Map>().map(_field).toList()
          : const [],
    );
  }

  static FormFieldDef _field(Map json) {
    final options = json['options'];
    final pair = json['pair'];
    final hint = json['hint'];
    return FormFieldDef(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      required: json['required'] == true,
      options: options is List
          ? options.map((o) => o.toString()).toList()
          : const [],
      min: json['min'] as num?,
      max: json['max'] as num?,
      pairRole: pair is Map ? pair['role']?.toString() : null,
      hint: hint is Map ? hint['text']?.toString() : hint?.toString(),
    );
  }

  /// `GET .../submission`.
  static Submission submissionFromJson(dynamic json) {
    if (json is! Map) throw const ParsingException();
    final steps = json['steps'];
    return Submission(
      status: json['status']?.toString() ?? '',
      steps: steps is List
          ? steps.whereType<Map>().map(stepFromJson).toList()
          : const [],
      signed: json['signature'] is Map,
    );
  }

  /// A step of the submission, also the response of saving answers.
  static StepSnapshot stepFromJson(dynamic json) {
    if (json is! Map) throw const ParsingException();
    final answers = <String, dynamic>{};
    final media = <String, MediaInfo>{};
    final fields = json['fields'];
    if (fields is List) {
      for (final f in fields.whereType<Map>()) {
        final id = f['fieldId']?.toString();
        if (id == null) continue;
        final answer = f['answer'];
        if (answer is Map) answers[id] = answer['value'];
        final m = f['media'];
        if (m is Map) media[id] = mediaFromJson(m);
      }
    }
    return StepSnapshot(
      stepId: json['stepId']?.toString() ?? '',
      complete: json['complete'] == true,
      lockedBy: json['lockedBy']?.toString(),
      answers: answers,
      media: media,
    );
  }

  /// `POST .../media` (202) and `GET .../media/{mediaId}`.
  static MediaInfo mediaFromJson(dynamic json) {
    if (json is! Map || json['mediaId'] is! String) {
      throw const ParsingException();
    }
    final flags = json['flags'];
    return MediaInfo(
      mediaId: json['mediaId'] as String,
      status: json['status']?.toString() ?? 'PROCESSING',
      fileId: json['fileId']?.toString(),
      flags: flags is List ? flags.map((f) => f.toString()).toList() : const [],
    );
  }
}
