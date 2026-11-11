import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const maxReleaseMetadataBytes = 2048;

Map<String, String> validatedReleaseMetadata({
  String? version,
  String? buildNumber,
}) {
  final metadata = <String, String>{};
  for (final entry in {
    'version': version,
    'buildNumber': buildNumber,
  }.entries) {
    final value = entry.value;
    if (value == null || value.isEmpty) continue;
    if (utf8.encode(value).length > 256 ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(value) ||
        value.trim() != value) {
      throw ArgumentError('Invalid app release ${entry.key}.');
    }
    metadata[entry.key] = value;
  }
  return metadata;
}

File? _metadataFile(Uri url) {
  final output = Platform.environment['OPENCI_PR_QR_OUTPUT'];
  if (output == null || output.isEmpty) return null;
  final key = sha256.convert(utf8.encode(url.toString()));
  return File('$output/releases/$key.json');
}

// Retain only the version fields, keyed by the exact tester URL. Keeping them
// in the run's output directory also works across workflow isolates/processes.
Future<void> rememberPullRequestRelease(
  Uri url, {
  String? version,
  String? buildNumber,
}) async {
  final file = _metadataFile(url);
  if (file == null) return;
  final metadata = validatedReleaseMetadata(
    version: version,
    buildNumber: buildNumber,
  );
  await file.parent.create(recursive: true);
  final temporary = await file.parent.createTemp('.pending-');
  try {
    final pending = File('${temporary.path}/metadata.json');
    await pending.writeAsString(jsonEncode(metadata));
    await pending.rename(file.path);
  } finally {
    await temporary.delete(recursive: true);
  }
}

Future<Map<String, String>> readPullRequestRelease(Uri url) async {
  final file = _metadataFile(url);
  if (file == null || !await file.exists()) return {};
  final bytes = await file
      .openRead(0, maxReleaseMetadataBytes + 1)
      .fold(
        <int>[],
        (bytes, chunk) => bytes..addAll(chunk),
      );
  if (bytes.length > maxReleaseMetadataBytes) {
    throw const FormatException('App release metadata exceeds its limit.');
  }
  final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  return validatedReleaseMetadata(
    version: data['version'] as String?,
    buildNumber: data['buildNumber'] as String?,
  );
}
