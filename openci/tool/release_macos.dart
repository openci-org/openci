import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:openci_workflows/macos_release_publisher.dart';

/// Runs only on an OpenCI disposable macOS VM. Signing material is deleted
/// afterward; no credential is passed in a logged command or written to Storage.
Future<void> main(List<String> arguments) async {
  try {
    final buildArgument = arguments
        .where((a) => a.startsWith('--build-number='))
        .single;
    final build = int.tryParse(
      buildArgument.replaceFirst('--build-number=', ''),
    );
    if (!buildArgument.startsWith('--build-number=') ||
        build == null ||
        build <= 0) {
      throw StateError('Pass a positive --build-number.');
    }
    if (!Platform.isMacOS) throw StateError('macOS is required.');
    if (arguments.contains('--validate-only') && arguments.length == 2) {
      await validateUnsignedBuild(build);
    } else if (arguments.length == 1) {
      await release(build);
    } else {
      throw StateError('Unknown release arguments.');
    }
  } catch (error) {
    // Tool/HTTP exceptions may contain credentials. Only our controlled errors
    // are surfaced; Apple/Xcode diagnostics are streamed by run() below.
    stderr.writeln(
      error is StateError ? error.message : 'macOS release failed.',
    );
    exitCode = 1;
  }
}

/// Produces a reviewable local app without reading signing credentials,
/// creating certificates, notarizing, or publishing anything.
Future<void> validateUnsignedBuild(int build) async {
  final appDirectory = '${Directory.current.path}/apps/dashboard';
  final derivedData =
      '${Directory.current.path}/build/macos-release-validation';
  await run(
    'Prepare unsigned validation build',
    'flutter',
    [
      'build',
      'macos',
      '--release',
      '--config-only',
      '--build-number=$build',
    ],
    cwd: appDirectory,
    timeout: const Duration(minutes: 15),
  );
  await run(
    'Build macOS app without signing or publishing',
    'xcodebuild',
    [
      '-workspace',
      '$appDirectory/macos/Runner.xcworkspace',
      '-scheme',
      'Runner',
      '-configuration',
      'Release',
      '-destination',
      'generic/platform=macOS',
      '-derivedDataPath',
      derivedData,
      'build',
      'CODE_SIGNING_ALLOWED=NO',
    ],
    timeout: const Duration(minutes: 40),
  );
  stdout.writeln(
    'Unsigned validation app: $derivedData/Build/Products/Release/OpenCI.app',
  );
}

String secret(String name) {
  final value = Platform.environment[name];
  if (value == null || value.trim().isEmpty) {
    throw StateError('Required secret $name is missing.');
  }
  return value;
}

Future<void> release(int build) async {
  final temporary = await Directory.systemTemp.createTemp(
    'openci-macos-release-',
  );
  final appDirectory = '${Directory.current.path}/apps/dashboard';
  final keychain = '${temporary.path}/signing.keychain-db';
  var keychainCreated = false;
  try {
    final ascKey = await writePrivate(
      temporary,
      'asc.p8',
      base64Decode(secret('OPENCI_GENERATED_P8_BASE64')),
    );
    final certificateKey = await writePrivate(
      temporary,
      'certificate.pem',
      utf8.encode(
        secret('MACOS_CERTIFICATE_PRIVATE_KEY').replaceAll(r'\n', '\n'),
      ),
    );
    final sparkleKey = await writePrivate(
      temporary,
      'sparkle.key',
      utf8.encode(secret('SPARKLE_PRIVATE_ED_KEY').trim()),
    );
    final firebaseOptions = File('$appDirectory/lib/firebase_options.dart');
    await firebaseOptions.writeAsBytes(
      base64Decode(secret('FIREBASE_OPTIONS_DART_BASE64')),
    );

    final issuer = secret('OPENCI_GENERATED_ASC_ISSUER_ID');
    final keyId = secret('OPENCI_GENERATED_ASC_KEY_ID');
    final certificates = '${temporary.path}/certificates';
    final userHome = Platform.environment['HOME'];
    if (userHome == null || userHome.isEmpty) {
      throw StateError('The macOS build user has no home directory.');
    }
    // Xcode discovers installed profiles here; a private staging directory is
    // sufficient for Codemagic's project edits but not for the archive itself.
    final profiles =
        '$userHome/Library/Developer/Xcode/UserData/Provisioning Profiles';
    final exportOptions = '${temporary.path}/ExportOptions.plist';
    final archive = '${temporary.path}/OpenCI.xcarchive';
    final sourcePackages = '${temporary.path}/SourcePackages';
    final derivedData = '${temporary.path}/DerivedData';
    final exported = '${temporary.path}/exported';
    final updates = Directory('${temporary.path}/updates');
    await updates.create();

    await run(
      'Prepare Flutter release configuration',
      'flutter',
      [
        'build',
        'macos',
        '--release',
        '--config-only',
        '--build-number=$build',
      ],
      cwd: appDirectory,
      timeout: const Duration(minutes: 15),
    );
    await run('Prepare signing keychain', 'keychain', [
      'initialize',
      '--path',
      keychain,
    ]);
    keychainCreated = true;
    await run('Fetch Developer ID signing files', 'app-store-connect', [
      'fetch-signing-files',
      'org.openci.dashboard',
      '--platform',
      'MAC_OS',
      '--type',
      'MAC_APP_DIRECT',
      '--strict-match-identifier',
      '--issuer-id',
      issuer,
      '--key-id',
      keyId,
      '--private-key',
      '@file:${ascKey.path}',
      '--certificate-key',
      '@file:${certificateKey.path}',
      '--certificates-dir',
      certificates,
      '--profiles-dir',
      profiles,
      '--disable-jwt-cache',
      '--create',
    ]);
    await run('Import signing certificate', 'keychain', [
      'add-certificates',
      '--path',
      keychain,
      '--certificate',
      '$certificates/*.p12',
    ]);
    await run('Apply Developer ID profiles', 'xcode-project', [
      'use-profiles',
      '--project',
      '$appDirectory/macos/Runner.xcodeproj',
      '--profile',
      '$profiles/*.provisionprofile',
      '$profiles/*.mobileprovision',
      '--export-options-plist',
      exportOptions,
      '--custom-export-options',
      '{"signingStyle":"manual"}',
    ]);
    // Codemagic 0.69.1 validates method against an iOS-only enum. Apply the
    // macOS export method after it has generated the profile assignments.
    await run('Set Developer ID export method', '/usr/libexec/PlistBuddy', [
      '-c',
      'Set :method developer-id',
      exportOptions,
    ]);
    final signingTeam = (await run(
      'Read signing team',
      '/usr/libexec/PlistBuddy',
      ['-c', 'Print :teamID', exportOptions],
      capture: true,
    )).trim();
    if (!RegExp(r'^[A-Z0-9]{10}$').hasMatch(signingTeam)) {
      throw StateError('The signing profile has no valid Apple team.');
    }
    await run('Archive macOS app', 'xcodebuild', [
      '-workspace',
      '$appDirectory/macos/Runner.xcworkspace',
      '-scheme',
      'Runner',
      '-configuration',
      'Release',
      '-destination',
      'generic/platform=macOS',
      '-archivePath',
      archive,
      'archive',
      'ENABLE_HARDENED_RUNTIME=YES',
      '-derivedDataPath',
      derivedData,
      '-clonedSourcePackagesDirPath',
      sourcePackages,
      'CODE_SIGN_IDENTITY=Developer ID Application',
      'DEVELOPMENT_TEAM=$signingTeam',
    ], timeout: const Duration(minutes: 40));
    await run('Export Developer ID app', 'xcodebuild', [
      '-exportArchive',
      '-archivePath',
      archive,
      '-exportPath',
      exported,
      '-exportOptionsPlist',
      exportOptions,
    ], timeout: const Duration(minutes: 15));

    final app = '$exported/OpenCI.app';
    await run('Validate code signatures', 'codesign', [
      '--verify',
      '--deep',
      '--strict',
      app,
    ]);
    final notarizationZip = '${temporary.path}/notarization.zip';
    await run('Package app for notarization', 'ditto', [
      '-c',
      '-k',
      '--sequesterRsrc',
      '--keepParent',
      app,
      notarizationZip,
    ]);
    final notary = await run(
      'Wait for Apple notarization',
      'xcrun',
      [
        'notarytool',
        'submit',
        notarizationZip,
        '--key',
        ascKey.path,
        '--key-id',
        keyId,
        '--issuer',
        issuer,
        '--wait',
        '--timeout',
        '30m',
        '--output-format',
        'json',
      ],
      capture: true,
      timeout: const Duration(minutes: 35),
    );
    final notaryResult = jsonDecode(notary) as Map;
    if (notaryResult['status'] != 'Accepted') {
      throw StateError(
        'Apple did not accept the notarization. Check the submission in Apple Developer.',
      );
    }
    await run('Attach notarization ticket', 'xcrun', [
      'stapler',
      'staple',
      app,
    ]);
    await run('Validate notarization ticket', 'xcrun', [
      'stapler',
      'validate',
      app,
    ]);
    await run('Validate Gatekeeper acceptance', 'spctl', [
      '--assess',
      '--type',
      'execute',
      '--verbose=2',
      app,
    ]);

    final plist = '$app/Contents/Info.plist';
    final version = (await run('Read app version', '/usr/libexec/PlistBuddy', [
      '-c',
      'Print :CFBundleShortVersionString',
      plist,
    ], capture: true)).trim();
    final builtNumber = (await run(
      'Read app build number',
      '/usr/libexec/PlistBuddy',
      [
        '-c',
        'Print :CFBundleVersion',
        plist,
      ],
      capture: true,
    )).trim();
    final feedUrl = (await run(
      'Validate app feed URL',
      '/usr/libexec/PlistBuddy',
      [
        '-c',
        'Print :SUFeedURL',
        plist,
      ],
      capture: true,
    )).trim();
    final publicKey = (await run(
      'Validate app update key',
      '/usr/libexec/PlistBuddy',
      [
        '-c',
        'Print :SUPublicEDKey',
        plist,
      ],
      capture: true,
    )).trim();
    if (!RegExp(r'^\d+\.\d+\.\d+(?:[.+-][A-Za-z0-9.-]+)?$').hasMatch(version) ||
        builtNumber != '$build' ||
        feedUrl != releaseUrl(releaseFeedObject).toString() ||
        base64Decode(publicKey).length != 32) {
      throw StateError(
        'Exported app has invalid version or Sparkle configuration.',
      );
    }
    final fileName = 'OpenCI-$version-$build.zip';
    final releaseArchive = File('${updates.path}/$fileName');
    await run('Create final update archive', 'ditto', [
      '-c',
      '-k',
      '--sequesterRsrc',
      '--keepParent',
      app,
      releaseArchive.path,
    ]);
    final sparkleBin = '$sourcePackages/artifacts/sparkle/Sparkle/bin';
    if (!await File('$sparkleBin/generate_appcast').exists()) {
      throw StateError(
        'The resolved Sparkle distribution has no appcast tool.',
      );
    }
    await run('Generate signed appcast', '$sparkleBin/generate_appcast', [
      '--ed-key-file',
      sparkleKey.path,
      '--maximum-deltas',
      '0',
      '--download-url-prefix',
      releaseUrl('$releasePrefix/releases/$build/').toString(),
      '--link',
      'https://genuineci.com',
      updates.path,
    ]);
    final appcast = await File('${updates.path}/appcast.xml').readAsString();
    await publish(releaseArchive, appcast, build, version);
  } finally {
    if (keychainCreated) {
      // Build VMs are disposable. Restore the default before deleting this
      // workflow's keychain so later cleanup tools do not use a deleted path.
      await Process.run('keychain', ['use-login']);
      await Process.run('security', ['delete-keychain', keychain]);
    }
    await temporary.delete(recursive: true);
  }
}

Future<File> writePrivate(
  Directory directory,
  String name,
  List<int> bytes,
) async {
  final file = File('${directory.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  await Process.run('chmod', ['600', file.path]);
  return file;
}

Future<void> publish(
  File archive,
  String appcast,
  int build,
  String version,
) async {
  final baseClient = http.Client();
  final publicClient = http.Client();
  AutoRefreshingAuthClient? client;
  try {
    final credentials = ServiceAccountCredentials.fromJson(
      jsonDecode(
        utf8.decode(
          base64Decode(secret('MACOS_RELEASE_SERVICE_ACCOUNT_JSON_BASE64')),
        ),
      ),
    );
    client = await clientViaServiceAccount(
      credentials,
      ['https://www.googleapis.com/auth/devstorage.read_write'],
      baseClient: baseClient,
    ).timeout(const Duration(seconds: 60));
    final published = await MacosReleasePublisher(client, publicClient).publish(
      archive: archive,
      appcast: appcast,
      buildNumber: build,
      version: version,
    );
    stdout.writeln(
      published
          ? 'Published macOS $version ($build): ${releaseUrl(releaseFeedObject)}'
          : 'A newer or identical macOS build is already published.',
    );
  } finally {
    client?.close();
    baseClient.close();
    publicClient.close();
  }
}

Future<String> run(
  String label,
  String executable,
  List<String> arguments, {
  String? cwd,
  bool capture = false,
  Duration timeout = const Duration(minutes: 5),
}) async {
  stdout.writeln(label);
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: cwd,
  );
  final output = StringBuffer();
  final streams = Future.wait([
    process.stdout.transform(utf8.decoder).forEach((text) {
      if (capture) {
        output.write(text);
      } else {
        stdout.write(text);
      }
    }),
    process.stderr.transform(utf8.decoder).forEach((text) {
      if (!capture) stderr.write(text);
    }),
  ]);
  try {
    final code = await process.exitCode.timeout(timeout);
    await streams;
    if (code != 0) throw StateError('$label failed (exit $code).');
    return output.toString();
  } on TimeoutException {
    process.kill(ProcessSignal.sigkill);
    await streams;
    throw StateError('$label timed out. No release feed was changed.');
  }
}
