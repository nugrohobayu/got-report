import 'package:ada_tugas/core/constants/app_constants.dart';
import 'package:ada_tugas/core/error/exceptions.dart';
import 'package:ada_tugas/core/network/api_client.dart';
import 'package:ada_tugas/features/mulai_tugas/domain/entities/task_start.dart';
import 'package:ada_tugas/features/tugas_hari_ini/data/models/task_summary_model.dart';
import 'package:ada_tugas/features/tugas_hari_ini/domain/entities/task_summary.dart';

abstract class StartTaskRemoteDataSource {
  /// `GET /api/v1/field/tasks/{id}`.
  Future<TaskStartInfo> getStartInfo(String taskId);

  /// `POST /api/v1/field/tasks/{id}/start`; returns the task, now
  /// `DIKERJAKAN`.
  Future<TaskSummary> start(String taskId, StartEvidence evidence);
}

class StartTaskRemoteDataSourceImpl implements StartTaskRemoteDataSource {
  final ApiClient apiClient;

  const StartTaskRemoteDataSourceImpl(this.apiClient);

  @override
  Future<TaskStartInfo> getStartInfo(String taskId) async {
    final data = await apiClient.get(ApiEndpoints.fieldTask(taskId));
    return startInfoFromJson(data);
  }

  @override
  Future<TaskSummary> start(String taskId, StartEvidence evidence) async {
    final data = await apiClient.post(
      ApiEndpoints.fieldTaskStart(taskId),
      body: evidence.toJson(),
    );
    return TaskSummaryModel.fromJson(data);
  }
}

/// Parses the task detail; the list item fields are shared with
/// [TaskSummaryModel].
TaskStartInfo startInfoFromJson(dynamic json) {
  if (json is! Map) throw const ParsingException();
  final template = json['template'];
  return TaskStartInfo(
    task: TaskSummaryModel.fromJson(json),
    requireQr: template is Map && template['requireQr'] == true,
  );
}
