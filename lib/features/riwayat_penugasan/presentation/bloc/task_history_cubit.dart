import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/error/failures.dart';
import 'package:got_report/core/utils/load_status.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:got_report/features/tugas_hari_ini/domain/repositories/task_repository.dart';

/// How far back the history goes.
enum HistoryPeriod {
  week(7, '7 hari'),
  month(30, '30 hari'),
  quarter(90, '90 hari');

  final int days;
  final String label;

  const HistoryPeriod(this.days, this.label);
}

class TaskHistoryState extends Equatable {
  final LoadStatus status;
  final HistoryPeriod period;

  /// Tasks (every status) due within [period] up to today, newest first.
  final List<TaskSummary> tasks;
  final String? errorMessage;

  const TaskHistoryState({
    this.status = LoadStatus.initial,
    this.period = HistoryPeriod.month,
    this.tasks = const [],
    this.errorMessage,
  });

  int get doneCount => tasks.where((t) => t.isDone).length;

  @override
  List<Object?> get props => [status, period, tasks, errorMessage];
}

/// Assignment history: the worker's tasks due in the last N days
/// (including today), newest deadline first.
class TaskHistoryCubit extends Cubit<TaskHistoryState> {
  final TaskRepository repository;
  final DateTime Function() _now;

  TaskHistoryCubit(this.repository, {DateTime Function()? now})
      : _now = now ?? DateTime.now,
        super(const TaskHistoryState());

  Future<void> load() => _load(state.period);

  void changePeriod(HistoryPeriod period) {
    if (period == state.period) return;
    _load(period);
  }

  Future<void> _load(HistoryPeriod period) async {
    emit(TaskHistoryState(
      status: LoadStatus.loading,
      period: period,
      // Keep the list while refreshing the same period.
      tasks: period == state.period ? state.tasks : const [],
    ));
    final now = _now();
    final end = DateTime(now.year, now.month, now.day + 1);
    final start = DateTime(now.year, now.month, now.day - period.days + 1);
    try {
      final tasks = await repository.getMyTasks(from: start, to: end);
      // The user may have picked another period meanwhile.
      if (isClosed || state.period != period) return;
      // Repository sorts earliest deadline first (no deadline last).
      final dated = tasks.where((t) => t.dueAt != null).toList().reversed;
      final undated = tasks.where((t) => t.dueAt == null);
      emit(TaskHistoryState(
        status: LoadStatus.loaded,
        period: period,
        tasks: [...dated, ...undated],
      ));
    } on Failure catch (f) {
      if (isClosed || state.period != period) return;
      emit(TaskHistoryState(
        status: LoadStatus.failure,
        period: period,
        tasks: state.tasks,
        errorMessage: f.message,
      ));
    }
  }
}
