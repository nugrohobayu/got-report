import 'package:flutter/material.dart';
import 'package:got_report/core/utils/date_formatter.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:got_report/features/tugas_hari_ini/presentation/widgets/open_navigation.dart';
import 'package:got_report/features/tugas_hari_ini/presentation/widgets/task_status_chip.dart';

/// List item for a task: deadline, title, location, status + Navigasi.
class TaskCard extends StatelessWidget {
  final TaskSummary task;
  final VoidCallback? onTap;

  /// Show the date next to the time (for lists spanning several days).
  final bool showDate;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final due = task.dueAt;
    final location = task.location;
    final radius = BorderRadius.circular(16);

    return Material(
      color: scheme.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: scheme.outline),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status color strip.
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: task.statusColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                due == null
                                    ? 'Tanpa tenggat'
                                    : showDate
                                        ? DateFormatter.dayTime(due)
                                        : 'Tenggat ${DateFormatter.time(due)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            TaskStatusChip(task: task),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (location != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            location.address?.isNotEmpty == true
                                ? '${location.name} · ${location.address}'
                                : location.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (location != null && !task.isDone)
                  Center(
                    child: IconButton(
                      tooltip: 'Navigasi',
                      iconSize: 28,
                      color: scheme.primary,
                      onPressed: () => openNavigation(context, location),
                      icon: const Icon(Icons.directions),
                    ),
                  ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
