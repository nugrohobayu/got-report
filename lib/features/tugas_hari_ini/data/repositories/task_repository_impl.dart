import 'package:got_report/core/error/exceptions.dart';
import 'package:got_report/core/error/failures.dart';
import 'package:got_report/features/tugas_hari_ini/data/datasources/task_remote_data_source.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:got_report/features/tugas_hari_ini/domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;

  const TaskRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<TaskSummary>> getMyTasks({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final tasks = await remoteDataSource.getMyTasks(dueFrom: from, dueTo: to);
      return tasks..sort(compareByDue);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, code: e.code);
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
