import 'dart:io';

import 'package:avf_dart/avf_dart.dart';

void main() async {
  print('Fetching latest supported macOS IPSW URL from Apple...');
  try {
    final url = await AppleVirtualization.fetchLatestIpswUrl();
    final savePath =
        '${VirtualMachine.defaultVmsDir}/../downloads/${url.pathSegments.last}';

    print('Downloading IPSW to $savePath...');
    final metadataFile = File('$savePath.download');
    if (metadataFile.existsSync()) {
      print('Resuming download from previous state...');
    }

    await VirtualMachine.downloadIpsw(
      uri: url,
      savePath: savePath,
      concurrency: 8,
      onProgress: (progress) {
        stdout.write(
            '\rDownloading... ${progress.percent.toStringAsFixed(2)}% (${progress.speedStr}) [Elapsed: ${progress.elapsedStr}, ETA: ${progress.etaStr}]');
      },
    );
    print('\nSuccess: IPSW downloaded successfully to $savePath');
  } catch (e) {
    if (e is StateError &&
        e.message == 'The file is already fully downloaded.') {
      print('\n[Skip] IPSW is already fully downloaded.');
      return;
    }
    print('\nError downloading IPSW: $e');
  }
}
