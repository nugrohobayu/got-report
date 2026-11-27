import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ada_tugas/core/error/failures.dart';
import 'package:ada_tugas/core/utils/load_status.dart';
import 'package:ada_tugas/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:ada_tugas/features/tugas_hari_ini/domain/entities/today_progress.dart';
import 'package:ada_tugas/features/tugas_hari_ini/domain/repositories/task_repository.dart';

class TodayTasksState extends Equatable {
  final LoadStatus status;

  /// Today's tasks (every status), earliest deadline first.
  final List<TaskSummary> tasks;
  final String? errorMessage;

  const TodayTasksState({
    this.status = LoadStatus.initial,
    this.tasks = const [],
    this.errorMessage,
  });

  TaskSummary? get nearest => nearestTask(tasks);

  /// Breakdown for "Progres hari ini" (cancelled tasks not counted).
  TodayProgress get progress => TodayProgress.of(tasks);

  @override
  List<Object?> get props => [status, tasks, errorMessage];
}

/// Loads the tasks due today (device local day) for the home screen.
class TodayTasksCubit extends Cubit<TodayTasksState> {
  final TaskRepository repository;
  final DateTime Function() _now;

  TodayTasksCubit(this.repository, {DateTime Function()? now})
      : _now = now ?? DateTime.now,
        super(const TodayTasksState());

  Future<void> load() async {
    // Keep showing the old list while refreshing (pull to refresh).
    emit(TodayTasksState(status: LoadStatus.loading, tasks: state.tasks));
    final now = _now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day + 1);
    try {
      final tasks = await repository.getMyTasks(from: start, to: end);
      if (isClosed) return;
      emit(TodayTasksState(status: LoadStatus.loaded, tasks: tasks));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(TodayTasksState(
        status: LoadStatus.failure,
        tasks: state.tasks,
        errorMessage: f.message,
      ));
    }
  }
}
