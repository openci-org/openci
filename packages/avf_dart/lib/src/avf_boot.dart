import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

class AppleVirtualization {
  /// Launches the virtualization helper binary with the given macOS configuration.
  static Future<Process> boot({
    required String diskImgPath,
    required String nvramPath,
    required String hardwareModelB64,
    required String machineIdentifierB64,
    required String macAddress,
  }) async {
    final helperBinary = await _findHelperBinary();

    // 2. Start VM process using the helper binary with macOS arguments
    final Process process;
    try {
      process = await Process.start(helperBinary, [
        'boot',
        diskImgPath,
        nvramPath,
        hardwareModelB64,
        machineIdentifierB64,
        macAddress,
      ]);
    } catch (e) {
      rethrow;
    }

    return process;
  }

  /// Searches for config.json, disk.img, and nvram.bin inside the given [directoryPath],
  /// parses macOS machine metadata, and boots the macOS VM.
  static Future<Process> bootFromDirectory(String directoryPath) async {
    final configFile = File('$directoryPath/config.json');
    if (!configFile.existsSync()) {
      throw FileSystemException(
          'config.json not found in VM directory', configFile.path);
    }

    final configData = jsonDecode(configFile.readAsStringSync());
    if (configData['os'] != 'macOS') {
      throw StateError(
          'Only macOS VMs are supported. Found OS: ${configData['os']}');
    }

    final diskImgPath = '$directoryPath/disk.img';
    final nvramPath = '$directoryPath/nvram.bin';
    final hardwareModelB64 = configData['hardwareModel'] as String?;
    final machineIdentifierB64 = configData['machineIdentifier'] as String?;
    var macAddress = configData['macAddress'] as String?;

    if (hardwareModelB64 == null || machineIdentifierB64 == null) {
      throw StateError(
          'hardwareModel or machineIdentifier missing in config.json');
    }
    if (macAddress == null || macAddress.isEmpty) {
      macAddress = _generateRandomMacAddress();
      configData['macAddress'] = macAddress;
      try {
        configFile.writeAsStringSync(
            const JsonEncoder.withIndent('  ').convert(configData));
      } catch (_) {}
    }

    if (!File(diskImgPath).existsSync()) {
      throw FileSystemException('Disk image not found', diskImgPath);
    }
    if (!File(nvramPath).existsSync()) {
      throw FileSystemException('NVRAM file not found', nvramPath);
    }

    return boot(
      diskImgPath: diskImgPath,
      nvramPath: nvramPath,
      hardwareModelB64: hardwareModelB64,
      machineIdentifierB64: machineIdentifierB64,
      macAddress: macAddress,
    );
  }

  /// Contacts Apple's servers using the Virtualization framework API to retrieve
  /// the URL for the latest supported macOS restore image (IPSW).
  static Future<Uri> fetchLatestIpswUrl() async {
    final helperBinary = await _findHelperBinary();

    final tmpFile = File('${Directory.systemTemp.path}/avf_ipsw_url.txt');
    if (tmpFile.existsSync()) {
      tmpFile.deleteSync();
    }

    final processResult =
        await Process.run(helperBinary, ['fetch-ipsw-url', tmpFile.path]);
    if (processResult.exitCode != 0) {
      throw StateError('Failed to fetch IPSW URL: ${processResult.stderr}');
    }

    if (!tmpFile.existsSync()) {
      throw StateError('IPSW URL file was not created by helper.');
    }

    final urlStr = tmpFile.readAsStringSync().trim();
    try {
      tmpFile.deleteSync();
    } catch (_) {}

    return Uri.parse(urlStr);
  }

  /// Starts the macOS installation process onto a blank virtual disk.
  /// Standard output of the returned process can be parsed for progress updates.
  static Future<Process> install({
    required String ipswPath,
    required String diskImgPath,
    required String nvramPath,
    required String configJsonPath,
  }) async {
    final helperBinary = await _findHelperBinary();

    final process = await Process.start(helperBinary, [
      'install',
      ipswPath,
      diskImgPath,
      nvramPath,
      configJsonPath,
    ]);

    return process;
  }

  /// Locates the avf_helper binary, supporting both local execution and pub-cache AOT deployment.
  static Future<String> _findHelperBinary() async {
    // 1. Try to resolve via Isolate package URI (normal project run - only trust if it points to a local dev environment)
    try {
      final packageUri = Uri.parse('package:avf_dart/avf_dart.dart');
      final resolvedUri = await Isolate.resolvePackageUri(packageUri);
      if (resolvedUri != null) {
        final libDir = File(resolvedUri.toFilePath()).parent;
        final packageRoot = libDir.parent;
        if (packageRoot.path.endsWith('packages/avf_dart')) {
          final helper = '${packageRoot.path}/.dart_tool/avf_dart/avf_helper';
          if (File(helper).existsSync()) {
            return helper;
          }
        }
      }
    } catch (_) {}

    // 2. Try to fallback to pub-cache dynamic scanning (AOT/global run)
    // Find the latest version of avf_dart in pub-cache.
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null) {
      final pubCacheDir = Directory('$home/.pub-cache/hosted/pub.dev');
      if (pubCacheDir.existsSync()) {
        final matches = pubCacheDir
            .listSync()
            .whereType<Directory>()
            .where((d) => d.uri.pathSegments
                .where((s) => s.isNotEmpty)
                .last
                .startsWith('avf_dart-'))
            .toList();

        // Sort packages by version descending
        matches.sort((a, b) {
          final aVer = a.uri.pathSegments
              .where((s) => s.isNotEmpty)
              .last
              .replaceFirst('avf_dart-', '');
          final bVer = b.uri.pathSegments
              .where((s) => s.isNotEmpty)
              .last
              .replaceFirst('avf_dart-', '');
          return _compareVersions(bVer, aVer); // Descending (latest first)
        });

        for (final match in matches) {
          final helper = File('${match.path}/.dart_tool/avf_dart/avf_helper');
          if (helper.existsSync()) {
            return helper.path;
          }
        }
      }
    }

    // 3. Fallback: Try general Isolate resolve (even if it might point to a dummy install dir)
    try {
      final packageUri = Uri.parse('package:avf_dart/avf_dart.dart');
      final resolvedUri = await Isolate.resolvePackageUri(packageUri);
      if (resolvedUri != null) {
        final libDir = File(resolvedUri.toFilePath()).parent;
        final packageRoot = libDir.parent;
        final helper = '${packageRoot.path}/.dart_tool/avf_dart/avf_helper';
        if (File(helper).existsSync()) {
          return helper;
        }
      }
    } catch (_) {}

    // 4. Last resort: Try standard relative path if running from source
    final localHelper = './.dart_tool/avf_dart/avf_helper';
    if (File(localHelper).existsSync()) {
      return localHelper;
    }

    throw StateError(
        'Could not locate avf_helper binary. Ensure package:avf_dart is resolved or compiled.');
  }

  static int _compareVersions(String a, String b) {
    final aClean = a.split('-').first;
    final bClean = b.split('-').first;
    final aParts = aClean.split('.').map(int.tryParse).toList();
    final bParts = bClean.split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final aVal = i < aParts.length ? (aParts[i] ?? 0) : 0;
      final bVal = i < bParts.length ? (bParts[i] ?? 0) : 0;
      if (aVal != bVal) {
        return aVal.compareTo(bVal);
      }
    }
    return a.compareTo(b);
  }

  static String _generateRandomMacAddress() {
    final r = DateTime.now().microsecondsSinceEpoch;
    // locally administered unicast
    final firstByte = 0x02;
    final mac = [
      firstByte,
      (r >> 32) & 0xff,
      (r >> 24) & 0xff,
      (r >> 16) & 0xff,
      (r >> 8) & 0xff,
      r & 0xff,
    ];
    return mac.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
  }
}
