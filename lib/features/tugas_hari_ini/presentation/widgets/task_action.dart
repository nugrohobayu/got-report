import 'package:flutter/material.dart';
import 'package:ada_tugas/features/form_dinamis/presentation/pages/task_form_page.dart';
import 'package:ada_tugas/features/mulai_tugas/presentation/pages/start_task_page.dart';
import 'package:ada_tugas/features/mulai_tugas/presentation/start_revision.dart';
import 'package:ada_tugas/features/tugas_hari_ini/domain/entities/task_summary.dart';

/// The next thing the worker does with a task, shown as the card button.
enum TaskAction {
  start('Mulai tugas', Icons.play_arrow),

  /// PERLU_REVISI: started again with `POST .../start` (GPS + QR scan when
  /// the template requires it, no start screen), then the form from step 1.
  startRevision('Mulai revisi', Icons.replay),
  resume('Lanjutkan tugas', Icons.edit_note),
  sign('Tanda tangan klien', Icons.draw);

  final String label;
  final IconData icon;

  const TaskAction(this.label, this.icon);

  /// `null` when there is nothing to do (done, or a team member waiting
  /// for the leader).
  static TaskAction? of(TaskSummary task) => switch (task.status) {
        TaskStatus.ditugaskan => start,
        TaskStatus.perluRevisi => startRevision,
        TaskStatus.dikerjakan => resume,
        TaskStatus.menungguTtd
            when task.myRole == null || task.myRole == 'LEADER' =>
          sign,
        _ => null,
      };
}

/// Runs [action]: start (then the form), or open the form / signature.
/// [onChanged] reloads the list afterwards.
Future<void> runTaskAction(
  BuildContext context,
  TaskSummary task,
  TaskAction action, {
  VoidCallback? onChanged,
}) {
  switch (action) {
    case TaskAction.startRevision:
      // No start screen: QR scan (if required) and start, then straight
      // to the form at step 1 (photos).
      return startRevision(
        context,
        task.id,
        onStarted: () => openTaskForm(
          context,
          task.id,
          fromFirstStep: true,
          onChanged: onChanged,
        ),
      );
    case TaskAction.start:
      return openStartTask(
        context,
        task.id,
        // Started: go straight to the form.
        onStarted: () => openTaskForm(context, task.id, onChanged: onChanged),
      );
    case TaskAction.resume:
    case TaskAction.sign:
      return openTaskForm(context, task.id, onChanged: onChanged);
  }
}
