import 'dart:convert';
import 'dart:io';

/// Represents a macOS IPSW restore image.
///
/// Use [MacOSRestoreImage.fetchLatest] to download the latest supported
/// macOS restore image from Apple's CDN.
class MacOSRestoreImage {
  /// Local file path of the IPSW.
  final String path;

  MacOSRestoreImage({required this.path});

  /// Whether the IPSW file exists on disk.
  bool get exists => File(path).existsSync();

  /// File size in bytes.
  int get sizeBytes => File(path).lengthSync();

  /// Fetches the latest macOS IPSW URL from Apple's CDN and downloads it.
  ///
  /// If [destPath] already exists, the download is skipped.
  /// Progress is reported via [onProgress] as a value between 0.0 and 1.0.
  static Future<MacOSRestoreImage> fetchLatest({
    required String destPath,
    void Function(double progress)? onProgress,
  }) async {
    if (File(destPath).existsSync()) {
      return MacOSRestoreImage(path: destPath);
    }

    final url = await _getLatestIPSWUrl();
    await _downloadFile(url, destPath, onProgress: onProgress);
    return MacOSRestoreImage(path: destPath);
  }

  static Future<String> _getLatestIPSWUrl() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse('https://ipsw.me/api/v1/latest/macos'),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as List;
      if (json.isEmpty) {
        throw Exception('No macOS IPSW found from Apple CDN');
      }
      return json[0]['url'] as String;
    } finally {
      client.close();
    }
  }

  static Future<void> _downloadFile(
    String url,
    String destPath, {
    void Function(double progress)? onProgress,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final totalBytes = response.contentLength;
      var receivedBytes = 0;

      final file = File(destPath);
      final sink = file.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          onProgress(receivedBytes / totalBytes);
        }
      }

      await sink.close();
    } finally {
      client.close();
    }
  }
}
