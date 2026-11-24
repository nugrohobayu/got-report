import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:got_report/core/tracking/ping_tracker.dart';
import 'package:got_report/core/location/location_service.dart';
import 'package:got_report/core/theme/app_colors.dart';
import 'package:got_report/core/utils/date_formatter.dart';
import 'package:got_report/core/widgets/error_view.dart';
import 'package:got_report/features/mulai_tugas/domain/repositories/start_task_repository.dart';
import 'package:got_report/features/mulai_tugas/presentation/bloc/start_task_cubit.dart';
import 'package:got_report/features/mulai_tugas/presentation/pages/qr_scan_page.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';

/// Route name of [StartTaskPage]; path `/tasks/:id/start`.
const startTaskRouteName = 'startTask';

/// Opens "Mulai tugas" for [taskId]. When the task was started, shows a
/// confirmation and calls [onStarted] (e.g. open the form).
Future<void> openStartTask(
  BuildContext context,
  String taskId, {
  VoidCallback? onStarted,
}) async {
  final started = await context.pushNamed<bool>(
    startTaskRouteName,
    pathParameters: {'id': taskId},
  );
  if (started != true || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Tugas dimulai. Selamat bekerja!')),
  );
  onStarted?.call();
}

/// "Mulai tugas": shows the task, the GPS fix and its distance to the
/// location, then starts the task (scanning the location QR first when the
/// template requires it). Pops with `true` once started.
class StartTaskPage extends StatelessWidget {
  final String taskId;

  const StartTaskPage({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StartTaskCubit(
        repository: context.read<StartTaskRepository>(),
        locationService: context.read<LocationService>(),
        taskId: taskId,
      )..load(),
      child: const _StartTaskView(),
    );
  }
}

class _StartTaskView extends StatefulWidget {
  const _StartTaskView();

  @override
  State<_StartTaskView> createState() => _StartTaskViewState();
}

class _StartTaskViewState extends State<_StartTaskView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the phone settings: permission / GPS may be on now.
    if (state == AppLifecycleState.resumed) {
      final cubit = context.read<StartTaskCubit>();
      // While the task is still loading, load() checks access itself.
      if (cubit.state.info != null &&
          cubit.state.access != LocationAccess.granted) {
        cubit.checkAccess(locateIfGranted: true);
      }
    }
  }

  Future<void> _start() async {
    final cubit = context.read<StartTaskCubit>();
    String? qr;
    if (cubit.state.needsQr) {
      qr = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const QrScanPage()),
      );
      if (qr == null) return; // Scanner closed.
    }
    await cubit.start(qrCode: qr);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StartTaskCubit, StartTaskState>(
      listenWhen: (a, b) => b.status == StartTaskStatus.started,
      listener: (context, state) {
        PingTracker.maybeOf(context)?.refresh();
        Navigator.of(context).pop(true);
      },
      builder: (context, state) {
        final cubit = context.read<StartTaskCubit>();
        final info = state.info;
        final revision = info?.task.status == TaskStatus.perluRevisi;
        final note = info?.task.lastRevisionNote;
        final what = revision ? 'revisi' : 'tugas';
        return Scaffold(
          appBar:
              AppBar(title: Text(revision ? 'Mulai revisi' : 'Mulai tugas')),
          body: switch (state.status) {
            StartTaskStatus.loadFailed => ErrorView(
                message: state.error ?? 'Gagal memuat tugas.',
                onRetry: cubit.load,
              ),
            // Still loading the task. Also covers a GPS read that started
            // before the detail arrived (e.g. app resumed from a
            // notification tap): status is then locating/ready, not loading.
            _ when info == null =>
              const Center(child: CircularProgressIndicator()),
            _ => ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  _TaskHeader(task: info.task),
                  if (revision && note != null && note.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _Notice(
                      icon: Icons.assignment_return_outlined,
                      text: 'Perlu revisi: $note',
                    ),
                  ],
                  const SizedBox(height: 20),
                  _StepTitle(
                    number: 1,
                    title: 'Lokasi GPS',
                    subtitle: 'Harus berada dalam radius lokasi tugas.',
                  ),
                  const SizedBox(height: 8),
                  const _GpsCard(),
                  if (state.needsQr) ...[
                    const SizedBox(height: 20),
                    _StepTitle(
                      number: 2,
                      title: 'Scan QR lokasi',
                      subtitle: 'Kamera terbuka saat Anda menekan Mulai '
                          '$what. Pindai QR yang tertempel di lokasi.',
                    ),
                  ],
                  if (!state.isStartable) ...[
                    const SizedBox(height: 20),
                    const _Notice(
                      icon: Icons.info_outline,
                      text: 'Tugas ini sudah dimulai atau selesai.',
                    ),
                  ],
                  if (state.error != null) ...[
                    const SizedBox(height: 20),
                    _Notice(
                      icon: Icons.error_outline,
                      text: state.error!,
                      isError: true,
                    ),
                  ],
                ],
              ),
          },
          bottomNavigationBar: info == null
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                    ),
                    onPressed: state.canStart ? _start : null,
                    icon: state.status == StartTaskStatus.submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            state.needsQr
                                ? Icons.qr_code_scanner
                                : Icons.play_arrow,
                          ),
                    label: Text(
                      state.status == StartTaskStatus.submitting
                          ? 'Memulai...'
                          : state.needsQr
                              ? 'Scan QR & mulai $what'
                              : 'Mulai $what',
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _TaskHeader extends StatelessWidget {
  final TaskSummary task;

  const _TaskHeader({required this.task});

  @override
  Widget build(BuildContext context) {
    const muted = Color(0xFFC9D6E8);
    final location = task.location;
    final due = task.dueAt;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (location != null) ...[
            const SizedBox(height: 8),
            _HeaderLine(
              icon: Icons.place_outlined,
              text: location.address?.isNotEmpty == true
                  ? '${location.name} · ${location.address}'
                  : location.name,
              color: muted,
            ),
          ],
          if (due != null) ...[
            const SizedBox(height: 4),
            _HeaderLine(
              icon: Icons.schedule,
              text: 'Tenggat ${DateFormatter.dayTime(due)}',
              color: muted,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _HeaderLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: color)),
        ),
      ],
    );
  }
}

class _StepTitle extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;

  const _StepTitle({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: scheme.primary,
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// GPS status: permission / GPS off, reading, or the fix with its
/// accuracy and distance to the location.
class _GpsCard extends StatelessWidget {
  const _GpsCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<StartTaskCubit>();
    final state = context.watch<StartTaskCubit>().state;
    final access = state.access;
    final fix = state.location;
    final radius = state.info?.task.location?.radiusM;
    final distance = cubit.distanceToLocationM;

    final Widget content;
    if (access == null) {
      content = const _CardRow(
        icon: Icons.my_location,
        text: 'Memeriksa izin lokasi...',
      );
    } else if (access == LocationAccess.needsPermission) {
      content = _CardAction(
        icon: Icons.location_on_outlined,
        text: 'Lokasi dipakai sebagai bukti hadir selama tugas berjalan.',
        action: 'Izinkan lokasi',
        onPressed: cubit.requestAccess,
      );
    } else if (access == LocationAccess.deniedForever) {
      content = _CardAction(
        icon: Icons.location_off_outlined,
        text: 'Izin lokasi ditolak. Aktifkan di pengaturan aplikasi.',
        action: 'Buka pengaturan',
        onPressed: cubit.openSettings,
        isError: true,
      );
    } else if (access == LocationAccess.serviceOff) {
      content = _CardAction(
        icon: Icons.location_disabled,
        text: 'GPS di HP sedang mati.',
        action: 'Nyalakan GPS',
        onPressed: cubit.openSettings,
        isError: true,
      );
    } else if (state.status == StartTaskStatus.locating && fix == null) {
      content = const _CardRow(
        icon: Icons.my_location,
        text: 'Mencari lokasi Anda...',
        loading: true,
      );
    } else if (fix == null) {
      content = _CardAction(
        icon: Icons.location_searching,
        text: 'Lokasi belum didapat.',
        action: 'Coba lagi',
        onPressed: cubit.locate,
      );
    } else if (fix.mock) {
      content = _CardAction(
        icon: Icons.gpp_bad_outlined,
        text: 'Lokasi palsu (fake GPS) terdeteksi. Tugas tidak bisa '
            'dimulai.',
        action: state.status == StartTaskStatus.locating
            ? 'Memeriksa...'
            : 'Periksa lagi',
        onPressed: state.busy ? null : cubit.locate,
        isError: true,
      );
    } else {
      final inside =
          distance != null && radius != null ? distance <= radius : null;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardRow(
            icon: inside == false ? Icons.wrong_location : Icons.where_to_vote,
            iconColor: inside == null
                ? null
                : inside
                    ? AppColors.statusSelesai
                    : scheme.error,
            text: distance == null
                ? 'Lokasi didapat'
                : '±${distance.round()} m dari lokasi'
                    '${radius == null ? '' : ' (radius $radius m)'}',
            caption: 'Akurasi GPS ±${fix.accuracyM.round()} m',
            loading: state.status == StartTaskStatus.locating,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: state.busy ? null : cubit.locate,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Perbarui lokasi'),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: content,
    );
  }
}

class _CardRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String text;
  final String? caption;
  final bool loading;

  const _CardRow({
    required this.icon,
    required this.text,
    this.iconColor,
    this.caption,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? scheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (caption != null)
                  Text(
                    caption!,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (loading)
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  final IconData icon;
  final String text;
  final String action;
  final VoidCallback? onPressed;
  final bool isError;

  const _CardAction({
    required this.icon,
    required this.text,
    required this.action,
    required this.onPressed,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardRow(
          icon: icon,
          iconColor: isError ? scheme.error : null,
          text: text,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: onPressed, child: Text(action)),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isError;

  const _Notice({
    required this.icon,
    required this.text,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isError ? scheme.error : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
