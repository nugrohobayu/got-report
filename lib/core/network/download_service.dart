import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'package:got_report/core/error/exceptions.dart';
import 'package:got_report/core/network/logging_interceptor.dart';

typedef DownloadProgressCallback = void Function(int received, int total);

/// Downloads files to local storage using [Dio], translating failures into
/// the same exception types the rest of the app's network layer uses.
class DownloadService {
  final Dio _dio;

  DownloadService({Dio? dio}) : _dio = dio ?? Dio() {
    if (dio == null) {
      _dio.interceptors.add(LoggingInterceptor());
    }
  }

  /// Downloads [url] into the platform's Downloads directory (falling back
  /// to the app's documents directory where Downloads isn't available),
  /// returning the resulting [File]. Pass [fileName] to control the saved
  /// name, otherwise it's inferred from the last path segment of [url].
  ///
  /// [onProgress] is called with `(received, total)` bytes as the download
  /// proceeds; `total` is `-1` when the server doesn't report content length.
  /// Pass [cancelToken] to allow cancelling an in-flight download.
  Future<File> download(
    String url, {
    String? fileName,
    DownloadProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final directory = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    await directory.create(recursive: true);
    final inferredName = fileName ?? _fileNameFromUrl(url);
    var savePath = '${directory.path}/$inferredName';

    try {
      final response = await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
      );

      // The URL's last path segment doesn't always carry a file extension
      // (e.g. a photo served from an ID-based path), which leaves image
      // viewers unable to recognize the saved file. Fall back to the
      // response's Content-Type in that case.
      if (fileName == null && !inferredName.contains('.')) {
        final extension = _extensionFromContentType(
          response.headers.value(Headers.contentTypeHeader),
        );
        if (extension != null) {
          final renamedPath = '$savePath.$extension';
          await File(savePath).rename(renamedPath);
          savePath = renamedPath;
        }
      }

      return File(savePath);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;

      if (e.type == DioExceptionType.connectionError ||
          e.error is SocketException) {
        throw const NetworkException();
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const ApiTimeoutException();
      }
      if (e.type == DioExceptionType.badResponse) {
        throw ServerException(
          message: 'Download failed with status code '
              '${e.response?.statusCode}',
          statusCode: e.response?.statusCode,
        );
      }
      throw NetworkException(e.message ?? 'Download failed');
    }
  }

  /// Cancels a download started with the given [cancelToken].
  void cancel(CancelToken cancelToken, [String? reason]) =>
      cancelToken.cancel(reason);

  String _fileNameFromUrl(String url) {
    final segments = Uri.parse(url).pathSegments;
    if (segments.isNotEmpty && segments.last.isNotEmpty) return segments.last;
    return 'download_${url.hashCode}';
  }

  static const _mimeToExtension = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
    'image/gif': 'gif',
    'image/bmp': 'bmp',
    'application/pdf': 'pdf',
    'application/zip': 'zip',
    'text/plain': 'txt',
  };

  String? _extensionFromContentType(String? contentType) {
    if (contentType == null) return null;
    final mimeType = contentType.split(';').first.trim().toLowerCase();
    return _mimeToExtension[mimeType];
  }

  void dispose() => _dio.close();
}
