import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/theme/app_colors.dart';
import 'package:got_report/core/utils/date_formatter.dart';
import 'package:got_report/core/utils/load_status.dart';
import 'package:got_report/core/widgets/error_view.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/today_progress.dart';
import 'package:got_report/features/tugas_hari_ini/presentation/bloc/today_tasks_cubit.dart';
import 'package:got_report/features/tugas_hari_ini/presentation/widgets/task_card.dart';

/// Opens [TodayProgressPage] on the Beranda's [TodayTasksCubit], so both
/// screens show (and refresh) the same list.
Future<void> openTodayProgress(BuildContext context) {
  final cubit = context.read<TodayTasksCubit>();
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      settings: const RouteSettings(name: 'todayProgress'),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const TodayProgressPage(),
      ),
    ),
  );
}

extension ProgressGroupView on ProgressGroup {
  String get label => switch (this) {
        ProgressGroup.late => 'Terlambat',
        ProgressGroup.running => 'Berjalan',
        ProgressGroup.notStarted => 'Belum mulai',
        ProgressGroup.done => 'Selesai',
        ProgressGroup.cancelled => 'Dibatalkan',
      };

  /// Same status colors as the web (cancelled is grey like "Belum").
  Color get color => switch (this) {
        ProgressGroup.late => AppColors.statusTerlambat,
        ProgressGroup.running => AppColors.statusBerjalan,
        ProgressGroup.notStarted => AppColors.statusBelum,
        ProgressGroup.done => AppColors.statusSelesai,
        ProgressGroup.cancelled => AppColors.statusBelum,
      };

  IconData get icon => switch (this) {
        ProgressGroup.late => Icons.warning_amber_rounded,
        ProgressGroup.running => Icons.play_circle_outline,
        ProgressGroup.notStarted => Icons.radio_button_unchecked,
        ProgressGroup.done => Icons.check_circle_outline,
        ProgressGroup.cancelled => Icons.block,
      };
}

/// "Progres hari ini" in detail: percentage done, a bar split by status,
/// the count per status, and today's tasks grouped by status (most urgent
/// first). Cancelled tasks are listed but not counted in the progress.
class TodayProgressPage extends StatelessWidget {
  const TodayProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progres hari ini')),
      body: BlocBuilder<TodayTasksCubit, TodayTasksState>(
        builder: (context, state) {
          final cubit = context.read<TodayTasksCubit>();
          final progress = state.progress;
          final firstLoad = state.status == LoadStatus.initial ||
              (state.status == LoadStatus.loading && state.tasks.isEmpty);

          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                if (firstLoad)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.status == LoadStatus.failure &&
                    state.tasks.isEmpty)
                  ErrorView(
                    message: state.errorMessage ?? 'Gagal memuat tugas.',
                    onRetry: cubit.load,
                  )
                else ...[
                  if (state.status == LoadStatus.failure)
                    _InlineError(message: state.errorMessage),
                  _SummaryCard(progress: progress),
                  const SizedBox(height: 16),
                  _CountGrid(progress: progress),
                  const SizedBox(height: 8),
                  if (state.tasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        'Tidak ada tugas dengan tenggat hari ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  for (final g in ProgressGroup.values)
                    if (progress.count(g) > 0) ...[
                      const SizedBox(height: 16),
                      _GroupHeader(group: g, count: progress.count(g)),
                      const SizedBox(height: 10),
                      for (final t in progress.groups[g]!) ...[
                        TaskCard(task: t, onChanged: cubit.load),
                        const SizedBox(height: 10),
                      ],
                    ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Date, "x dari y tugas selesai", percentage and a bar split by status.
class _SummaryCard extends StatelessWidget {
  final TodayProgress progress;

  const _SummaryCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = progress.total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormatter.fullDate(DateTime.now()),
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  total == 0
                      ? 'Belum ada tugas hari ini'
                      : '${progress.done} dari $total tugas selesai',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (total > 0)
                Text(
                  '${progress.percent}%',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.statusSelesai,
                  ),
                ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            _StackedBar(progress: progress),
          ],
        ],
      ),
    );
  }
}

/// One bar, one segment per non-empty status (cancelled left out).
class _StackedBar extends StatelessWidget {
  final TodayProgress progress;

  const _StackedBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    // Done first so the bar fills from the left as work gets finished.
    const order = [
      ProgressGroup.done,
      ProgressGroup.running,
      ProgressGroup.late,
      ProgressGroup.notStarted,
    ];
    final segments = [
      for (final g in order)
        if (progress.count(g) > 0) g,
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (var i = 0; i < segments.length; i++)
              Expanded(
                flex: progress.count(segments[i]),
                child: Container(
                  margin: EdgeInsets.only(
                    right: i == segments.length - 1 ? 0 : 2,
                  ),
                  color: segments[i].color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Count per status, two per row.
class _CountGrid extends StatelessWidget {
  final TodayProgress progress;

  const _CountGrid({required this.progress});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      for (final g in ProgressGroup.values)
        _CountTile(group: g, count: progress.count(g)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in tiles) SizedBox(width: width, child: t),
          ],
        );
      },
    );
  }
}

class _CountTile extends StatelessWidget {
  final ProgressGroup group;
  final int count;

  const _CountTile({required this.group, required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = group.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(group.icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              group.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final ProgressGroup group;
  final int count;

  const _GroupHeader({required this.group, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: group.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            group.label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          '$count tugas',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Refresh failed but older data is still shown.
class _InlineError extends StatelessWidget {
  final String? message;

  const _InlineError({this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.error, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message ?? 'Gagal memperbarui tugas.',
              style: TextStyle(color: scheme.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
