import 'dart:convert';
import 'dart:io';

import 'package:genuineci_cli/src/asc/asc_api_key.dart';
import 'package:genuineci_cli/src/asc/asc_api_key_secret.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  const pem =
      '-----BEGIN PRIVATE KEY-----\ndGVzdA==\n-----END PRIVATE KEY-----\n';
  late Directory directory;
  late File privateKey;
  late File metadata;
  late Map<String, Object?> fields;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('asc saved key test ');
    privateKey = await File(
      p.join(directory.path, 'AuthKey_KEY123.p8'),
    ).writeAsString(pem);
    metadata = File(p.join(directory.path, 'key.json'));
    fields = {
      'keyId': 'KEY123',
      'issuerId': 'issuer',
      'p8Path': privateKey.path,
      'role': 'APP_MANAGER',
    };
    await metadata.writeAsString(jsonEncode(fields));
  });
  tearDown(() => directory.delete(recursive: true));

  test(
    'reads a saved key and encodes one fastlane-compatible secret',
    () async {
      final key = await readSavedAscApiKey(directory);
      expect(key.keyId, 'KEY123');
      expect(key.issuerId, 'issuer');
      expect(jsonDecode(await encodeAscApiKeySecret(key)), {
        'key_id': 'KEY123',
        'issuer_id': 'issuer',
        'key': pem,
      });
      expect(await privateKey.readAsString(), pem);
      expect(await metadata.exists(), isTrue);
    },
  );

  for (final changes in <Map<String, Object?>>[
    {'keyId': '../outside'},
    {'keyId': null},
    {'keyId': ''},
    {'issuerId': 123},
    {'issuerId': ''},
    {'issuerId': 'issuer\u001b[2J'},
    {'role': 'ADMIN'},
    {'p8Path': '/outside/private-key.p8'},
    {'p8Path': null},
  ]) {
    test(
      'rejects unsafe or invalid metadata: ${jsonEncode(changes)}',
      () async {
        await metadata.writeAsString(jsonEncode({...fields, ...changes}));
        await expectLater(readSavedAscApiKey(directory), throwsFormatException);
        expect(await privateKey.readAsString(), pem);
      },
    );
  }

  for (final content in ['not-json', '[]', 'null', '', 'x' * (16 * 1024 + 1)]) {
    test(
      'rejects malformed/oversized metadata (${content.length} bytes)',
      () async {
        await metadata.writeAsString(content);
        await expectLater(readSavedAscApiKey(directory), throwsFormatException);
      },
    );
  }

  for (final content in [
    '',
    'plain text',
    '-----BEGIN PRIVATE KEY-----\n!invalid!\n-----END PRIVATE KEY-----',
    'x' * (16 * 1024 + 1),
  ]) {
    test(
      'rejects malformed/oversized private key (${content.length} bytes)',
      () async {
        await privateKey.writeAsString(content);
        await expectLater(readSavedAscApiKey(directory), throwsFormatException);
        expect(await metadata.exists(), isTrue);
      },
    );
  }

  test('preserves CRLF PEM contents when saving', () async {
    final crlf = pem.replaceAll('\n', '\r\n');
    await privateKey.writeAsString(crlf);
    final key = await readSavedAscApiKey(directory);
    expect((jsonDecode(await encodeAscApiKeySecret(key)) as Map)['key'], crlf);
  });

  for (final name in ['key.json', 'AuthKey_KEY123.p8']) {
    test('rejects missing or linked $name', () async {
      final original = File(p.join(directory.path, name));
      final moved = await original.rename('${original.path}.moved');
      await expectLater(readSavedAscApiKey(directory), throwsFormatException);
      await Link(original.path).create(moved.path);
      await expectLater(readSavedAscApiKey(directory), throwsFormatException);
    }, skip: Platform.isWindows);
  }

  test(
    'does not serialize a local path or metadata as private-key content',
    () async {
      final key = AscApiKey(
        keyId: 'KEY123',
        issuerId: 'issuer',
        privateKeyFile: metadata,
      );
      await expectLater(encodeAscApiKeySecret(key), throwsFormatException);
    },
  );
}
