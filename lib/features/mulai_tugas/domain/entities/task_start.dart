import 'package:equatable/equatable.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';

/// What the start screen needs from `GET /api/v1/field/tasks/{id}`.
class TaskStartInfo extends Equatable {
  final TaskSummary task;

  /// `template.requireQr`: scan the location QR before starting.
  final bool requireQr;

  const TaskStartInfo({required this.task, required this.requireQr});

  @override
  List<Object?> get props => [task, requireQr];
}

/// Body of `POST /api/v1/field/tasks/{id}/start`.
class StartEvidence extends Equatable {
  final double latitude;
  final double longitude;
  final double accuracyM;

  /// Android mock location; the server rejects `true`.
  final bool mock;

  /// Device clock, UTC. Informational only: proof times are server times.
  final DateTime deviceTime;

  /// Scanned location QR; only when the template requires it.
  final String? qrCode;

  const StartEvidence({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    required this.mock,
    required this.deviceTime,
    this.qrCode,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracyM': accuracyM,
        'mock': mock,
        'deviceTime': deviceTime.toUtc().toIso8601String(),
        if (qrCode != null) 'qrCode': qrCode,
      };

  @override
  List<Object?> get props =>
      [latitude, longitude, accuracyM, mock, deviceTime, qrCode];
}
