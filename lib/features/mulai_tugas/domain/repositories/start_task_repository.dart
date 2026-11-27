import 'package:ada_tugas/features/mulai_tugas/domain/entities/task_start.dart';
import 'package:ada_tugas/features/tugas_hari_ini/domain/entities/task_summary.dart';

abstract class StartTaskRepository {
  /// Throws a `Failure` on error.
  Future<TaskStartInfo> getStartInfo(String taskId);

  /// Starts the task (status → `DIKERJAKAN`). Throws a `ServerFailure` with
  /// code `EVIDENCE_OUT_OF_RADIUS`, `EVIDENCE_QR_MISMATCH`,
  /// `EVIDENCE_MOCK_LOCATION`, `EVIDENCE_LOW_ACCURACY` or
  /// `TASK_INVALID_TRANSITION` when rejected.
  Future<TaskSummary> start(String taskId, StartEvidence evidence);
}
