import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:googleapis/androidpublisher/v3.dart';
import 'package:googleapis_auth/auth_io.dart';

// ══════════════════════════════════════════════════════════════
// CLI Parser
// ══════════════════════════════════════════════════════════════

ArgParser androidDeployParser() {
  return ArgParser()
    ..addOption('artifact', help: 'Path to the AAB or APK file to upload')
    ..addOption(
      'aab',
      help: 'Path to the AAB file to upload (alias for --artifact)',
    )
    ..addOption(
      'package-name',
      help: 'Android package name (e.g. com.example.app)',
      mandatory: true,
    )
    ..addOption(
      'service-account-json',
      help:
          'Path to Google Cloud service account JSON key file. '
          'If not provided, reads from GOOGLE_PLAY_SERVICE_ACCOUNT_JSON env var '
          '(can be the JSON content itself or a file path).',
    )
    ..addOption(
      'track',
      help: 'Release track (internal, alpha, beta, production)',
      defaultsTo: 'internal',
      allowed: ['internal', 'alpha', 'beta', 'production'],
    )
    ..addOption(
      'status',
      help: 'Release status',
      defaultsTo: 'completed',
      allowed: ['completed', 'draft', 'halted', 'inProgress'],
    )
    ..addOption(
      'release-name',
      help: 'Release name (optional, shown in Play Console)',
    )
    ..addOption(
      'release-notes',
      help:
          'Release notes as JSON array, e.g. '
          '\'[{"language":"en-US","text":"Bug fixes"}]\'',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');
}

// ══════════════════════════════════════════════════════════════
// Main Command
// ══════════════════════════════════════════════════════════════

Future<void> runAndroidDeploy(ArgResults args) async {
  if (args['help'] as bool) {
    print('''
Usage: openci_vm android-deploy [options]

Deploy an AAB or APK to Google Play Console.

${androidDeployParser().usage}

Environment variables:
  GOOGLE_PLAY_SERVICE_ACCOUNT_JSON  Service account JSON key content or file path
''');
    return;
  }

  // Resolve artifact path: --artifact takes priority, then --aab
  final artifactPath = args['artifact'] as String? ?? args['aab'] as String?;
  if (artifactPath == null) {
    _error('No artifact specified. Use --artifact <path> or --aab <path>.');
    exit(1);
  }

  final packageName = args['package-name'] as String;
  final track = args['track'] as String;
  final status = args['status'] as String;
  final releaseName = args['release-name'] as String?;
  final releaseNotesJson = args['release-notes'] as String?;

  // ── Determine artifact type ────────────────────────────────
  final isAab = artifactPath.toLowerCase().endsWith('.aab');
  final isApk = artifactPath.toLowerCase().endsWith('.apk');
  if (!isAab && !isApk) {
    _error(
      'Unknown file type: $artifactPath\n'
      'Supported formats: .aab (Android App Bundle), .apk',
    );
    exit(1);
  }
  final artifactType = isAab ? 'AAB' : 'APK';

  // ── Validate artifact file ─────────────────────────────────
  _log('🤖 OpenCI Android Deploy');
  _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  final artifactFile = File(artifactPath);
  if (!artifactFile.existsSync()) {
    _error('$artifactType file not found: $artifactPath');
    exit(1);
  }

  final fileSizeMb = artifactFile.lengthSync() / (1024 * 1024);
  _log('📦 $artifactType: $artifactPath (${fileSizeMb.toStringAsFixed(1)} MB)');
  _log('📱 Package: $packageName');
  _log('🛤️  Track: $track');
  _log('📋 Status: $status');

  // ── Resolve service account credentials ────────────────────
  final serviceAccountJson = _resolveServiceAccountJson(
    args['service-account-json'] as String?,
  );

  // ── Authenticate ───────────────────────────────────────────
  _log('');
  _log('🔐 Authenticating with Google Play Developer API...');

  final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
  final httpClient = await clientViaServiceAccount(credentials, [
    AndroidPublisherApi.androidpublisherScope,
  ]);

  try {
    final api = AndroidPublisherApi(httpClient);

    // ── Create edit session ────────────────────────────────────
    _log('📝 Creating edit session...');
    final edit = await api.edits.insert(AppEdit(), packageName);
    final editId = edit.id!;
    _log('   Edit ID: $editId');

    // ── Upload artifact ────────────────────────────────────────
    _log('⬆️  Uploading $artifactType (this may take a while)...');
    final uploadMedia = Media(
      artifactFile.openRead(),
      artifactFile.lengthSync(),
      contentType: 'application/octet-stream',
    );

    int? versionCode;

    if (isAab) {
      final bundle = await api.edits.bundles.upload(
        packageName,
        editId,
        uploadMedia: uploadMedia,
      );
      versionCode = bundle.versionCode;
    } else {
      final apk = await api.edits.apks.upload(
        packageName,
        editId,
        uploadMedia: uploadMedia,
      );
      versionCode = apk.versionCode;
    }

    _log('   ✅ Upload complete! Version code: $versionCode');

    // ── Assign to track ────────────────────────────────────────
    _log('🛤️  Assigning to $track track...');

    // Parse release notes if provided
    List<LocalizedText>? releaseNotes;
    if (releaseNotesJson != null) {
      try {
        final notesList = (jsonDecode(releaseNotesJson) as List)
            .cast<Map<String, dynamic>>();
        releaseNotes = notesList
            .map(
              (n) => LocalizedText(
                language: n['language'] as String?,
                text: n['text'] as String?,
              ),
            )
            .toList();
      } catch (e) {
        _error(
          'Failed to parse release notes JSON: $e\n'
          'Expected format: [{"language":"en-US","text":"Bug fixes"}]',
        );
        exit(1);
      }
    }

    var effectiveStatus = status;

    final trackConfig = Track(
      track: track,
      releases: [
        TrackRelease(
          versionCodes: ['$versionCode'],
          status: effectiveStatus,
          name: releaseName,
          releaseNotes: releaseNotes,
        ),
      ],
    );

    await api.edits.tracks.update(trackConfig, packageName, editId, track);
    _log('   ✅ Track updated');

    // ── Commit ─────────────────────────────────────────────────
    _log('🚀 Committing changes...');

    try {
      await api.edits.commit(packageName, editId);
    } on DetailedApiRequestError catch (e) {
      // Draft apps only accept releases with status 'draft'.
      // Auto-fallback: re-create edit with status 'draft' and retry.
      if (e.status == 400 &&
          (e.message?.contains('draft') ?? false) &&
          effectiveStatus != 'draft') {
        _log('');
        _log('⚠️  App is in draft state on Google Play Console.');
        _log('   Retrying with status: draft ...');

        effectiveStatus = 'draft';

        // Previous edit is invalidated after a failed commit, create a new one.
        final retryEdit = await api.edits.insert(AppEdit(), packageName);
        final retryEditId = retryEdit.id!;

        // Re-upload artifact
        final retryMedia = Media(
          artifactFile.openRead(),
          artifactFile.lengthSync(),
          contentType: 'application/octet-stream',
        );

        if (isAab) {
          await api.edits.bundles.upload(
            packageName,
            retryEditId,
            uploadMedia: retryMedia,
          );
        } else {
          await api.edits.apks.upload(
            packageName,
            retryEditId,
            uploadMedia: retryMedia,
          );
        }

        final retryTrackConfig = Track(
          track: track,
          releases: [
            TrackRelease(
              versionCodes: ['$versionCode'],
              status: 'draft',
              name: releaseName,
              releaseNotes: releaseNotes,
            ),
          ],
        );

        await api.edits.tracks.update(
          retryTrackConfig,
          packageName,
          retryEditId,
          track,
        );

        await api.edits.commit(packageName, retryEditId);
        _log('   ✅ Committed as draft');
      } else {
        rethrow;
      }
    }

    _log('');
    _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _log('✅ Successfully deployed to Google Play Console!');
    _log('   Package: $packageName');
    _log('   Version code: $versionCode');
    _log('   Track: $track');
    _log('   Status: $effectiveStatus');
    _log('   Type: $artifactType');
    if (effectiveStatus == 'draft' && status != 'draft') {
      _log('');
      _log('📋 Note: Release was created as draft because the app');
      _log('   has not been published yet. Go to Google Play Console');
      _log('   to review and publish the release.');
    }
    _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  } on DetailedApiRequestError catch (e) {
    _error('Google Play API error: ${e.status} - ${e.message}');
    for (final err in e.errors) {
      _error('  • ${err.message} (${err.reason})');
    }
    exit(1);
  } catch (e) {
    _error('Unexpected error: $e');
    exit(1);
  } finally {
    httpClient.close();
  }
}

// ══════════════════════════════════════════════════════════════
// Helpers
// ══════════════════════════════════════════════════════════════

/// Resolves service account JSON from either:
/// 1. --service-account-json flag (file path)
/// 2. GOOGLE_PLAY_SERVICE_ACCOUNT_JSON env var (JSON content or file path)
String _resolveServiceAccountJson(String? flagValue) {
  // Option 1: from --service-account-json flag
  if (flagValue != null) {
    final file = File(flagValue);
    if (!file.existsSync()) {
      _error('Service account JSON file not found: $flagValue');
      exit(1);
    }
    _log('🔑 Service account: $flagValue');
    return file.readAsStringSync();
  }

  // Option 2: from environment variable
  final envValue = Platform.environment['GOOGLE_PLAY_SERVICE_ACCOUNT_JSON'];
  if (envValue == null || envValue.isEmpty) {
    _error(
      'No service account credentials provided.\n'
      'Either pass --service-account-json or set '
      'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON environment variable.',
    );
    exit(1);
  }

  // Check if env value is a file path or JSON content
  if (envValue.trimLeft().startsWith('{')) {
    _log('🔑 Service account: from GOOGLE_PLAY_SERVICE_ACCOUNT_JSON env var');
    return envValue;
  }

  // It's a file path
  final file = File(envValue);
  if (!file.existsSync()) {
    _error(
      'Service account JSON file not found: $envValue '
      '(from GOOGLE_PLAY_SERVICE_ACCOUNT_JSON env var)',
    );
    exit(1);
  }
  _log('🔑 Service account: $envValue (from env var)');
  return file.readAsStringSync();
}

void _log(String message) {
  print(message);
}

void _error(String message) {
  print('❌ $message');
}
