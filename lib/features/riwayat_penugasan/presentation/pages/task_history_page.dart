import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/utils/date_formatter.dart';
import 'package:got_report/core/utils/load_status.dart';
import 'package:got_report/core/widgets/error_view.dart';
import 'package:got_report/features/riwayat_penugasan/presentation/bloc/task_history_cubit.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:got_report/features/tugas_hari_ini/domain/repositories/task_repository.dart';
import 'package:got_report/features/tugas_hari_ini/presentation/widgets/task_card.dart';

/// Riwayat Penugasan tab: tasks of the last 7 / 30 / 90 days, grouped by
/// deadline date, newest first.
class TaskHistoryPage extends StatelessWidget {
  const TaskHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TaskHistoryCubit(context.read<TaskRepository>())..load(),
      child: BlocBuilder<TaskHistoryCubit, TaskHistoryState>(
        builder: (context, state) {
          final cubit = context.read<TaskHistoryCubit>();
          final scheme = Theme.of(context).colorScheme;
          final firstLoad = state.status == LoadStatus.initial ||
              (state.status == LoadStatus.loading && state.tasks.isEmpty);

          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in HistoryPeriod.values)
                      ChoiceChip(
                        label: Text(p.label),
                        selected: p == state.period,
                        onSelected: (_) => cubit.changePeriod(p),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (firstLoad)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.status == LoadStatus.failure &&
                    state.tasks.isEmpty)
                  ErrorView(
                    message: state.errorMessage ?? 'Gagal memuat riwayat.',
                    onRetry: cubit.load,
                  )
                else if (state.tasks.isEmpty)
                  _EmptyHistory(period: state.period)
                else ...[
                  if (state.status == LoadStatus.failure)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        state.errorMessage ?? 'Gagal memperbarui riwayat.',
                        style: TextStyle(color: scheme.error, fontSize: 13),
                      ),
                    ),
                  Text(
                    '${state.doneCount} dari ${state.tasks.length} tugas '
                    'selesai',
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  ..._grouped(state.tasks),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// A date header before each deadline day, then that day's cards.
  List<Widget> _grouped(List<TaskSummary> tasks) {
    final widgets = <Widget>[];
    DateTime? lastDay;
    for (var i = 0; i < tasks.length; i++) {
      final due = tasks[i].dueAt;
      final day = due == null ? null : DateTime(due.year, due.month, due.day);
      if (i == 0 || day != lastDay) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            day == null ? 'Tanpa tenggat' : DateFormatter.fullDate(day),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ));
        lastDay = day;
      }
      widgets
        ..add(TaskCard(task: tasks[i]))
        ..add(const SizedBox(height: 10));
    }
    return widgets;
  }
}

class _EmptyHistory extends StatelessWidget {
  final HistoryPeriod period;

  const _EmptyHistory({required this.period});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.history, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            'Belum ada penugasan dalam ${period.label} terakhir.',
            textAlign: TextAlign.center,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}
