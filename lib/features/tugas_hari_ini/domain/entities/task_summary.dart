import 'package:equatable/equatable.dart';

/// Backend task statuses (`status` of `/api/v1/field/tasks`).
class TaskStatus {
  TaskStatus._();

  static const ditugaskan = 'DITUGASKAN';
  static const dikerjakan = 'DIKERJAKAN';
  static const menungguTtd = 'MENUNGGU_TTD';
  static const perluRevisi = 'PERLU_REVISI';
  static const selesai = 'SELESAI';

  /// Cancelled by an admin/supervisor. Shown in the list, but there is
  /// nothing left to do.
  static const dibatalkan = 'DIBATALKAN';

  /// Statuses the field worker still works on or has finished
  /// ([isActive] relies on this, so [dibatalkan] is left out).
  static const all = [
    ditugaskan,
    dikerjakan,
    menungguTtd,
    perluRevisi,
    selesai
  ];
}

class TaskLocation extends Equatable {
  final String id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int? radiusM;

  const TaskLocation({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.radiusM,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  @override
  List<Object?> get props => [id, name, address, latitude, longitude, radiusM];
}

/// One item of `GET /api/v1/field/tasks` (no template schema / team: fetch
/// the detail for those).
class TaskSummary extends Equatable {
  final String id;
  final String title;
  final String status;
  final bool overdue;

  /// `LEADER` or `MEMBER`.
  final String? myRole;
  final TaskLocation? location;
  final String? templateName;

  /// Local time (converted from the server's UTC).
  final DateTime? dueAt;
  final DateTime? startedAt;
  final String? lastRevisionNote;

  const TaskSummary({
    required this.id,
    required this.title,
    required this.status,
    this.overdue = false,
    this.myRole,
    this.location,
    this.templateName,
    this.dueAt,
    this.startedAt,
    this.lastRevisionNote,
  });

  bool get isDone => status == TaskStatus.selesai;

  bool get isCancelled => status == TaskStatus.dibatalkan;

  /// Still needs work from the field worker.
  bool get isActive => TaskStatus.all.contains(status) && !isDone;

  @override
  List<Object?> get props => [
        id,
        title,
        status,
        overdue,
        myRole,
        location,
        templateName,
        dueAt,
        startedAt,
        lastRevisionNote,
      ];
}

/// The task to do next: the unfinished one with the earliest deadline
/// (overdue ones come first, they are the most urgent). Tasks without a
/// deadline come last.
TaskSummary? nearestTask(Iterable<TaskSummary> tasks) {
  final active = tasks.where((t) => t.isActive).toList()..sort(compareByDue);
  return active.isEmpty ? null : active.first;
}

/// Earliest `dueAt` first; tasks without a deadline last.
int compareByDue(TaskSummary a, TaskSummary b) {
  final da = a.dueAt;
  final db = b.dueAt;
  if (da == null && db == null) return 0;
  if (da == null) return 1;
  if (db == null) return -1;
  return da.compareTo(db);
}
