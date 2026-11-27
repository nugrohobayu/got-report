import 'package:flutter/material.dart';
import 'package:ada_tugas/core/theme/app_colors.dart';
import 'package:ada_tugas/core/utils/date_formatter.dart';
import 'package:ada_tugas/features/tugas_hari_ini/presentation/widgets/task_action.dart';
import 'package:ada_tugas/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:ada_tugas/features/tugas_hari_ini/presentation/widgets/open_navigation.dart';
import 'package:ada_tugas/features/tugas_hari_ini/presentation/widgets/task_status_chip.dart';

/// List item for a task: status icon, title, template, deadline, location,
/// revision note, and the next action (Mulai / Lanjutkan tugas / Tanda
/// tangan klien) next to Navigasi.
class TaskCard extends StatelessWidget {
  final TaskSummary task;
  final VoidCallback? onTap;

  /// Show the date next to the time (for lists spanning several days).
  final bool showDate;

  /// Called after working on the task from this card (reload the list).
  final VoidCallback? onChanged;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.showDate = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final location = task.location;
    final action = TaskAction.of(task);
    final showNavigation = location != null && !task.isDone;
    final note = task.lastRevisionNote;
    final showNote = task.status == TaskStatus.perluRevisi &&
        note != null &&
        note.trim().isNotEmpty;
    final radius = BorderRadius.circular(18);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: scheme.surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: scheme.outline.withValues(alpha: 0.7)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusBadge(task: task),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              color: scheme.onSurface,
                            ),
                          ),
                          if (task.templateName?.isNotEmpty == true) ...[
                            const SizedBox(height: 2),
                            Text(
                              task.templateName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TaskStatusChip(task: task),
                  ],
                ),
                const SizedBox(height: 12),
                _DuePill(task: task, showDate: showDate),
                if (location != null) ...[
                  const SizedBox(height: 10),
                  _LocationRow(location: location),
                ],
                if (showNote) ...[
                  const SizedBox(height: 10),
                  _RevisionNote(note: note),
                ],
                if (action != null || showNavigation) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (action != null)
                        Expanded(
                          // Tonal, not solid: the screen keeps one solid
                          // blue main button.
                          child: FilledButton.tonalIcon(
                            onPressed: () => runTaskAction(
                              context,
                              task,
                              action,
                              onChanged: onChanged,
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor: scheme.primaryContainer,
                              foregroundColor: scheme.onPrimaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            icon: Icon(action.icon, size: 20),
                            label: Text(action.label),
                          ),
                        )
                      else
                        const Spacer(),
                      if (showNavigation) ...[
                        const SizedBox(width: 10),
                        IconButton.outlined(
                          tooltip: 'Navigasi',
                          onPressed: () => openNavigation(context, location),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            foregroundColor: scheme.primary,
                            side: BorderSide(color: scheme.outline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.directions, size: 24),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded square tinted with the status color, with an icon per status.
class _StatusBadge extends StatelessWidget {
  final TaskSummary task;

  const _StatusBadge({required this.task});

  IconData get _icon {
    if (task.isDone) return Icons.task_alt;
    if (task.isCancelled) return Icons.block;
    if (task.isLate) return Icons.alarm;
    return switch (task.status) {
      TaskStatus.dikerjakan => Icons.engineering_outlined,
      TaskStatus.menungguTtd => Icons.draw_outlined,
      TaskStatus.perluRevisi => Icons.replay,
      _ => Icons.assignment_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = task.statusColor;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_icon, color: color, size: 24),
    );
  }
}

/// Deadline as a small pill; red when the task is late.
class _DuePill extends StatelessWidget {
  final TaskSummary task;
  final bool showDate;

  const _DuePill({required this.task, required this.showDate});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final due = task.dueAt;
    final late = task.isLate;
    final color = late ? AppColors.statusTerlambat : scheme.onSurfaceVariant;
    final text = due == null
        ? 'Tanpa tenggat'
        : showDate
            ? DateFormatter.dayTime(due)
            : 'Tenggat ${DateFormatter.time(due)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: late
            ? AppColors.statusTerlambat.withValues(alpha: 0.10)
            : scheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(late ? Icons.alarm : Icons.schedule, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Location name with the address below it.
class _LocationRow extends StatelessWidget {
  final TaskLocation location;

  const _LocationRow({required this.location});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final address = location.address;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.place_outlined, size: 18, color: AppColors.orange),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              if (address != null && address.isNotEmpty)
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The supervisor's note for a task sent back for revision.
class _RevisionNote extends StatelessWidget {
  final String note;

  const _RevisionNote({required this.note});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chat_outlined, size: 16, color: AppColors.orange),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Catatan revisi: $note',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
