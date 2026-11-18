import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/network/download_service.dart';
import 'package:got_report/core/widgets/app_button.dart';
import 'package:got_report/core/widgets/app_text_form_field.dart';

enum _DownloadStatus { idle, downloading, success, error, cancelled }

class DownloadTestPage extends StatefulWidget {
  const DownloadTestPage({super.key});

  @override
  State<DownloadTestPage> createState() => _DownloadTestPageState();
}

class _DownloadTestPageState extends State<DownloadTestPage> {
  static const _defaultUrl = 'https://picsum.photos/1200/900.jpg';

  final _urlController = TextEditingController(text: _defaultUrl);

  _DownloadStatus _status = _DownloadStatus.idle;
  int _received = 0;
  int _total = -1;
  String? _resultPath;
  String? _errorMessage;
  CancelToken? _cancelToken;

  bool get _isDownloading => _status == _DownloadStatus.downloading;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _status = _DownloadStatus.downloading;
      _received = 0;
      _total = -1;
      _resultPath = null;
      _errorMessage = null;
    });

    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    try {
      final file = await context.read<DownloadService>().download(
        url,
        cancelToken: cancelToken,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _received = received;
            _total = total;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _status = _DownloadStatus.success;
        _resultPath = file.path;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.type == DioExceptionType.cancel) {
        setState(() => _status = _DownloadStatus.cancelled);
      } else {
        setState(() {
          _status = _DownloadStatus.error;
          _errorMessage = e.message ?? 'Download failed';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _DownloadStatus.error;
        _errorMessage = e.toString();
      });
    } finally {
      _cancelToken = null;
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel('Cancelled by user');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextFormField(
              controller: _urlController,
              label: 'File URL',
              enabled: !_isDownloading,
              prefixIcon: Icons.link,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Download',
                    icon: Icons.download_outlined,
                    loading: _isDownloading,
                    onPressed: _isDownloading ? null : _startDownload,
                  ),
                ),
                if (_isDownloading) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.outlined,
                      onPressed: _cancelDownload,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            _buildStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus() {
    switch (_status) {
      case _DownloadStatus.idle:
        return const SizedBox.shrink();
      case _DownloadStatus.downloading:
        final progress = _total > 0 ? _received / _total : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              progress != null
                  ? '${(progress * 100).toStringAsFixed(0)}% '
                      '(${_formatBytes(_received)} / ${_formatBytes(_total)})'
                  : _formatBytes(_received),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case _DownloadStatus.success:
        return Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 48,
            ),
            const SizedBox(height: 8),
            const Text('Download complete'),
            const SizedBox(height: 4),
            Text(
              _resultPath ?? '',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (_resultPath != null) _buildImagePreview(_resultPath!),
          ],
        );
      case _DownloadStatus.cancelled:
        return const Center(child: Text('Download cancelled'));
      case _DownloadStatus.error:
        return Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
            ),
          ],
        );
    }
  }

  Widget _buildImagePreview(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(path),
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 0) return 'unknown';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
