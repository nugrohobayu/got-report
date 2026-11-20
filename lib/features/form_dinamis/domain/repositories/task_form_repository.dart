import 'dart:typed_data';

import 'package:got_report/features/form_dinamis/domain/entities/task_form.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';

/// Everything a worker does after starting a task. All methods throw a
/// `Failure` on error (`ServerFailure` keeps the backend code and details).
abstract class TaskFormRepository {
  Future<TaskForm> getForm(String taskId);

  /// Current answers, photos and step progress.
  Future<Submission> getSubmission(String taskId);

  /// Saves the answer fields of one step (partial is fine); returns the
  /// step as stored, with `complete`.
  Future<StepSnapshot> saveAnswers(
    String taskId,
    String stepId,
    Map<String, dynamic> answers,
    GpsEvidence evidence,
  );

  /// Uploads a camera photo (JPEG); the server adds the watermark.
  Future<MediaInfo> uploadPhoto(
    String taskId, {
    required String stepId,
    required String fieldId,
    required Uint8List jpeg,
    required GpsEvidence evidence,
  });

  Future<MediaInfo> getMedia(String taskId, String mediaId);

  /// Leader only. Status → `MENUNGGU_TTD`, or `SELESAI` without signature.
  Future<TaskSummary> submit(String taskId);

  /// Leader only, status `MENUNGGU_TTD`. Status → `SELESAI`.
  Future<TaskSummary> sign(
    String taskId, {
    required String signerName,
    String? signerTitle,
    required Uint8List png,
    required GpsEvidence evidence,
  });

  /// Bytes of a stored file (watermarked photo).
  Future<Uint8List> fileBytes(String fileId);
}
