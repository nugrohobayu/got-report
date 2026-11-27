import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ada_tugas/core/location/location_service.dart';

bool _askedThisRun = false;

@visibleForTesting
void resetLocationPrompt() => _askedThisRun = false;

/// Asks for location permission when the app opens (Beranda), once per app
/// run, with the reason in Indonesian before the OS prompt. Location is
/// only read while starting / working on a task, never in the background.
Future<void> askLocationPermissionOnStart(BuildContext context) async {
  if (_askedThisRun) return;
  _askedThisRun = true;

  final service = context.read<LocationService>();
  final LocationAccess access;
  try {
    access = await service.access();
  } catch (_) {
    return; // No GPS support (e.g. desktop): nothing to ask.
  }
  if (!context.mounted) return;

  switch (access) {
    case LocationAccess.needsPermission:
      final allow = await _explain(
        context,
        title: 'Izinkan akses lokasi',
        message: 'Lokasi dipakai sebagai bukti hadir selama tugas berjalan, '
            'saat memulai tugas, mengisi form, dan mengambil foto. Lokasi '
            'tidak dikirim di luar tugas.',
        action: 'Izinkan',
      );
      if (allow) await service.requestAccess();
    case LocationAccess.deniedForever:
      final open = await _explain(
        context,
        title: 'Izin lokasi ditolak',
        message: 'Tugas tidak bisa dimulai tanpa lokasi. Aktifkan izin '
            'lokasi untuk aplikasi ini di pengaturan HP.',
        action: 'Buka pengaturan',
      );
      if (open) await service.openSettings(access);
    case LocationAccess.granted:
    case LocationAccess.serviceOff:
      // GPS off is handled on the Mulai tugas screen.
      return;
  }
}

Future<bool> _explain(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        Icons.location_on_outlined,
        size: 36,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Nanti'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}
