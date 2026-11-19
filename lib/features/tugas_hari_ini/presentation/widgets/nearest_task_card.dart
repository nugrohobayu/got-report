import 'package:flutter/material.dart';
import 'package:got_report/core/theme/app_colors.dart';
import 'package:got_report/core/utils/date_formatter.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:got_report/features/tugas_hari_ini/presentation/widgets/open_navigation.dart';
import 'package:got_report/features/tugas_hari_ini/presentation/widgets/task_status_chip.dart';

/// Highlighted card for the next task to do, with the screen's main
/// (blue) Navigasi button.
class NearestTaskCard extends StatelessWidget {
  final TaskSummary task;
  final VoidCallback? onTap;

  const NearestTaskCard({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    final due = task.dueAt;
    final location = task.location;
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => openNavigation(context, location),
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
