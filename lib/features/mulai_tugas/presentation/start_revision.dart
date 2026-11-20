import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/tracking/ping_tracker.dart';
import 'package:got_report/core/error/failures.dart';
import 'package:got_report/core/location/location_service.dart';
import 'package:got_report/features/mulai_tugas/domain/entities/task_start.dart';
import 'package:got_report/features/mulai_tugas/domain/repositories/start_task_repository.dart';
import 'package:got_report/features/mulai_tugas/presentation/bloc/start_task_cubit.dart';
import 'package:got_report/features/mulai_tugas/presentation/pages/qr_scan_page.dart';
import 'package:got_report/features/mulai_tugas/presentation/pages/start_task_page.dart';

/// Opens the scanner and returns the scanned text, or `null` if closed.
typedef QrScanner = Future<String?> Function(BuildContext context);

Future<String?> _scanWithCamera(BuildContext context) =>
    Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScanPage()),
    );

/// "Mulai revisi" without the start screen: scans the location QR when the
/// template requires it (also for a revision), reads the GPS and calls
/// `POST /api/v1/field/tasks/{id}/start`, then [onStarted] opens the form.
///
/// Falls back to the full start screen when location permission or GPS
/// is not ready, since that screen explains how to fix it.
Future<void> startRevision(
  BuildContext context,
  String taskId, {
  required VoidCallback onStarted,
  QrScanner scanQr = _scanWithCamera,
}) async {
  final repository = context.read<StartTaskRepository>();
  final location = context.read<LocationService>();

  var access = await location.access();
  if (access == LocationAccess.needsPermission) {
    access = await location.requestAccess();
  }
  if (!context.mounted) return;
  if (access != LocationAccess.granted) {
    return openStartTask(context, taskId, onStarted: onStarted);
  }

  // requireQr is only in the task detail (null in the list).
  final info = await _withProgress(
    context,
    () => repository.getStartInfo(taskId),
  );
  if (!context.mounted || info == null) return;

  String? qrCode;
  if (info.requireQr) {
    qrCode = await scanQr(context);
    if (qrCode == null || !context.mounted) return; // scanner closed
  }

  final ok = await _withProgress(context, () async {
    final fix = await location.current();
    await repository.start(
      taskId,
      StartEvidence(
        latitude: fix.latitude,
        longitude: fix.longitude,
        accuracyM: fix.accuracyM,
        mock: fix.mock,
        deviceTime: DateTime.now().toUtc(),
        qrCode: qrCode,
      ),
    );
    return true;
  });
  if (ok == true && context.mounted) {
    PingTracker.maybeOf(context)?.refresh();
    onStarted();
  }
}

/// Runs [action] behind a "Memulai revisi..." dialog. On error shows the
/// reason and returns `null`.
Future<T?> _withProgress<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(width: 20),
            Expanded(child: Text('Memulai revisi...')),
          ],
        ),
      ),
    ),
  );

  T? result;
  String? error;
  try {
    result = await action();
  } on Failure catch (f) {
    error = startErrorMessage(f);
  } on LocationUnavailable catch (e) {
    error = e.message;
  }
  navigator.pop();

  if (error != null && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revisi belum bisa dimulai'),
        content: Text(error!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
  return result;
}
