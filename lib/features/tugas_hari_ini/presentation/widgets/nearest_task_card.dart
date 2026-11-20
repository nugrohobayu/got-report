import 'package:flutter/material.dart';
import 'package:got_report/core/theme/app_colors.dart';
import 'package:got_report/core/utils/date_formatter.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:got_report/features/tugas_hari_ini/presentation/widgets/open_navigation.dart';
import 'package:got_report/features/tugas_hari_ini/presentation/widgets/task_action.dart';
import 'package:got_report/features/tugas_hari_ini/presentation/widgets/task_status_chip.dart';

/// Highlighted card for the next task to do, with the screen's main
/// (blue) button: the task's next action (Mulai / Lanjutkan tugas /
/// Tanda tangan klien), else Navigasi.
class NearestTaskCard extends StatelessWidget {
  final TaskSummary task;
  final VoidCallback? onTap;

  /// Called after working on the task from this card (reload the list).
  final VoidCallback? onChanged;

  const NearestTaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final due = task.dueAt;
    final location = task.location;
    final action = TaskAction.of(task);
    final radius = BorderRadius.circular(20);
    const muted = Color(0xFFC9D6E8);

    return Material(
      color: AppColors.navy,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18, color: muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      due == null
                          ? 'Tanpa tenggat'
                          : 'Tenggat ${DateFormatter.time(due)}'
                              '${DateUtils.isSameDay(due, DateTime.now()) ? '' : ', ${DateFormatter.shortDate(due)}'}',
                      style: const TextStyle(fontSize: 14, color: muted),
                    ),
                  ),
                  TaskStatusChip(task: task, solid: true),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (location != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.place_outlined, size: 18, color: muted),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (location.address?.isNotEmpty == true)
                            Text(
                              location.address!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontSize: 13, color: muted),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              if (action != null || location != null) ...[
                const SizedBox(height: 16),
                if (action != null)
                  // The next action is the main (blue) button; Navigasi
                  // becomes a white outlined button next to it.
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => runTaskAction(
                            context,
                            task,
                            action,
                            onChanged: onChanged,
                          ),
                          icon: Icon(action.icon),
                          label: Text(action.label),
                        ),
                      ),
                      if (location != null) ...[
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () => openNavigation(context, location),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            iconColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          icon: const Icon(Icons.directions),
                          label: const Text('Navigasi'),
                        ),
                      ],
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => openNavigation(context, location!),
                      icon: const Icon(Icons.directions),
                      label: const Text('Navigasi'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
