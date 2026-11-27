import 'package:ada_tugas/features/tugas_hari_ini/domain/entities/task_summary.dart';

abstract class TaskRepository {
  /// The logged-in worker's tasks (every status) whose deadline falls in
  /// `[from, to)`, local times. Throws a `Failure` on error.
  Future<List<TaskSummary>> getMyTasks({
    required DateTime from,
    required DateTime to,
  });
}
