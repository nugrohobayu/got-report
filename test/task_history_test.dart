import 'package:flutter_test/flutter_test.dart';
import 'package:got_report/core/utils/load_status.dart';
import 'package:got_report/features/riwayat_penugasan/presentation/bloc/task_history_cubit.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:got_report/features/tugas_hari_ini/domain/repositories/task_repository.dart';

class _RecordingTaskRepository implements TaskRepository {
  DateTime? from;
  DateTime? to;
  final List<TaskSummary> tasks;

  _RecordingTaskRepository(this.tasks);

  @override
  Future<List<TaskSummary>> getMyTasks({
    required DateTime from,
    required DateTime to,
  }) async {
    this.from = from;
    this.to = to;
    return tasks;
  }
}

void main() {
  final now = DateTime(2026, 11, 19, 10);

  TaskSummary task(String id, DateTime? due) =>
      TaskSummary(id: id, title: id, status: TaskStatus.selesai, dueAt: due);

  test('loads the last 30 days up to the end of today, newest first',
      () async {
    // Repository order: earliest deadline first, no deadline last.
    final repo = _RecordingTaskRepository([
      task('a', DateTime(2026, 11, 1)),
      task('b', DateTime(2026, 11, 18)),
      task('c', null),
    ]);
    final cubit = TaskHistoryCubit(repo, now: () => now);

    await cubit.load();

    expect(repo.from, DateTime(2026, 10, 21));
    expect(repo.to, DateTime(2026, 11, 20));
    expect(cubit.state.status, LoadStatus.loaded);
    expect(cubit.state.tasks.map((t) => t.id), ['b', 'a', 'c']);
    await cubit.close();
  });

  test('changing the period reloads with the new range', () async {
    final repo = _RecordingTaskRepository(const []);
    final cubit = TaskHistoryCubit(repo, now: () => now);

    cubit.changePeriod(HistoryPeriod.week);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.period, HistoryPeriod.week);
    expect(repo.from, DateTime(2026, 11, 13));
    await cubit.close();
  });
}
