import 'package:got_report/core/constants/app_constants.dart';
import 'package:got_report/core/network/api_client.dart';
import 'package:got_report/features/tugas_hari_ini/data/models/task_summary_model.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';

abstract class TaskRemoteDataSource {
  /// `GET /api/v1/field/tasks?dueFrom=&dueTo=`, sorted by `dueAt`.
  /// Every status is returned, including cancelled tasks.
  Future<List<TaskSummary>> getMyTasks({
    required DateTime dueFrom,
    required DateTime dueTo,
  });
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final ApiClient apiClient;

  const TaskRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<TaskSummary>> getMyTasks({
    required DateTime dueFrom,
    required DateTime dueTo,
  }) async {
    // No `status` param: the backend returns every status (confirmed by BE),
    // so the app filters.
    final data = await apiClient.get(
      ApiEndpoints.fieldTasks,
      queryParameters: {
        'dueFrom': dueFrom.toUtc().toIso8601String(),
        'dueTo': dueTo.toUtc().toIso8601String(),
      },
    );
    return TaskSummaryModel.listFromJson(data);
  }
}
