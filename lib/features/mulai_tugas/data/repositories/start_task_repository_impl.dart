import 'package:got_report/core/error/exceptions.dart';
import 'package:got_report/core/error/failures.dart';
import 'package:got_report/features/mulai_tugas/data/datasources/start_task_remote_data_source.dart';
import 'package:got_report/features/mulai_tugas/domain/entities/task_start.dart';
import 'package:got_report/features/mulai_tugas/domain/repositories/start_task_repository.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';

class StartTaskRepositoryImpl implements StartTaskRepository {
  final StartTaskRemoteDataSource remoteDataSource;

  const StartTaskRepositoryImpl(this.remoteDataSource);

  @override
  Future<TaskStartInfo> getStartInfo(String taskId) =>
      _guard(() => remoteDataSource.getStartInfo(taskId));

  @override
  Future<TaskSummary> start(String taskId, StartEvidence evidence) =>
      _guard(() => remoteDataSource.start(taskId, evidence));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ServerException catch (e) {
      throw ServerFailure(e.message, code: e.code, details: e.details);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ApiTimeoutException catch (e) {
      throw TimeoutFailure(e.message);
    } on ParsingException catch (e) {
      throw ParsingFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }
}
