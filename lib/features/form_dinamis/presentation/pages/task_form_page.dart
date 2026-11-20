import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:got_report/core/location/location_service.dart';
import 'package:got_report/core/theme/app_colors.dart';
import 'package:got_report/core/widgets/error_view.dart';
import 'package:got_report/features/form_dinamis/domain/entities/task_form.dart';
import 'package:got_report/features/form_dinamis/domain/repositories/task_form_repository.dart';
import 'package:got_report/features/form_dinamis/presentation/bloc/task_form_cubit.dart';
import 'package:got_report/features/form_dinamis/presentation/widgets/form_fields.dart';
import 'package:got_report/features/ttd/presentation/pages/signature_page.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';

/// Route name of [TaskFormPage]; path `/tasks/:id/form`.
const taskFormRouteName = 'taskForm';

/// Query of [taskFormRouteName] that opens the form at step 1.
const fromFirstStepQuery = {'langkah': 'awal'};

/// Opens the form of a started task (also the signature when the task is
/// waiting for it). [fromFirstStep] opens step 1 instead of the first
/// incomplete step (a revision redoes the work from the photos). Calls
/// [onChanged] when coming back, so the list can reload the task status.
Future<void> openTaskForm(
  BuildContext context,
  String taskId, {
  bool fromFirstStep = false,
  VoidCallback? onChanged,
}) async {
  await context.pushNamed<bool>(
    taskFormRouteName,
    pathParameters: {'id': taskId},
    queryParameters: fromFirstStep ? fromFirstStepQuery : const {},
  );
  onChanged?.call();
}

/// Dynamic form: "Langkah N dari M", fields rendered from the template
/// schema, Kembali / Lanjut (enabled when required fields are filled),
/// then Kirim hasil → client signature → done.
class TaskFormPage extends StatelessWidget {
  final String taskId;
  final bool fromFirstStep;

  const TaskFormPage({
    super.key,
    required this.taskId,
    this.fromFirstStep = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskFormCubit(
        repository: context.read<TaskFormRepository>(),
        locationService: context.read<LocationService>(),
        taskId: taskId,
      )..load(fromFirstStep: fromFirstStep),
      child: const _TaskFormView(),
    );
  }
}

class _TaskFormView extends StatefulWidget {
  const _TaskFormView();

  @override
  State<_TaskFormView> createState() => _TaskFormViewState();
}

class _TaskFormViewState extends State<_TaskFormView> {
  /// Feeds the signature page with the cubit's error.
  final _signatureError = ValueNotifier<String?>(null);
  bool _signatureOpen = false;

  @override
  void dispose() {
    _signatureError.dispose();
    super.dispose();
  }

  Future<void> _openSignature() async {
    if (_signatureOpen) return;
    _signatureOpen = true;
    final cubit = context.read<TaskFormCubit>();
    _signatureError.value = null;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SignaturePage(
          taskTitle: cubit.state.form?.task.title ?? '',
          error: _signatureError,
          onSubmit: (r) => cubit.sign(
            signerName: r.signerName,
            signerTitle: r.signerTitle,
            png: r.png,
          ),
        ),
      ),
    );
    _signatureOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskFormCubit, TaskFormState>(
      listener: (context, state) {
        _signatureError.value = state.error;
        if (state.status == TaskFormStatus.awaitingSignature &&
            (state.form?.isLeader ?? false)) {
          _openSignature();
        }
      },
      listenWhen: (a, b) => a.status != b.status || a.error != b.error,
      builder: (context, state) {
        final cubit = context.read<TaskFormCubit>();
        return PopScope(
          // Don't leave in the middle of an upload / save.
          canPop: !state.busy,
          child: Scaffold(
            appBar: AppBar(
              title: Text(state.form?.task.title ?? 'Form tugas'),
            ),
            body: switch (state.status) {
              TaskFormStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              TaskFormStatus.loadFailed => ErrorView(
                  message: state.error ?? 'Gagal memuat form.',
                  onRetry: cubit.load,
                ),
              TaskFormStatus.awaitingSignature => _StatusView(
                  icon: Icons.draw_outlined,
                  color: AppColors.statusBerjalan,
                  title: 'Menunggu tanda tangan klien',
                  message: state.form?.isLeader ?? false
                      ? 'Semua langkah sudah dikirim. Minta klien '
                          'menandatangani untuk menyelesaikan tugas.'
                      : 'Ketua tim akan meminta tanda tangan klien.',
                ),
              TaskFormStatus.finished => _StatusView(
                  icon: Icons.task_alt,
                  color: AppColors.statusSelesai,
                  title: 'Selesai',
                  message: state.doneMessage ?? 'Tugas selesai.',
                ),
              TaskFormStatus.ready => _StepView(state: state),
            },
            bottomNavigationBar: switch (state.status) {
              TaskFormStatus.ready => _StepButtons(state: state),
              TaskFormStatus.awaitingSignature
                  when state.form?.isLeader ?? false =>
                _BottomButton(
                  label: 'Mulai tanda tangan',
                  icon: Icons.draw,
                  onPressed: _openSignature,
                ),
              TaskFormStatus.finished => _BottomButton(
                  label: 'Kembali',
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              _ => null,
            },
          ),
        );
      },
    );
  }
}

class _StepView extends StatelessWidget {
  final TaskFormState state;

  const _StepView({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final step = state.step;
    final total = state.steps.length;
    if (step == null) {
      return const _StatusView(
        icon: Icons.help_outline,
        color: AppColors.statusBelum,
        title: 'Form kosong',
        message: 'Template tugas ini belum punya langkah.',
      );
    }
    // A revision is started again (status back to DIKERJAKAN), so show the
    // note while there is one and the task is not done.
    final note = state.form?.task.lastRevisionNote;
    final revision = state.taskStatus != TaskStatus.selesai &&
        note != null &&
        note.isNotEmpty;

    return ListView(
      key: PageStorageKey(step.id),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          'Langkah ${state.stepIndex + 1} dari $total',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (state.stepIndex + 1) / total,
            minHeight: 8,
            color: scheme.primary,
            backgroundColor: scheme.outline,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          step.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        if (revision) ...[
          const SizedBox(height: 12),
          _Banner(
            icon: Icons.assignment_return_outlined,
            color: AppColors.orange,
            text: 'Perlu revisi: $note',
          ),
        ],
        const SizedBox(height: 16),
        for (final f in step.fields) ...[
          FormFieldView(
            key: ValueKey(fieldKey(step.id, f.id)),
            step: step,
            field: f,
          ),
          const SizedBox(height: 12),
        ],
        if (state.error != null) ...[
          const SizedBox(height: 4),
          _Banner(
            icon: Icons.error_outline,
            color: scheme.error,
            text: state.error!,
          ),
        ],
      ],
    );
  }
}

class _StepButtons extends StatelessWidget {
  final TaskFormState state;

  const _StepButtons({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskFormCubit>();
    final isLeader = state.form?.isLeader ?? true;
    final last = state.isLastStep;
    // Leader's last step submits and goes on to the client's signature.
    final label = !last
        ? 'Lanjut'
        : !isLeader
            ? 'Simpan'
            : (state.form?.requireSignature ?? false)
                ? 'Mulai tanda tangan'
                : 'Kirim hasil';
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          if (state.stepIndex > 0) ...[
            OutlinedButton(
              onPressed: state.busy ? null : cubit.back,
              child: const Text('Kembali'),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: FilledButton(
              onPressed: state.canProceed ? cubit.next : null,
              child: state.saving
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(label),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _BottomButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _StatusView({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Banner({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
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
