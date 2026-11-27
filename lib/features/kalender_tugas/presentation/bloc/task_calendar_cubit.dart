import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ada_tugas/core/error/failures.dart';
import 'package:ada_tugas/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:ada_tugas/features/tugas_hari_ini/domain/repositories/task_repository.dart';
import 'package:ada_tugas/core/utils/load_status.dart';

/// Date-only key (local midnight) used to group tasks per calendar day.
DateTime dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

class TaskCalendarState extends Equatable {
  final LoadStatus status;

  /// First day of the month shown in the calendar.
  final DateTime focusedMonth;
  final DateTime selectedDay;

  /// Tasks of [focusedMonth] grouped by [dayKey] of their deadline.
  final Map<DateTime, List<TaskSummary>> tasksByDay;
  final String? errorMessage;

  const TaskCalendarState({
    required this.status,
    required this.focusedMonth,
    required this.selectedDay,
    this.tasksByDay = const {},
    this.errorMessage,
  });

  List<TaskSummary> tasksOn(DateTime day) =>
      tasksByDay[dayKey(day)] ?? const [];

  List<TaskSummary> get selectedTasks => tasksOn(selectedDay);

  TaskCalendarState copyWith({
    LoadStatus? status,
    DateTime? focusedMonth,
    DateTime? selectedDay,
    Map<DateTime, List<TaskSummary>>? tasksByDay,
    String? errorMessage,
  }) {
    return TaskCalendarState(
      status: status ?? this.status,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedDay: selectedDay ?? this.selectedDay,
      tasksByDay: tasksByDay ?? this.tasksByDay,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, focusedMonth, selectedDay, tasksByDay, errorMessage];
}

/// Month calendar of the worker's tasks. Loads one month at a time.
class TaskCalendarCubit extends Cubit<TaskCalendarState> {
  final TaskRepository repository;

  TaskCalendarCubit(this.repository, {DateTime? today})
      : super(_initial(today ?? DateTime.now()));

  static TaskCalendarState _initial(DateTime today) => TaskCalendarState(
        status: LoadStatus.initial,
        focusedMonth: DateTime(today.year, today.month),
        selectedDay: dayKey(today),
      );

  Future<void> load() => _loadMonth(state.focusedMonth);

  void selectDay(DateTime day) {
    final key = dayKey(day);
    final month = DateTime(key.year, key.month);
    emit(state.copyWith(selectedDay: key, status: state.status));
    // Tapping a day of the previous / next month shown in the grid.
    if (month != state.focusedMonth) _loadMonth(month);
  }

  void changeMonth(DateTime anyDayInMonth) {
    final month = DateTime(anyDayInMonth.year, anyDayInMonth.month);
    if (month == state.focusedMonth) return;
    _loadMonth(month);
  }

  Future<void> _loadMonth(DateTime month) async {
    emit(state.copyWith(
      status: LoadStatus.loading,
      focusedMonth: month,
      tasksByDay: month == state.focusedMonth ? null : const {},
    ));
    try {
      final tasks = await repository.getMyTasks(
        from: month,
        to: DateTime(month.year, month.month + 1),
      );
      // The user may have moved to another month meanwhile.
      if (isClosed || state.focusedMonth != month) return;
      final byDay = <DateTime, List<TaskSummary>>{};
      for (final t in tasks) {
        final due = t.dueAt;
        if (due == null) continue;
        byDay.putIfAbsent(dayKey(due), () => []).add(t);
      }
      emit(state.copyWith(status: LoadStatus.loaded, tasksByDay: byDay));
    } on Failure catch (f) {
      if (isClosed || state.focusedMonth != month) return;
      emit(state.copyWith(status: LoadStatus.failure, errorMessage: f.message));
    }
  }
}
