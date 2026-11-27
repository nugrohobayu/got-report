import 'package:flutter/material.dart';
import 'package:ada_tugas/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens Google Maps (app if installed, otherwise browser) with directions
/// to the task location.
Future<void> openNavigation(BuildContext context, TaskLocation location) async {
  final messenger = ScaffoldMessenger.of(context);
  final Uri uri;
  if (location.hasCoordinates) {
    uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${location.latitude},${location.longitude}',
    });
  } else {
    uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': location.address ?? location.name,
    });
  }
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Tidak dapat membuka Google Maps.')),
    );
  }
}
