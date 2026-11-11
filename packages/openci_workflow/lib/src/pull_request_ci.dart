import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import 'pull_request_release_metadata.dart';

/// Language of the QR code's pull request comment.
enum PostQrCodeLang { en, ja }

/// Display size of the QR code in the pull request comment, in pixels.
@immutable
final class PostQrCodeSize {
  /// Creates a custom display size in pixels (`1`–`1000` for each dimension).
  const PostQrCodeSize.custom({required this.width, required this.height});

  /// Small QR code (`120`x`120` pixels).
  static const PostQrCodeSize small = PostQrCodeSize.custom(
    width: 120,
    height: 120,
  );

  /// Medium QR code (`180`x`180` pixels).
  static const PostQrCodeSize medium = PostQrCodeSize.custom(
    width: 180,
    height: 180,
  );

  /// Large QR code (`240`x`240` pixels).
  static const PostQrCodeSize large = PostQrCodeSize.custom(
    width: 240,
    height: 240,
  );

  /// Display width in pixels.
  final int width;

  /// Display height in pixels.
  final int height;

  @override
  bool operator ==(Object other) =>
      other is PostQrCodeSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'PostQrCodeSize(width: $width, height: $height)';
}

/// Publishes workflow output on the pull request that triggered the run.
class PullRequestCI {
  const PullRequestCI();

  /// Requests a PR comment containing [url] and its QR code after success.
  ///
  /// Accepts absolute HTTP(S) URLs without user info, up to 2,331 UTF-8 bytes,
  /// and pixel dimensions between 1 and 1,000. Push and local runs skip
  /// publication.
  ///
  /// Firebase App Distribution uploads automatically provide the uploaded
  /// app's version and build number for their returned tester URL. Other
  /// URLs can supply [version] and [buildNumber] explicitly.
  Future<void> postQrCode({
    required Uri url,
    PostQrCodeLang lang = PostQrCodeLang.en,
    PostQrCodeSize size = PostQrCodeSize.medium,
    String? version,
    String? buildNumber,
  }) async {
    final suppliedMetadata = validatedReleaseMetadata(
      version: version,
      buildNumber: buildNumber,
    );
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
    if (size.width < 1 ||
        size.width > 1000 ||
        size.height < 1 ||
        size.height > 1000) {
      throw ArgumentError(
        'Expected QR code width and height between 1 and 1000 pixels.',
      );
    }
    final output = Platform.environment['OPENCI_PR_QR_OUTPUT'];
    if (output == null && Platform.environment.containsKey('OPENCI_RUN_ID')) {
      throw StateError('This executor does not support pull request QR codes.');
    }
    if (output == null || output.isEmpty) return;
    final metadata = {
      ...await readPullRequestRelease(url),
      ...suppliedMetadata,
    };
    // Each call owns a file. A rename makes the complete record visible even
    // when multiple isolates or processes request QR codes at the same time.
    final request = await Directory(output).createTemp(
      'qr-${DateTime.now().microsecondsSinceEpoch}-',
    );
    final pending = File.fromUri(request.uri.resolve('pending'));
    if (metadata.isNotEmpty) {
      await File.fromUri(request.uri.resolve('metadata.json')).writeAsString(
        jsonEncode(metadata),
      );
    }
    await pending.writeAsString(
      '${lang.name}\t${size.width}x${size.height}\t$link\n',
    );
    await pending.rename('${request.path}/url');
  }
}
