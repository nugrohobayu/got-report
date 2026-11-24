import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/config/env_config.dart';
import 'package:got_report/core/constants/app_constants.dart';
import 'package:got_report/core/network/api_client.dart';
import 'package:got_report/core/push/push_service.dart';
import 'package:got_report/features/login/presentation/widgets/logout_dialog.dart';

/// Hidden env form (Profil → tap the app version 3×). Saving checks the
/// new server first; on success the user is logged out from the current
/// server, the app switches to the new `BASE_URL` and shows login.
Future<void> showEnvConfigDialog(BuildContext context) async {
  final newUrl = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _EnvConfigDialog(),
  );
  if (newUrl == null || !context.mounted) return;

  final apiClient = context.read<ApiClient>();
  final push = context.read<PushService>();
  await logoutWithProgress(
    context,
    beforeSignedOut: () async {
      await EnvConfig.setBaseUrl(newUrl);
      apiClient.updateBaseUrl(EnvConfig.baseUrl);
      await push.reloadServerConfig();
    },
  );
}

class _EnvConfigDialog extends StatefulWidget {
  const _EnvConfigDialog();

  @override
  State<_EnvConfigDialog> createState() => _EnvConfigDialogState();
}

class _EnvConfigDialogState extends State<_EnvConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _baseUrl =
      TextEditingController(text: EnvConfig.baseUrl);
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _baseUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final url = EnvConfig.normalizeBaseUrl(_baseUrl.text);
    if (url == EnvConfig.normalizeBaseUrl(EnvConfig.baseUrl)) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
    });
    final error = await _checkServer(url);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _checking = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(url);
  }

  /// `GET /api/v1/public/config` (no login needed) on the new server;
  /// returns an error message or `null` when it answers.
  Future<String?> _checkServer(String url) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: url,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
      ),
    );
    try {
      await dio.get<dynamic>(ApiEndpoints.publicConfig);
      return null;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null) {
        return 'Server menjawab dengan kode $status. Periksa BASE_URL.';
      }
      return 'Tidak dapat terhubung ke server. Periksa BASE_URL dan '
          'koneksi internet.';
    } catch (_) {
      return 'Tidak dapat terhubung ke server.';
    } finally {
      dio.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_checking,
      child: AlertDialog(
        title: const Text('Pengaturan server'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _baseUrl,
                  enabled: !_checking,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'BASE_URL',
                    hintText: 'https://api.contoh.com',
                  ),
                  validator: EnvConfig.validateBaseUrl,
                ),
                const SizedBox(height: 8),
                Text(
                  'Default: ${EnvConfig.defaultBaseUrl}',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: _checking
                      ? null
                      : () => _baseUrl.text = EnvConfig.defaultBaseUrl,
                  child: const Text('Pakai default'),
                ),
                const SizedBox(height: 4),
                Text(
                  'Setelah disimpan, Anda akan keluar dan perlu masuk '
                  'kembali.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(fontSize: 13, color: scheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _checking ? null : () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: _checking ? null : _save,
            child: _checking
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
