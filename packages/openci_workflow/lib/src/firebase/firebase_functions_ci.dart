import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

/// Deploys Cloud Functions using the Firebase CLI.
class FirebaseFunctionsCI {
  const FirebaseFunctionsCI(
    this._resolveDirectory, {
    @visibleForTesting
    FirebaseFunctionsProcessRunner processRunner = runFirebaseFunctionsProcess,
  }) : _processRunner = processRunner;

  final String Function(String? dir) _resolveDirectory;
  final FirebaseFunctionsProcessRunner _processRunner;

  /// Deploys [codebase], or all Functions codebases when omitted.
  ///
  /// Requires `firebase` on PATH and its compatible Node.js runtime. Runs with
  /// `--non-interactive`, honoring the config's predeploy/postdeploy hooks.
  /// Prepare source dependencies and runtime environment files before calling.
  /// [firebaseConfigPath] is relative to the workflow directory, or [dir].
  ///
  /// The Base64-encoded service account JSON is written to a temporary ADC file
  /// and deleted in `finally`. Existing Firebase logins/tokens are not used.
  /// Output streams to the workflow log; failures throw [ProcessException].
  Future<void> deploy({
    required String projectId,
    required String serviceAccountJsonBase64,
    String? codebase,
    String firebaseConfigPath = 'firebase.json',
    String? dir,
  }) async {
    if (projectId.trim().isEmpty || firebaseConfigPath.trim().isEmpty) {
      throw ArgumentError(
        'projectId and firebaseConfigPath must not be empty.',
      );
    }
    if (codebase != null && !RegExp(r'^[a-z0-9_-]{1,63}$').hasMatch(codebase)) {
      throw ArgumentError.value(
        codebase,
        'codebase',
        'Invalid Functions codebase.',
      );
    }

    final String credentials;
    try {
      credentials = utf8.decode(base64Decode(serviceAccountJsonBase64));
      final json = jsonDecode(credentials);
      if (json is! Map<String, dynamic> ||
          json['type'] != 'service_account' ||
          json['client_email'] is! String ||
          json['private_key'] is! String) {
        throw const FormatException();
      }
    } on FormatException {
      // Decoder exceptions can contain the input, including a private key.
      throw const FormatException(
        'Expected a Base64-encoded service account JSON key.',
      );
    }

    final temporary = await Directory.systemTemp.createTemp(
      'openci-functions-',
    );
    try {
      final keyFile = File('${temporary.path}/service-account.json');
      await keyFile.writeAsString(credentials, flush: true);
      if (!Platform.isWindows) {
        final chmod = await Process.run('chmod', ['600', keyFile.path]);
        if (chmod.exitCode != 0) {
          throw const FileSystemException(
            'Could not restrict credential file permissions.',
          );
        }
      }
      final environment = Map<String, String>.of(Platform.environment)
        ..remove('FIREBASE_TOKEN')
        ..['GOOGLE_APPLICATION_CREDENTIALS'] = keyFile.path
        ..['XDG_CONFIG_HOME'] = temporary.path
        ..['CI'] = 'true';
      final result = await _processRunner(
        'firebase',
        [
          'deploy',
          '--project=$projectId',
          '--config=$firebaseConfigPath',
          '--only=functions${codebase == null ? '' : ':$codebase'}',
          '--non-interactive',
        ],
        workingDirectory: _resolveDirectory(dir),
        environment: environment,
      );
      if (result != 0) {
        throw ProcessException(
          'firebase',
          const ['deploy'],
          'Firebase Functions deployment failed. See the command output above.',
          result,
        );
      }
    } finally {
      await temporary.delete(recursive: true);
    }
  }
}

typedef FirebaseFunctionsProcessRunner =
    Future<int> Function(
      String executable,
      List<String> arguments, {
      required String workingDirectory,
      required Map<String, String> environment,
    });

Future<int> runFirebaseFunctionsProcess(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  required Map<String, String> environment,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: false,
    mode: ProcessStartMode.inheritStdio,
  );
  return process.exitCode;
}
