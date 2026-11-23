import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';

/// Buckets of the "Progres hari ini" breakdown, most urgent first.
enum ProgressGroup { late, running, notStarted, done, cancelled }

extension TaskProgressGroup on TaskSummary {
  /// Overdue wins over the backend status (except for finished/cancelled
  /// tasks, which are never late).
  ProgressGroup get progressGroup {
    if (isCancelled) return ProgressGroup.cancelled;
    if (isDone) return ProgressGroup.done;
    if (overdue) return ProgressGroup.late;
    return switch (status) {
      TaskStatus.dikerjakan ||
      TaskStatus.menungguTtd ||
      TaskStatus.perluRevisi =>
        ProgressGroup.running,
      _ => ProgressGroup.notStarted,
    };
  }
}

/// Breakdown of today's tasks by [ProgressGroup]. Cancelled tasks are
/// listed but not counted in [total] (nothing left to do on them).
class TodayProgress {
  /// Tasks per group, each sorted by deadline (earliest first).
  final Map<ProgressGroup, List<TaskSummary>> groups;

  TodayProgress._(this.groups);

  factory TodayProgress.of(Iterable<TaskSummary> tasks) {
    final groups = {for (final g in ProgressGroup.values) g: <TaskSummary>[]};
    for (final t in tasks) {
      groups[t.progressGroup]!.add(t);
    }
    for (final list in groups.values) {
      list.sort(compareByDue);
    }
    return TodayProgress._(groups);
  }

  int count(ProgressGroup g) => groups[g]!.length;

  int get done => count(ProgressGroup.done);

  /// Tasks that count toward progress (everything but cancelled).
  int get total => groups.entries
      .where((e) => e.key != ProgressGroup.cancelled)
      .fold(0, (sum, e) => sum + e.value.length);

  /// 0..1; 0 when there is nothing to do.
  double get ratio => total == 0 ? 0 : done / total;

  int get percent => (ratio * 100).round();
}
