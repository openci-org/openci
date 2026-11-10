import 'dart:convert';
import 'dart:io';

/// Language of the QR code's pull request comment.
enum PostQrCodeLang { en, ja }

/// Publishes workflow output on the pull request that triggered the run.
class PullRequestCI {
  const PullRequestCI();

  /// Requests a PR comment containing [url] and its QR code after success.
  ///
  /// Accepts absolute HTTP(S) URLs without user info, up to 2,331 UTF-8 bytes.
  /// Push and local runs skip publication.
  Future<void> postQrCode({
    required Uri url,
    PostQrCodeLang lang = PostQrCodeLang.en,
  }) async {
    final link = url.toString();
    if ((url.scheme != 'https' && url.scheme != 'http') ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        (url.hasPort && url.port > 65535) ||
        utf8.encode(link).length > 2331) {
      throw ArgumentError(
        'Expected an absolute HTTP(S) URL without user info that fits in a QR code.',
      );
    }
    final output = Platform.environment['OPENCI_PR_QR_OUTPUT'];
    if (output == null && Platform.environment.containsKey('OPENCI_RUN_ID')) {
      throw StateError('This executor does not support pull request QR codes.');
    }
    if (output == null || output.isEmpty) return;
    // Each call owns a file. A rename makes the complete record visible even
    // when multiple isolates or processes request QR codes at the same time.
    final request = await Directory(output).createTemp(
      'qr-${DateTime.now().microsecondsSinceEpoch}-',
    );
    final pending = File.fromUri(request.uri.resolve('pending'));
    await pending.writeAsString('${lang.name}\t$link\n');
    await pending.rename('${request.path}/url');
  }
}
