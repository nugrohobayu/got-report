import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/utils/date_formatter.dart';
import 'package:got_report/core/utils/load_status.dart';
import 'package:got_report/core/widgets/error_view.dart';
import 'package:got_report/features/kalender_tugas/presentation/pages/task_calendar_page.dart';
import 'package:got_report/features/profil/domain/repositories/profile_repository.dart';
import 'package:got_report/features/profil/presentation/bloc/profile_cubit.dart';
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

  /// Shared by the Beranda greeting and the Profil tab (one `/me` call).
  late final ProfileCubit _profile =
      ProfileCubit(context.read<ProfileRepository>())..load();

  @override
  void dispose() {
    _profile.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final title = _tabs[_navIndex].title;
    return BlocProvider.value(
      value: _profile,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (title != null) _TopBar(title: title),
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
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outline)),
            ),
            child: NavigationBar(
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
      // No header: the greeting is the top of the page.
      title: null,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      builder: () => _BerandaTab(
        onOpenCalendar: () => _select(1),
        onOpenProfile: () => _select(3),
      ),
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
      // No header: the profile card is the top of the page.
      title: null,
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      builder: () => const ProfilePage(),
    ),
  ];
}

class _Tab {
  final String label;

  /// Header title; `null` hides the header.
  final String? title;
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

/// Beranda: greeting, today's progress, the nearest task to do, a shortcut
/// to the task calendar, and the rest of today's tasks.
class _BerandaTab extends StatelessWidget {
  /// Switch to the Kalender / Profil tab.
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenProfile;

  const _BerandaTab({
    required this.onOpenCalendar,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TodayTasksCubit(context.read<TaskRepository>())..load(),
      child: _TodayContent(
        onOpenCalendar: onOpenCalendar,
        onOpenProfile: onOpenProfile,
      ),
    );
  }
}

class _TodayContent extends StatelessWidget {
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenProfile;

  const _TodayContent({
    required this.onOpenCalendar,
    required this.onOpenProfile,
  });

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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _Greeting(onTapAvatar: onOpenProfile),
              const SizedBox(height: 20),
              _TodayProgress(state: state),
              const SizedBox(height: 12),
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

/// "Selamat pagi" + the worker's name and today's date, with their initials
/// on the right (tap → Profil tab).
class _Greeting extends StatelessWidget {
  final VoidCallback onTapAvatar;

  const _Greeting({required this.onTapAvatar});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final profile = state.profile;
        final name = profile?.fullName.trim() ?? '';
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty
                        ? timeOfDayGreeting(now)
                        : '${timeOfDayGreeting(now)},',
                    style: TextStyle(
                      fontSize: 15,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (name.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.fullDate(now),
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            InkResponse(
              onTap: onTapAvatar,
              radius: 28,
              child: CircleAvatar(
                radius: 24,
                backgroundColor: scheme.primary,
                child: profile == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : Text(
                        profile.initials,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// `Selamat pagi / siang / sore / malam` from the device's local hour
/// (display only, never used as proof of time).
String timeOfDayGreeting(DateTime now) {
  final h = now.hour;
  if (h >= 4 && h < 11) return 'Selamat pagi';
  if (h >= 11 && h < 15) return 'Selamat siang';
  if (h >= 15 && h < 18) return 'Selamat sore';
  return 'Selamat malam';
}

/// Card with "x dari y tugas selesai" and a progress bar.
class _TodayProgress extends StatelessWidget {
  final TodayTasksState state;

  const _TodayProgress({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = state.tasks.length;
    final done = state.doneCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progres hari ini',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? 'Belum ada tugas hari ini'
                : '$done dari $total tugas selesai',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (total > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: done / total,
                minHeight: 8,
                color: scheme.primary,
                backgroundColor: scheme.outline,
              ),
            ),
          ],
        ],
      ),
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
