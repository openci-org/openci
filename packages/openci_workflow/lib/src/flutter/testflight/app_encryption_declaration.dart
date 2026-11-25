import '../../app_store_connect_keys.dart';
import 'app_store_connect_client.dart';
import 'testflight_export_compliance.dart';

void validateExportCompliance(TestFlightExportCompliance compliance) {
  if (compliance.appDescription.trim().isEmpty) {
    throw ArgumentError(
      'An app description is required for export compliance.',
    );
  }
}

Future<void> applyTestFlightExportCompliance({
  required String buildId,
  required AppStoreConnectKeys ascKeys,
  required TestFlightExportCompliance exportCompliance,
}) async {
  if (!isAppStoreResourceId(buildId)) {
    throw ArgumentError('A valid App Store Connect build ID is required.');
  }
  validateExportCompliance(exportCompliance);
  final client = AppStoreConnectClient(ascKeys);
  try {
    await applyExportComplianceToBuild(client, buildId, exportCompliance);
  } finally {
    client.close();
  }
}

Future<void> applyExportComplianceToBuild(
  AppStoreConnectClient client,
  String buildId,
  TestFlightExportCompliance compliance,
) async {
  final response = await client.request(
    'GET',
    '/v1/builds/$buildId',
    'read export compliance for build $buildId',
    query: {
      'include': 'app,appEncryptionDeclaration',
      'fields[builds]': 'app,appEncryptionDeclaration,usesNonExemptEncryption',
      'fields[apps]': 'bundleId',
      'fields[appEncryptionDeclarations]': 'appEncryptionDeclarationState',
    },
  );
  final build = appStoreResource(response['data'], 'builds', id: buildId);
  final app = appStoreResource(build['relationships']?['app']?['data'], 'apps');
  final declaration = await _resolveDeclaration(
    client,
    app['id'] as String,
    compliance,
  );
  if (!declaration.isReady) {
    throw StateError(
      'App Store Connect encryption declaration ${declaration.id} is ${declaration.state}. '
      'Check App Encryption Documentation in App Store Connect. After approval, '
      'rerun applyTestFlightExportCompliance() for build $buildId.',
    );
  }
  await declaration.applyToBuild(client, build);
}

Future<_Declaration> _resolveDeclaration(
  AppStoreConnectClient client,
  String appId,
  TestFlightExportCompliance compliance,
) async {
  final answers = {
    'appDescription': compliance.appDescription.trim(),
    'containsProprietaryCryptography': false,
    'containsThirdPartyCryptography': true,
    'availableOnFrenchStore': compliance.availableOnFrenchStore,
  };
  final existing = await _findDeclaration(client, appId, answers);
  if (existing != null) return existing;

  final Map<String, dynamic> response;
  try {
    response = await client.request(
      'POST',
      '/v1/appEncryptionDeclarations',
      'create app encryption declaration',
      body: {
        'data': {
          'type': 'appEncryptionDeclarations',
          'attributes': answers,
          'relationships': {
            'app': {
              'data': {'type': 'apps', 'id': appId},
            },
          },
        },
      },
    );
  } on AppStoreConnectHttpException catch (error) {
    if (error.statusCode != 409) rethrow;
    // Another workflow may have created the declaration after our lookup.
    final concurrent = await _findDeclaration(client, appId, answers);
    if (concurrent == null) rethrow;
    return concurrent;
  }
  return _Declaration.fromResource(
    appStoreResource(response['data'], 'appEncryptionDeclarations'),
  );
}

Future<_Declaration?> _findDeclaration(
  AppStoreConnectClient client,
  String appId,
  Map<String, Object> answers,
) async {
  final path = '/v1/apps/$appId/appEncryptionDeclarations';
  final cursors = <String>{};
  String? cursor;
  _Declaration? pending;
  do {
    final page = await client.request(
      'GET',
      path,
      'find app encryption declaration',
      query: {
        'fields[appEncryptionDeclarations]':
            '${answers.keys.join(',')},platform,exempt,appEncryptionDeclarationState',
        'limit': '200',
        'cursor': ?cursor,
      },
    );
    final items = page['data'];
    if (items is! List) {
      throw StateError(
        'Invalid App Store Connect encryption declaration list.',
      );
    }
    for (final item in items) {
      final data = appStoreResource(item, 'appEncryptionDeclarations');
      final attributes = data['attributes'];
      if (attributes is! Map) {
        throw StateError('Missing App Store Connect declaration attributes.');
      }
      if ((attributes['platform'] != null && attributes['platform'] != 'IOS') ||
          !answers.entries.every((e) => attributes[e.key] == e.value)) {
        continue;
      }
      final declaration = _Declaration.fromResource(data);
      if (declaration.isReady) return declaration;
      if (declaration.state == 'EXPIRED') continue;
      if (pending == null ||
          declaration.state == 'IN_REVIEW' ||
          (declaration.state == 'CREATED' && pending.state != 'IN_REVIEW')) {
        pending = declaration;
      }
    }
    final next = page['links']?['next'];
    if (next == null) return pending;
    // Forward only the cursor, to the same app-scoped endpoint.
    cursor = next is String
        ? Uri.tryParse(next)?.queryParameters['cursor']
        : null;
    if (cursor == null || cursor.isEmpty || !cursors.add(cursor)) {
      throw StateError('Invalid App Store Connect declaration pagination.');
    }
  } while (true);
}

class _Declaration {
  const _Declaration(this.id, this.state, this.exempt);

  factory _Declaration.fromResource(Map<String, dynamic> data) {
    if (data['attributes'] case {
      'appEncryptionDeclarationState': String state,
    }) {
      final exempt = data['attributes']['exempt'];
      if (const {
            'CREATED',
            'IN_REVIEW',
            'APPROVED',
            'REJECTED',
            'INVALID',
            'EXPIRED',
          }.contains(state) &&
          (exempt is bool || (exempt == null && state != 'APPROVED'))) {
        return _Declaration(
          data['id'] as String,
          state,
          exempt as bool?,
        );
      }
    }
    throw StateError('Invalid App Store Connect encryption declaration.');
  }

  final String id;
  final String state;
  final bool? exempt;

  bool get isReady =>
      state == 'APPROVED' || (state == 'CREATED' && exempt == true);

  Future<void> applyToBuild(
    AppStoreConnectClient client,
    Map<String, dynamic> current,
  ) async {
    final buildId = current['id'] as String;
    final usesNonExemptEncryption = exempt == false;
    final declaredValue = current['attributes']?['usesNonExemptEncryption'];
    final linked =
        current['relationships']?['appEncryptionDeclaration']?['data'];
    final linkedId = linked == null
        ? null
        : appStoreResource(linked, 'appEncryptionDeclarations')['id'];
    final attachDeclaration = usesNonExemptEncryption || linkedId != null;
    if (declaredValue == usesNonExemptEncryption &&
        (!attachDeclaration || linkedId == id)) {
      return;
    }
    final response = await client.request(
      'PATCH',
      '/v1/builds/$buildId',
      'apply export compliance to build $buildId',
      body: {
        'data': {
          'type': 'builds',
          'id': buildId,
          if (declaredValue != usesNonExemptEncryption)
            'attributes': {'usesNonExemptEncryption': usesNonExemptEncryption},
          if (attachDeclaration)
            'relationships': {
              'appEncryptionDeclaration': {
                'data': {'type': 'appEncryptionDeclarations', 'id': id},
              },
            },
        },
      },
    );
    final build = appStoreResource(response['data'], 'builds', id: buildId);
    if (build['attributes']?['usesNonExemptEncryption'] !=
        usesNonExemptEncryption) {
      throw StateError(
        'App Store Connect did not confirm export compliance for build $buildId.',
      );
    }
    if (attachDeclaration) {
      final confirmed =
          build['relationships']?['appEncryptionDeclaration']?['data'] ??
          (await client.request(
            'GET',
            '/v1/builds/$buildId/relationships/appEncryptionDeclaration',
            'confirm encryption declaration for build $buildId',
          ))['data'];
      appStoreResource(confirmed, 'appEncryptionDeclarations', id: id);
    }
  }
}
