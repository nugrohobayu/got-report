import 'package:flutter/material.dart';
import 'package:got_report/core/theme/app_colors.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';

/// Label and color of a task status, same color rules as the web:
/// Belum abu, Berjalan biru, Selesai hijau, Terlambat merah.
extension TaskStatusView on TaskSummary {
  bool get isLate => overdue && !isDone;

  String get statusLabel {
    if (isLate) return 'Terlambat';
    return switch (status) {
      TaskStatus.ditugaskan => 'Belum mulai',
      TaskStatus.dikerjakan => 'Dikerjakan',
      TaskStatus.menungguTtd => 'Menunggu TTD',
      TaskStatus.perluRevisi => 'Perlu revisi',
      TaskStatus.selesai => 'Selesai',
      _ => status,
    };
  }

  Color get statusColor {
    if (isLate) return AppColors.statusTerlambat;
    return switch (status) {
      TaskStatus.dikerjakan ||
      TaskStatus.menungguTtd ||
      TaskStatus.perluRevisi =>
        AppColors.statusBerjalan,
      TaskStatus.selesai => AppColors.statusSelesai,
      _ => AppColors.statusBelum,
    };
  }
}

class TaskStatusChip extends StatelessWidget {
  final TaskSummary task;

  /// Light text on a solid color, for dark backgrounds.
  final bool solid;

  const TaskStatusChip({super.key, required this.task, this.solid = false});

  @override
  Widget build(BuildContext context) {
    final color = task.statusColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: solid ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        task.statusLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: solid ? Colors.white : color,
        ),
      ),
    );
  }
}
