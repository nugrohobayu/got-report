import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ada_tugas/core/error/failures.dart';
import 'package:ada_tugas/core/utils/load_status.dart';
import 'package:ada_tugas/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:ada_tugas/features/tugas_hari_ini/domain/repositories/task_repository.dart';

/// Default range when the page opens: the last 30 days up to today.
const defaultHistoryDays = 30;

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Inclusive range of local days.
typedef DateTimeRangeDays = ({DateTime from, DateTime to});

class TaskHistoryState extends Equatable {
  final LoadStatus status;

  /// Deadline range, both days inclusive (local dates, no time).
  final DateTime from;
  final DateTime to;

  /// Search text; filters the loaded tasks on the device because
  /// `GET /api/v1/field/tasks` has no search parameter.
  final String query;

  /// Every task in [from]..[to] (every status), newest deadline first.
  final List<TaskSummary> tasks;
  final String? errorMessage;

  const TaskHistoryState({
    required this.status,
    required this.from,
    required this.to,
    this.query = '',
    this.tasks = const [],
    this.errorMessage,
  });

  /// [tasks] matching [query] on title, location name / address or
  /// template name (case-insensitive).
  List<TaskSummary> get visibleTasks {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return tasks;
    bool has(String? s) => s != null && s.toLowerCase().contains(q);
    return tasks
        .where((t) =>
            has(t.title) ||
            has(t.location?.name) ||
            has(t.location?.address) ||
            has(t.templateName))
        .toList();
  }

  int get visibleDoneCount => visibleTasks.where((t) => t.isDone).length;

  TaskHistoryState copyWith({
    LoadStatus? status,
    DateTime? from,
    DateTime? to,
    String? query,
    List<TaskSummary>? tasks,
    String? errorMessage,
  }) {
    return TaskHistoryState(
      status: status ?? this.status,
      from: from ?? this.from,
      to: to ?? this.to,
      query: query ?? this.query,
      tasks: tasks ?? this.tasks,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, from, to, query, tasks, errorMessage];
}

/// Assignment history: the worker's tasks whose deadline falls in a chosen
/// date range (default: last [defaultHistoryDays] days), newest first,
/// searchable by text.
class TaskHistoryCubit extends Cubit<TaskHistoryState> {
  final TaskRepository repository;
  final DateTime Function() _now;

  TaskHistoryCubit(this.repository, {DateTime Function()? now})
      : _now = now ?? DateTime.now,
        super(_initial((now ?? DateTime.now)()));

  static TaskHistoryState _initial(DateTime now) {
    final today = _day(now);
    return TaskHistoryState(
      status: LoadStatus.initial,
      from: today.subtract(const Duration(days: defaultHistoryDays - 1)),
      to: today,
    );
  }

  Future<void> load() => _load(state.from, state.to);

  /// Reloads for a new range; [from] and [to] are inclusive days.
  Future<void> setRange(DateTime from, DateTime to) {
    final f = _day(from);
    final t = _day(to);
    if (f == state.from && t == state.to) return Future.value();
    return _load(f, t);
  }

  /// Filters the loaded list; no request.
  void setQuery(String query) => emit(state.copyWith(query: query));

  /// Range for the empty-state reset: today and the next 6 days.
  DateTimeRangeDays get nextWeek {
    final today = _day(_now());
    return (from: today, to: today.add(const Duration(days: 6)));
  }

  /// Whether the empty-state reset would change anything.
  bool get canResetToNextWeek {
    final next = nextWeek;
    return state.query.isNotEmpty ||
        state.from != next.from ||
        state.to != next.to;
  }

  /// Empty-state action: clear the search and show the next 7 days.
  Future<void> resetToNextWeek() {
    final next = nextWeek;
    emit(state.copyWith(query: ''));
    return setRange(next.from, next.to);
  }

  Future<void> _load(DateTime from, DateTime to) async {
    final sameRange = from == state.from && to == state.to;
    emit(state.copyWith(
      status: LoadStatus.loading,
      from: from,
      to: to,
      // Keep the list while refreshing the same range.
      tasks: sameRange ? null : const [],
    ));
    try {
      final tasks = await repository.getMyTasks(
        from: from,
        to: DateTime(to.year, to.month, to.day + 1),
      );
      // The user may have picked another range meanwhile.
      if (isClosed || state.from != from || state.to != to) return;
      // Repository sorts earliest deadline first (no deadline last).
      final dated = tasks.where((t) => t.dueAt != null).toList().reversed;
      final undated = tasks.where((t) => t.dueAt == null);
      emit(state.copyWith(
        status: LoadStatus.loaded,
        tasks: [...dated, ...undated],
      ));
    } on Failure catch (f) {
      if (isClosed || state.from != from || state.to != to) return;
      emit(state.copyWith(status: LoadStatus.failure, errorMessage: f.message));
    }
  }
}
