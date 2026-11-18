import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/auth/session_cubit.dart';
import 'package:got_report/features/login/domain/repositories/auth_repository.dart';

/// Asks for confirmation, then logs out: revokes the session on the server
/// (best effort), clears the stored tokens and flips [SessionCubit], which
/// makes the router redirect to `/login`.
Future<void> confirmAndLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Keluar dari aplikasi?'),
      content: const Text(
        'Anda perlu masuk kembali untuk melihat dan mengerjakan tugas.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Keluar'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final authRepository = context.read<AuthRepository>();
  final session = context.read<SessionCubit>();
  final navigator = Navigator.of(context, rootNavigator: true);

  // Blocking progress while the server call runs.
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
            Text('Sedang keluar...'),
          ],
        ),
      ),
    ),
  );

  // Never throws: network errors still clear the local session.
  await authRepository.logout();

  navigator.pop();
  session.setUnauthenticated();
}
