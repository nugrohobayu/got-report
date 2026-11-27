import 'dart:typed_data';

import 'package:dio/dio.dart' show DioMediaType, MultipartFile;
import 'package:ada_tugas/core/constants/app_constants.dart';
import 'package:ada_tugas/core/error/guard.dart';
import 'package:ada_tugas/core/network/api_client.dart';
import 'package:ada_tugas/features/form_dinamis/data/models/task_form_model.dart';
import 'package:ada_tugas/features/form_dinamis/domain/entities/task_form.dart';
import 'package:ada_tugas/features/form_dinamis/domain/repositories/task_form_repository.dart';
import 'package:ada_tugas/features/tugas_hari_ini/data/models/task_summary_model.dart';
import 'package:ada_tugas/features/tugas_hari_ini/domain/entities/task_summary.dart';

/// Calls the `/api/v1/field/tasks/{id}/...` endpoints directly (thin enough
/// that a separate data source would only forward calls).
class TaskFormRepositoryImpl implements TaskFormRepository {
  final ApiClient apiClient;

  const TaskFormRepositoryImpl(this.apiClient);

  @override
  Future<TaskForm> getForm(String taskId) => guardFailures(() async {
        final data = await apiClient.get(ApiEndpoints.fieldTask(taskId));
        return TaskFormModel.formFromJson(data);
      });

  @override
  Future<Submission> getSubmission(String taskId) => guardFailures(() async {
        final data = await apiClient.get(ApiEndpoints.fieldSubmission(taskId));
        return TaskFormModel.submissionFromJson(data);
      });

  @override
  Future<StepSnapshot> saveAnswers(
    String taskId,
    String stepId,
    Map<String, dynamic> answers,
    GpsEvidence evidence,
  ) =>
      guardFailures(() async {
        final data = await apiClient.post(
          ApiEndpoints.fieldStepAnswers(taskId, stepId),
          body: {
            'answers': [
              for (final e in answers.entries)
                {'fieldId': e.key, 'value': e.value},
            ],
            ...evidence.toJson(),
          },
        );
        return TaskFormModel.stepFromJson(data);
      });

  @override
  Future<MediaInfo> uploadPhoto(
    String taskId, {
    required String stepId,
    required String fieldId,
    required Uint8List jpeg,
    required GpsEvidence evidence,
  }) =>
      guardFailures(() async {
        final data = await apiClient.postMultipart(
          ApiEndpoints.fieldMedia(taskId),
          {
            'stepId': stepId,
            'fieldId': fieldId,
            ...evidence.toFormFields(),
            // Explicit type: the server only accepts JPEG/PNG (415).
            'file': MultipartFile.fromBytes(
              jpeg,
              filename: '$fieldId.jpg',
              contentType: DioMediaType('image', 'jpeg'),
            ),
          },
        );
        return TaskFormModel.mediaFromJson(data);
      });

  @override
  Future<MediaInfo> getMedia(String taskId, String mediaId) =>
      guardFailures(() async {
        final data =
            await apiClient.get(ApiEndpoints.fieldMediaItem(taskId, mediaId));
        return TaskFormModel.mediaFromJson(data);
      });

  @override
  Future<TaskSummary> submit(String taskId) => guardFailures(() async {
        final data = await apiClient.post(ApiEndpoints.fieldSubmit(taskId));
        return TaskSummaryModel.fromJson(data);
      });

  @override
  Future<TaskSummary> sign(
    String taskId, {
    required String signerName,
    String? signerTitle,
    required Uint8List png,
    required GpsEvidence evidence,
  }) =>
      guardFailures(() async {
        final data = await apiClient.postMultipart(
          ApiEndpoints.fieldSignature(taskId),
          {
            'signerName': signerName,
            if (signerTitle != null && signerTitle.isNotEmpty)
              'signerTitle': signerTitle,
            ...evidence.toFormFields(),
            'file': MultipartFile.fromBytes(
              png,
              filename: 'ttd.png',
              contentType: DioMediaType('image', 'png'),
            ),
          },
        );
        return TaskSummaryModel.fromJson(data);
      });

  @override
  Future<Uint8List> fileBytes(String fileId) =>
      guardFailures(() => apiClient.getBytes(ApiEndpoints.file(fileId)));
}
