import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/utils/date_formatter.dart';
import 'package:got_report/core/utils/load_status.dart';
import 'package:got_report/core/widgets/error_view.dart';
import 'package:got_report/features/riwayat_penugasan/presentation/bloc/task_history_cubit.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:got_report/features/tugas_hari_ini/domain/repositories/task_repository.dart';
import 'package:got_report/features/tugas_hari_ini/presentation/widgets/task_card.dart';

/// Riwayat Penugasan tab: search box and deadline date-range filter on top,
/// tasks grouped by deadline date below, newest first.
class TaskHistoryPage extends StatelessWidget {
  const TaskHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TaskHistoryCubit(context.read<TaskRepository>())..load(),
      child: const _TaskHistoryView(),
    );
  }
}

class _TaskHistoryView extends StatelessWidget {
  const _TaskHistoryView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _SearchField(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 4),
          child: _DateRangeFilter(),
        ),
        Expanded(child: _HistoryList()),
      ],
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskHistoryCubit>();
    // The empty-state reset clears the query from the cubit side.
    return BlocListener<TaskHistoryCubit, TaskHistoryState>(
      listenWhen: (a, b) => a.query != b.query,
      listener: (context, state) {
        if (state.query != _controller.text) {
          _controller.text = state.query;
          setState(() {});
        }
      },
      child: _field(cubit),
    );
  }

  Widget _field(TaskHistoryCubit cubit) {
    return TextField(
      controller: _controller,
      onChanged: (v) {
        cubit.setQuery(v);
        setState(() {}); // Show / hide the clear button.
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Cari judul tugas atau lokasi',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Hapus pencarian',
                icon: const Icon(Icons.close),
                onPressed: () {
                  _controller.clear();
                  cubit.setQuery('');
                  setState(() {});
                },
              ),
      ),
    );
  }
}

class _DateRangeFilter extends StatelessWidget {
  const _DateRangeFilter();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(12);
    return BlocBuilder<TaskHistoryCubit, TaskHistoryState>(
      buildWhen: (a, b) => a.from != b.from || a.to != b.to,
      builder: (context, state) {
        return Material(
          color: scheme.surface,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: () => _pickRange(context, state),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: scheme.outline),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tanggal tenggat',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          dateRangeLabel(state.from, state.to),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.expand_more, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickRange(BuildContext context, TaskHistoryState state) async {
    final cubit = context.read<TaskHistoryCubit>();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: state.from, end: state.to),
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Pilih rentang tanggal tenggat',
      saveText: 'Terapkan',
    );
    if (picked != null) cubit.setRange(picked.start, picked.end);
  }
}

/// `20 Nov 2026`, `1 – 20 Nov 2026`, `28 Okt – 20 Nov 2026` or
/// `20 Des 2025 – 5 Jan 2026`.
String dateRangeLabel(DateTime from, DateTime to) {
  String full(DateTime d) => '${DateFormatter.shortDate(d)} ${d.year}';
  if (from == to) return full(to);
  if (from.year != to.year) return '${full(from)} – ${full(to)}';
  if (from.month != to.month) {
    return '${DateFormatter.shortDate(from)} – ${full(to)}';
  }
  return '${from.day} – ${full(to)}';
}

class _HistoryList extends StatelessWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskHistoryCubit, TaskHistoryState>(
      builder: (context, state) {
        final cubit = context.read<TaskHistoryCubit>();
        final scheme = Theme.of(context).colorScheme;
        final tasks = state.visibleTasks;
        final firstLoad = state.status == LoadStatus.initial ||
            (state.status == LoadStatus.loading && state.tasks.isEmpty);

        return RefreshIndicator(
          onRefresh: cubit.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
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
              else if (tasks.isEmpty)
                _EmptyHistory(
                  message: state.query.trim().isEmpty
                      ? 'Belum ada penugasan pada rentang tanggal ini.'
                      : 'Tidak ada tugas yang cocok dengan '
                          '"${state.query.trim()}".',
                  onReset:
                      cubit.canResetToNextWeek ? cubit.resetToNextWeek : null,
                )
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
                  '${state.visibleDoneCount} dari ${tasks.length} tugas '
                  'selesai',
                  style: TextStyle(
                    fontSize: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                ..._grouped(tasks),
              ],
            ],
          ),
        );
      },
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
  final String message;

  /// Clears the search and shows the next 7 days; `null` hides the button
  /// (already showing that).
  final VoidCallback? onReset;

  const _EmptyHistory({required this.message, this.onReset});

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
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: color),
          ),
          if (onReset != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Tampilkan 7 hari ke depan'),
            ),
          ],
        ],
      ),
    );
  }
}
