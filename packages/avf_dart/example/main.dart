import 'dart:io';
import 'package:avf_dart/avf_dart.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage:');
    print('  dart run example/main.dart boot [<vm-name>]');
    print('  dart run example/main.dart fetch-ipsw');
    print('  dart run example/main.dart download [<save-path>]');
    print('  dart run example/main.dart install <ipsw-path> [<vm-name>]');
    print('\nDefaulting to booting "tahoe-base" if available...');
    await _boot('tahoe-base');
    return;
  }

  final command = args[0];
  switch (command) {
    case 'boot':
      final name = args.length > 1 ? args[1] : 'tahoe-base';
      await _boot(name);
      break;

    case 'fetch-ipsw':
      print('Fetching latest supported macOS IPSW URL from Apple...');
      try {
        final url = await AppleVirtualization.fetchLatestIpswUrl();
        print('\nLatest supported IPSW URL:\n$url');
        print('\nYou can download this IPSW automatically by running:');
        print('  dart run example/main.dart download');
      } catch (e) {
        print('Error fetching IPSW URL: $e');
      }
      break;

    case 'download':
      print('Fetching latest supported macOS IPSW URL from Apple...');
      try {
        final url = await AppleVirtualization.fetchLatestIpswUrl();
        final savePath = args.length > 1
            ? args[1]
            : '${VirtualMachine.defaultVmsDir}/../downloads/${url.pathSegments.last}';

        print('Downloading IPSW to $savePath...');
        final stopwatch = Stopwatch()..start();
        
        final metadataFile = File('$savePath.download');
        if (metadataFile.existsSync()) {
          print('Resuming download from previous state...');
        }

        int lastTime = stopwatch.elapsedMilliseconds;
        int lastDownloaded = 0;
        double speedMb = 0.0;
        int etaSeconds = 0;

        await VirtualMachine.downloadIpsw(
          uri: url,
          savePath: savePath,
          concurrency: 8,
          onProgress: (downloaded, total) {
            final now = stopwatch.elapsedMilliseconds;
            final percent = ((downloaded / total) * 100.0).toStringAsFixed(2);
            
            if (now - lastTime >= 500) {
              final diff = downloaded - lastDownloaded;
              final sec = (now - lastTime) / 1000.0;
              final speedBytesPerSec = diff / sec;
              speedMb = speedBytesPerSec / (1024.0 * 1024.0);

              final remainingBytes = total - downloaded;
              etaSeconds = speedBytesPerSec > 0 ? (remainingBytes / speedBytesPerSec).round() : 0;

              lastDownloaded = downloaded;
              lastTime = now;
            }

            final elapsedMinutes = stopwatch.elapsed.inMinutes;
            final elapsedSeconds = stopwatch.elapsed.inSeconds % 60;
            final speedStr = speedMb >= 0 ? '${speedMb.toStringAsFixed(1)} MB/s' : '-- MB/s';
            
            String etaStr;
            if (etaSeconds <= 0) {
              etaStr = '--';
            } else if (etaSeconds < 60) {
              etaStr = '${etaSeconds}s';
            } else if (etaSeconds < 3600) {
              etaStr = '${etaSeconds ~/ 60}m ${etaSeconds % 60}s';
            } else {
              final hours = etaSeconds ~/ 3600;
              final minutes = (etaSeconds % 3600) ~/ 60;
              final seconds = etaSeconds % 60;
              etaStr = '${hours}h ${minutes}m ${seconds}s';
            }
            
            stdout.write(
                '\rDownloading... $percent% ($speedStr) [Elapsed: ${elapsedMinutes}m ${elapsedSeconds}s, ETA: $etaStr]');
          },
        );
        print('\nSuccess: IPSW downloaded successfully to $savePath');
      } catch (e) {
        print('\nError downloading IPSW: $e');
      }
      break;

    case 'install':
      if (args.length < 2) {
        print('Error: Missing IPSW file path.');
        print(
            'Usage: dart run example/main.dart install <ipsw-path> [<vm-name>]');
        exit(1);
      }
      final ipswPath = args[1];
      final name = args.length > 2 ? args[2] : 'tahoe-base';

      print(
          'Starting macOS installation onto VM "$name" using IPSW "$ipswPath"...');
      try {
        await VirtualMachine.install(
          name: name,
          ipswPath: ipswPath,
          onProgress: (progress) {
            stdout.write(
                '\rInstalling macOS... ${(progress * 100.0).toStringAsFixed(2)}%');
          },
        );
        print('\nSuccess: macOS installation complete!');
      } catch (e) {
        print('\nError during installation: $e');
      }
      break;

    default:
      print('Unknown command: $command');
      exit(1);
  }
}

Future<void> _boot(String name) async {
  try {
    final vm = await VirtualMachine.boot(name: name);
    final code = await vm.exitCode;
    print('VM exited with code: $code');
  } catch (e) {
    print('Failed to boot VM: $e');
  }
}
