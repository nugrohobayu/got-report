import 'package:ada_tugas/core/error/exceptions.dart';
import 'package:ada_tugas/features/tugas_hari_ini/domain/entities/task_summary.dart';

/// Parses one item of `data` from `GET /api/v1/field/tasks`.
class TaskSummaryModel {
  TaskSummaryModel._();

  static List<TaskSummary> listFromJson(dynamic json) {
    if (json is! List) throw const ParsingException();
    return json.map(fromJson).toList();
  }

  static TaskSummary fromJson(dynamic json) {
    if (json is! Map || json['id'] is! String || json['status'] is! String) {
      throw const ParsingException();
    }
    final template = json['template'];
    return TaskSummary(
      id: json['id'] as String,
      title: json['title']?.toString() ?? '-',
      status: json['status'] as String,
      overdue: json['overdue'] == true,
      myRole: json['myRole']?.toString(),
      location: _location(json['location']),
      templateName: template is Map ? template['name']?.toString() : null,
      dueAt: _date(json['dueAt']),
      startedAt: _date(json['startedAt']),
      lastRevisionNote: json['lastRevisionNote']?.toString(),
    );
  }

  static TaskLocation? _location(dynamic json) {
    if (json is! Map || json['id'] is! String) return null;
    return TaskLocation(
      id: json['id'] as String,
      name: json['name']?.toString() ?? '-',
      address: json['address']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      radiusM: (json['radiusM'] as num?)?.toInt(),
    );
  }

  /// Server times are UTC ISO-8601; shown in the device's local time.
  static DateTime? _date(dynamic value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
