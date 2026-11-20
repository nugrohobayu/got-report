import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/theme/app_colors.dart';
import 'package:got_report/core/utils/date_formatter.dart';
import 'package:got_report/core/utils/load_status.dart';
import 'package:got_report/core/widgets/app_empty_view.dart';
import 'package:got_report/core/widgets/error_view.dart';
import 'package:got_report/features/kalender_tugas/presentation/bloc/task_calendar_cubit.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:got_report/features/tugas_hari_ini/domain/repositories/task_repository.dart';
import 'package:got_report/features/tugas_hari_ini/presentation/widgets/task_card.dart';
import 'package:got_report/features/tugas_hari_ini/presentation/widgets/task_status_chip.dart';
import 'package:table_calendar/table_calendar.dart';

/// Kalender Kerja tab: month calendar of the worker's tasks; a dot per task
/// under each day, and the tasks of the selected day below.
class TaskCalendarPage extends StatelessWidget {
  const TaskCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TaskCalendarCubit(context.read<TaskRepository>())..load(),
      child: const _TaskCalendarView(),
    );
  }
}

class _TaskCalendarView extends StatelessWidget {
  const _TaskCalendarView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Shown as a tab of HomePage, which provides the Scaffold and title.
    return BlocBuilder<TaskCalendarCubit, TaskCalendarState>(
      builder: (context, state) {
        final cubit = context.read<TaskCalendarCubit>();
        return RefreshIndicator(
          onRefresh: cubit.load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: _Calendar(state: state),
                ),
              ),
              if (state.status == LoadStatus.loading)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Text(
                    DateFormatter.fullDate(state.selectedDay),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              ..._dayTasks(context, state),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _dayTasks(BuildContext context, TaskCalendarState state) {
    final cubit = context.read<TaskCalendarCubit>();
    if (state.status == LoadStatus.failure) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(
            message: state.errorMessage ?? 'Gagal memuat tugas.',
            onRetry: cubit.load,
          ),
        ),
      ];
    }
    final tasks = state.selectedTasks;
    if (tasks.isEmpty) {
      if (state.status == LoadStatus.loading) return const [];
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyView(
            message: 'Tidak ada tugas di tanggal ini.',
            icon: Icons.event_available_outlined,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverList.separated(
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) =>
              TaskCard(task: tasks[i], onChanged: cubit.load),
        ),
      ),
    ];
  }
}

class _Calendar extends StatelessWidget {
  final TaskCalendarState state;

  const _Calendar({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskCalendarCubit>();
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();

    return TableCalendar<TaskSummary>(
      locale: 'id_ID',
      firstDay: DateTime(today.year - 1, 1, 1),
      lastDay: DateTime(today.year + 1, 12, 31),
      focusedDay: _focusedDay,
      currentDay: today,
      startingDayOfWeek: StartingDayOfWeek.monday,
      availableCalendarFormats: const {CalendarFormat.month: 'Bulan'},
      rowHeight: 52,
      selectedDayPredicate: (day) => isSameDay(day, state.selectedDay),
      eventLoader: state.tasksOn,
      onDaySelected: (selected, _) => cubit.selectDay(selected),
      onPageChanged: cubit.changeMonth,
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextFormatter: (date, _) => DateFormatter.monthYear(date),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: scheme.primary),
        rightChevronIcon: Icon(Icons.chevron_right, color: scheme.primary),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        weekendStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.statusTerlambat,
        ),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        defaultTextStyle: TextStyle(color: scheme.onSurface),
        weekendTextStyle: const TextStyle(color: AppColors.statusTerlambat),
        todayDecoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
        selectedDecoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      calendarBuilders: CalendarBuilders<TaskSummary>(
        markerBuilder: (context, day, tasks) =>
            tasks.isEmpty ? null : _DayMarkers(tasks: tasks),
      ),
    );
  }

  /// Keep the selected day's month in view; otherwise show the loaded month.
  DateTime get _focusedDay {
    final s = state.selectedDay;
    final m = state.focusedMonth;
    return s.year == m.year && s.month == m.month ? s : m;
  }
}

/// Up to 3 dots colored by task status, then "+n".
class _DayMarkers extends StatelessWidget {
  final List<TaskSummary> tasks;

  const _DayMarkers({required this.tasks});

  @override
  Widget build(BuildContext context) {
    const maxDots = 3;
    return Positioned(
      bottom: 4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final t in tasks.take(maxDots))
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: t.statusColor,
                shape: BoxShape.circle,
              ),
            ),
          if (tasks.length > maxDots)
            Text(
              '+${tasks.length - maxDots}',
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
