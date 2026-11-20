import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/utils/date_formatter.dart';
import 'package:got_report/core/utils/load_status.dart';
import 'package:got_report/core/widgets/error_view.dart';
import 'package:got_report/features/kalender_tugas/presentation/pages/task_calendar_page.dart';
import 'package:got_report/features/profil/presentation/pages/profile_page.dart';
import 'package:got_report/features/riwayat_penugasan/presentation/pages/task_history_page.dart';
import 'package:got_report/features/tugas_hari_ini/domain/repositories/task_repository.dart';
import 'package:got_report/features/tugas_hari_ini/presentation/bloc/today_tasks_cubit.dart';
import 'package:got_report/features/tugas_hari_ini/presentation/widgets/nearest_task_card.dart';
import 'package:got_report/features/tugas_hari_ini/presentation/widgets/task_card.dart';

/// Main shell after login, with a bottom navbar of four tabs: Beranda
/// (today's tasks), Kalender (Kalender Kerja), Riwayat (assignment history)
/// and Profil.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;

  /// Tabs are built (and load their data) only once first opened, then
  /// kept alive by the [IndexedStack].
  final Set<int> _opened = {0};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _TopBar(title: _tabs[_navIndex].title),
              Expanded(
                child: IndexedStack(
                  index: _navIndex,
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      _opened.contains(i)
                          ? _tabs[i].builder()
                          : const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _navIndex,
          onDestinationSelected: _select,
          destinations: [
            for (final tab in _tabs)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }

  void _select(int index) => setState(() {
        _navIndex = index;
        _opened.add(index);
      });

  late final List<_Tab> _tabs = [
    _Tab(
      label: 'Beranda',
      title: 'Beranda',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      builder: () => _BerandaTab(onOpenCalendar: () => _select(1)),
    ),
    _Tab(
      label: 'Kalender',
      title: 'Kalender Kerja',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      builder: () => const TaskCalendarPage(),
    ),
    _Tab(
      label: 'Riwayat',
      title: 'Riwayat Penugasan',
      icon: Icons.history,
      selectedIcon: Icons.history,
      builder: () => const TaskHistoryPage(),
    ),
    _Tab(
      label: 'Profil',
      title: 'Profil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      builder: () => const ProfilePage(),
    ),
  ];
}

class _Tab {
  final String label;
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function() builder;

  const _Tab({
    required this.label,
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });
}

class _TopBar extends StatelessWidget {
  final String title;

  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

/// Beranda: today's progress, the nearest task to do, a shortcut to the
/// task calendar, and the rest of today's tasks.
class _BerandaTab extends StatelessWidget {
  /// Switches to the Kalender tab.
  final VoidCallback onOpenCalendar;

  const _BerandaTab({required this.onOpenCalendar});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TodayTasksCubit(context.read<TaskRepository>())..load(),
      child: _TodayContent(onOpenCalendar: onOpenCalendar),
    );
  }
}

class _TodayContent extends StatelessWidget {
  final VoidCallback onOpenCalendar;

  const _TodayContent({required this.onOpenCalendar});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodayTasksCubit, TodayTasksState>(
      builder: (context, state) {
        final cubit = context.read<TodayTasksCubit>();
        final nearest = state.nearest;
        final others = state.tasks.where((t) => t != nearest).toList();
        final firstLoad = state.status == LoadStatus.initial ||
            (state.status == LoadStatus.loading && state.tasks.isEmpty);

        return RefreshIndicator(
          onRefresh: cubit.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _Greeting(state: state),
              const SizedBox(height: 16),
              _CalendarMenu(onTap: onOpenCalendar),
              const SizedBox(height: 24),
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
                const _SectionTitle('Tugas terdekat'),
                const SizedBox(height: 10),
                if (nearest != null)
                  NearestTaskCard(task: nearest)
                else
                  _EmptyNearest(hasTasks: state.tasks.isNotEmpty),
                const SizedBox(height: 24),
                _SectionTitle(
                  'Tugas hari ini',
                  trailing: '${state.tasks.length} tugas',
                ),
                const SizedBox(height: 10),
                if (others.isEmpty)
                  Text(
                    state.tasks.isEmpty
                        ? 'Tidak ada tugas dengan tenggat hari ini.'
                        : 'Tidak ada tugas lain hari ini.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  for (final t in others) ...[
                    TaskCard(task: t),
                    const SizedBox(height: 10),
                  ],
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Today's date and "x dari y tugas selesai" progress.
class _Greeting extends StatelessWidget {
  final TodayTasksState state;

  const _Greeting({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = state.tasks.length;
    final done = state.doneCount;
    final progress = total == 0 ? 0.0 : done / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormatter.fullDate(DateTime.now()),
          style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          total == 0
              ? 'Belum ada tugas hari ini'
              : '$done dari $total tugas selesai',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        if (total > 0) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
      ],
    );
  }
}

/// Menu tile that opens the task calendar.
class _CalendarMenu extends StatelessWidget {
  final VoidCallback onTap;

  const _CalendarMenu({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(16);
    return Material(
      color: scheme.primaryContainer,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_month, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kalender tugas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lihat jadwal tugas per tanggal',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onPrimaryContainer.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _EmptyNearest extends StatelessWidget {
  final bool hasTasks;

  const _EmptyNearest({required this.hasTasks});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Icon(
            hasTasks ? Icons.task_alt : Icons.event_available_outlined,
            size: 32,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasTasks
                  ? 'Semua tugas hari ini sudah selesai.'
                  : 'Tidak ada tugas yang perlu dikerjakan hari ini.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
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
