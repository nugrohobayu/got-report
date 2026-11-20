import 'package:flutter_test/flutter_test.dart';
import 'package:got_report/core/utils/load_status.dart';
import 'package:got_report/features/riwayat_penugasan/presentation/bloc/task_history_cubit.dart';
import 'package:got_report/features/riwayat_penugasan/presentation/pages/task_history_page.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:got_report/features/tugas_hari_ini/domain/repositories/task_repository.dart';
import 'package:intl/date_symbol_data_local.dart';

class _RecordingTaskRepository implements TaskRepository {
  DateTime? from;
  DateTime? to;
  int calls = 0;
  final List<TaskSummary> tasks;

  _RecordingTaskRepository(this.tasks);

  @override
  Future<List<TaskSummary>> getMyTasks({
    required DateTime from,
    required DateTime to,
  }) async {
    calls++;
    this.from = from;
    this.to = to;
    return tasks;
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  final now = DateTime(2026, 11, 20, 10);

  TaskSummary task(String id, DateTime? due, {String? place}) => TaskSummary(
        id: id,
        title: 'Tugas $id',
        status: TaskStatus.selesai,
        dueAt: due,
        location: place == null ? null : TaskLocation(id: id, name: place),
      );

  test('loads the last 30 days up to the end of today, newest first', () async {
    // Repository order: earliest deadline first, no deadline last.
    final repo = _RecordingTaskRepository([
      task('a', DateTime(2026, 11, 1)),
      task('b', DateTime(2026, 11, 18)),
      task('c', null),
    ]);
    final cubit = TaskHistoryCubit(repo, now: () => now);

    await cubit.load();

    expect(repo.from, DateTime(2026, 10, 22));
    expect(repo.to, DateTime(2026, 11, 21));
    expect(cubit.state.status, LoadStatus.loaded);
    expect(cubit.state.tasks.map((t) => t.id), ['b', 'a', 'c']);
    await cubit.close();
  });

  test('setRange reloads with both days inclusive', () async {
    final repo = _RecordingTaskRepository(const []);
    final cubit = TaskHistoryCubit(repo, now: () => now);

    await cubit.setRange(DateTime(2026, 11, 3), DateTime(2026, 11, 5));

    expect(repo.from, DateTime(2026, 11, 3));
    expect(repo.to, DateTime(2026, 11, 6));
    expect(cubit.state.from, DateTime(2026, 11, 3));
    expect(cubit.state.to, DateTime(2026, 11, 5));
    await cubit.close();
  });

  test('search filters by title or location without a new request', () async {
    final repo = _RecordingTaskRepository([
      task('mesin', DateTime(2026, 11, 19), place: 'Bank Jateng'),
      task('printer', DateTime(2026, 11, 18), place: 'RSUD Kota'),
    ]);
    final cubit = TaskHistoryCubit(repo, now: () => now);
    await cubit.load();

    cubit.setQuery('rsud');
    expect(cubit.state.visibleTasks.map((t) => t.id), ['printer']);
    cubit.setQuery('MESIN');
    expect(cubit.state.visibleTasks.map((t) => t.id), ['mesin']);
    cubit.setQuery('');
    expect(cubit.state.visibleTasks, hasLength(2));
    expect(repo.calls, 1);
    await cubit.close();
  });

  test('empty-state reset clears search and shows the next 7 days', () async {
    final repo = _RecordingTaskRepository(const []);
    final cubit = TaskHistoryCubit(repo, now: () => now);
    await cubit.load();
    cubit.setQuery('xyz');
    expect(cubit.canResetToNextWeek, isTrue);

    await cubit.resetToNextWeek();

    expect(cubit.state.query, '');
    expect(cubit.state.from, DateTime(2026, 11, 20));
    expect(cubit.state.to, DateTime(2026, 11, 26));
    expect(repo.from, DateTime(2026, 11, 20));
    expect(repo.to, DateTime(2026, 11, 27));
    // Already showing it: no button.
    expect(cubit.canResetToNextWeek, isFalse);
    await cubit.close();
  });

  test('dateRangeLabel', () {
    expect(
      dateRangeLabel(DateTime(2026, 11, 20), DateTime(2026, 11, 20)),
      '20 Nov 2026',
    );
    expect(
      dateRangeLabel(DateTime(2026, 11, 1), DateTime(2026, 11, 20)),
      '1 – 20 Nov 2026',
    );
    expect(
      dateRangeLabel(DateTime(2025, 12, 20), DateTime(2026, 1, 5)),
      '20 Des 2025 – 5 Jan 2026',
    );
  });
}
