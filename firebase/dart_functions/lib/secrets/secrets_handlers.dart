import 'dart:io';

import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/firestore_paths.dart';
import 'package:uuid/uuid.dart';

import '../firebase.dart';
import '../secret_manager.dart';
import '../util/logger.dart';
import '../util/team_auth.dart';

// ---------------------------------------------------------------------------
// Request models
// ---------------------------------------------------------------------------

class CreateSecretRequest {
  const CreateSecretRequest({
    required this.name,
    required this.value,
    required this.teamId,
  });

  factory CreateSecretRequest.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    final value = json['value'] as String?;
    final teamId = json['teamId'] as String?;
    if (name == null ||
        name.isEmpty ||
        value == null ||
        value.isEmpty ||
        teamId == null ||
        teamId.isEmpty) {
      throw InvalidArgumentError('Missing name, value, or teamId');
    }
    return CreateSecretRequest(name: name, value: value, teamId: teamId);
  }

  final String name;
  final String value;
  final String teamId;
}

class DeleteSecretRequest {
  const DeleteSecretRequest({required this.documentId, required this.teamId});

  factory DeleteSecretRequest.fromJson(Map<String, dynamic> json) {
    final documentId = json['documentId'] as String?;
    final teamId = json['teamId'] as String?;
    if (documentId == null ||
        documentId.isEmpty ||
        teamId == null ||
        teamId.isEmpty) {
      throw InvalidArgumentError('Missing documentId or teamId');
    }
    return DeleteSecretRequest(documentId: documentId, teamId: teamId);
  }

  final String documentId;
  final String teamId;
}

class UpdateSecretRequest {
  const UpdateSecretRequest({
    required this.documentId,
    required this.name,
    required this.teamId,
    this.value,
  });

  factory UpdateSecretRequest.fromJson(Map<String, dynamic> json) {
    final documentId = json['documentId'] as String?;
    final name = json['name'] as String?;
    final teamId = json['teamId'] as String?;
    if (documentId == null ||
        documentId.isEmpty ||
        name == null ||
        name.isEmpty ||
        teamId == null ||
        teamId.isEmpty) {
      throw InvalidArgumentError('Missing documentId, name, or teamId');
    }
    return UpdateSecretRequest(
      documentId: documentId,
      name: name,
      teamId: teamId,
      value: json['value'] as String?,
    );
  }

  final String documentId;
  final String name;
  final String teamId;
  final String? value;
}

class GenerateCertificateKeyRequest {
  const GenerateCertificateKeyRequest({required this.teamId});

  factory GenerateCertificateKeyRequest.fromJson(Map<String, dynamic> json) {
    final teamId = json['teamId'] as String?;
    if (teamId == null || teamId.isEmpty) {
      throw InvalidArgumentError('Missing teamId');
    }
    return GenerateCertificateKeyRequest(teamId: teamId);
  }

  final String teamId;
}

class SetupAscApiKeyRequest {
  const SetupAscApiKeyRequest({
    required this.teamId,
    required this.issuerId,
    required this.keyId,
    required this.privateKey,
  });

  factory SetupAscApiKeyRequest.fromJson(Map<String, dynamic> json) {
    final teamId = json['teamId'] as String?;
    final issuerId = json['issuerId'] as String?;
    final keyId = json['keyId'] as String?;
    final privateKey = json['privateKey'] as String?;
    if (teamId == null ||
        teamId.isEmpty ||
        issuerId == null ||
        issuerId.isEmpty ||
        keyId == null ||
        keyId.isEmpty ||
        privateKey == null ||
        privateKey.isEmpty) {
      throw InvalidArgumentError('Missing required fields');
    }
    return SetupAscApiKeyRequest(
      teamId: teamId,
      issuerId: issuerId,
      keyId: keyId,
      privateKey: privateKey,
    );
  }

  final String teamId;
  final String issuerId;
  final String keyId;
  final String privateKey;
}

// ---------------------------------------------------------------------------
// Handlers
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> handleCreateSecret(
  CallableRequest<CreateSecretRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  await verifyTeamMembership(auth: request.auth, teamId: request.data.teamId);

  final name = request.data.name;
  final teamId = request.data.teamId;

  // Check for duplicate name
  final duplicateCheck = await firestore
      .collection(secretsCollection)
      .where('teamId', WhereFilter.equal, teamId)
      .where('name', WhereFilter.equal, name)
      .limit(1)
      .get();

  if (duplicateCheck.docs.isNotEmpty) {
    throw AlreadyExistsError('Secret with name "$name" already exists');
  }

  try {
    final secretId = const Uuid().v4();
    final pathToSecret = await createSecretWithValue(
      secretId,
      request.data.value,
    );

    final documentId = const Uuid().v4();
    final now = DateTime.now().toUtc().toIso8601String();

    await firestore.collection(secretsCollection).doc(documentId).set({
      'id': documentId,
      'name': name,
      'teamId': teamId,
      'pathToSecret': pathToSecret,
      'createdAt': now,
      'updatedAt': now,
    });

    logInfo('Secret created: $secretId', {'teamId': teamId, 'name': name});
    return <String, dynamic>{'success': true, 'documentId': documentId};
  } catch (e) {
    logError('Failed to create secret', null, e);
    throw InternalError('Failed to create secret: $e');
  }
}

Future<Map<String, dynamic>> handleDeleteSecret(
  CallableRequest<DeleteSecretRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  await verifyTeamMembership(auth: request.auth, teamId: request.data.teamId);

  final documentId = request.data.documentId;
  final teamId = request.data.teamId;

  final secretRef = firestore.collection(secretsCollection).doc(documentId);
  final secretDoc = await secretRef.get();

  if (!secretDoc.exists) {
    throw NotFoundError('Secret not found');
  }

  final secretData = secretDoc.data()!;
  if (secretData['teamId'] != teamId) {
    throw PermissionDeniedError('Secret does not belong to this team');
  }

  try {
    final pathToSecret = secretData['pathToSecret'] as String?;
    if (pathToSecret != null && pathToSecret.isNotEmpty) {
      try {
        await deleteSecretByPath(pathToSecret);
      } catch (e) {
        logWarning('Failed to delete from Secret Manager: $e', {
          'pathToSecret': pathToSecret,
        });
      }
    }

    await secretRef.delete();
    logInfo('Secret deleted: $documentId', {
      'teamId': teamId,
      'name': secretData['name'],
    });
    return <String, dynamic>{'success': true};
  } catch (e) {
    if (e is HttpsError) rethrow;
    logError('Failed to delete secret', null, e);
    throw InternalError('Failed to delete secret: $e');
  }
}

Future<Map<String, dynamic>> handleUpdateSecret(
  CallableRequest<UpdateSecretRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  await verifyTeamMembership(auth: request.auth, teamId: request.data.teamId);

  final documentId = request.data.documentId;
  final name = request.data.name;
  final teamId = request.data.teamId;

  final secretRef = firestore.collection(secretsCollection).doc(documentId);
  final secretDoc = await secretRef.get();

  if (!secretDoc.exists) {
    throw NotFoundError('Secret not found');
  }

  final secretData = secretDoc.data()!;
  if (secretData['teamId'] != teamId) {
    throw PermissionDeniedError('Secret does not belong to this team');
  }

  final oldName = secretData['name'] as String;

  // Check for duplicate name (only if name is being changed)
  if (name != oldName) {
    final duplicateCheck = await firestore
        .collection(secretsCollection)
        .where('teamId', WhereFilter.equal, teamId)
        .where('name', WhereFilter.equal, name)
        .limit(1)
        .get();

    if (duplicateCheck.docs.isNotEmpty) {
      throw AlreadyExistsError('Secret with name "$name" already exists');
    }
  }

  try {
    // Update secret value in Secret Manager if a new value is provided
    if (request.data.value != null) {
      final pathToSecret = secretData['pathToSecret'] as String;
      await addSecretVersionByPath(pathToSecret, request.data.value!);
      logInfo('Secret value updated for: $documentId', {
        'teamId': teamId,
        'name': name,
      });
    }

    // Update Firestore document
    final now = DateTime.now().toUtc().toIso8601String();
    await secretRef.update({'name': name, 'updatedAt': now});

    // If name changed, update all workflows that reference this secret
    if (name != oldName) {
      final workflowsSnapshot = await firestore
          .collection(workflowsCollection)
          .where('teamId', WhereFilter.equal, teamId)
          .get();

      for (final workflowDoc in workflowsSnapshot.docs) {
        final workflowData = workflowDoc.data();
        final steps = workflowData['workflowSteps'] as List<dynamic>? ?? [];
        var hasChanges = false;

        final updatedSteps = steps.map((step) {
          final stepMap = step as Map<String, dynamic>;
          final requiredSecrets =
              stepMap['requiredSecrets'] as List<dynamic>? ?? [];
          final updatedSecrets = requiredSecrets.map((secret) {
            final secretMap = secret as Map<String, dynamic>;
            if (secretMap['secretDocumentId'] == documentId) {
              hasChanges = true;
              return {...secretMap, 'key': name};
            }
            return secretMap;
          }).toList();
          return {...stepMap, 'requiredSecrets': updatedSecrets};
        }).toList();

        if (hasChanges) {
          await workflowDoc.ref.update({'workflowSteps': updatedSteps});
        }
      }
    }

    logInfo('Secret updated: $documentId', {'teamId': teamId, 'name': name});
    return <String, dynamic>{'success': true};
  } catch (e) {
    if (e is HttpsError) rethrow;
    logError('Failed to update secret', null, e);
    throw InternalError('Failed to update secret: $e');
  }
}

Future<Map<String, dynamic>> handleGenerateCertificateKey(
  CallableRequest<GenerateCertificateKeyRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  await verifyTeamMembership(auth: request.auth, teamId: request.data.teamId);

  final teamId = request.data.teamId;
  const secretName = 'OPENCI_CERTIFICATE_PRIVATE_KEY';

  final duplicateCheck = await firestore
      .collection(secretsCollection)
      .where('teamId', WhereFilter.equal, teamId)
      .where('name', WhereFilter.equal, secretName)
      .limit(1)
      .get();

  if (duplicateCheck.docs.isNotEmpty) {
    throw AlreadyExistsError(
      'Secret "$secretName" already exists. Delete the existing one first to regenerate.',
    );
  }

  try {
    // Generate RSA key pair using openssl process
    final result = await _generateRsaPrivateKey();

    final secretId = const Uuid().v4();
    final pathToSecret = await createSecretWithValue(secretId, result);

    final documentId = const Uuid().v4();
    final now = DateTime.now().toUtc().toIso8601String();

    await firestore.collection(secretsCollection).doc(documentId).set({
      'id': documentId,
      'name': secretName,
      'teamId': teamId,
      'pathToSecret': pathToSecret,
      'createdAt': now,
      'updatedAt': now,
    });

    logInfo('Certificate key generated: $secretId', {
      'teamId': teamId,
      'secretName': secretName,
    });
    return <String, dynamic>{'success': true, 'documentId': documentId};
  } catch (e) {
    if (e is HttpsError) rethrow;
    logError('Failed to generate certificate key', null, e);
    throw InternalError('Failed to generate certificate key: $e');
  }
}

Future<Map<String, dynamic>> handleSetupAscApiKey(
  CallableRequest<SetupAscApiKeyRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  await verifyTeamMembership(auth: request.auth, teamId: request.data.teamId);

  final teamId = request.data.teamId;
  const ascSecretNames = [
    'OPENCI_ASC_ISSUER_ID',
    'OPENCI_ASC_KEY_ID',
    'OPENCI_ASC_PRIVATE_KEY',
  ];

  final existingSecrets = await firestore
      .collection(secretsCollection)
      .where('teamId', WhereFilter.equal, teamId)
      .where('name', WhereFilter.isIn, ascSecretNames)
      .get();

  if (existingSecrets.docs.isNotEmpty) {
    final existingNames = existingSecrets.docs
        .map((doc) => doc.data()['name'])
        .toList();
    throw AlreadyExistsError(
      'ASC API Key secrets already exist: ${existingNames.join(", ")}. Delete them first to reconfigure.',
    );
  }

  try {
    final values = {
      'OPENCI_ASC_ISSUER_ID': request.data.issuerId,
      'OPENCI_ASC_KEY_ID': request.data.keyId,
      'OPENCI_ASC_PRIVATE_KEY': request.data.privateKey,
    };

    final results = <String, String>{};

    for (final entry in values.entries) {
      final secretId = const Uuid().v4();
      final pathToSecret = await createSecretWithValue(secretId, entry.value);

      final documentId = const Uuid().v4();
      final now = DateTime.now().toUtc().toIso8601String();

      await firestore.collection(secretsCollection).doc(documentId).set({
        'id': documentId,
        'name': entry.key,
        'teamId': teamId,
        'pathToSecret': pathToSecret,
        'createdAt': now,
        'updatedAt': now,
      });

      results[entry.key] = documentId;
    }

    logInfo('ASC API Key setup complete', {
      'teamId': teamId,
      'secrets': results.keys.toList(),
    });
    return <String, dynamic>{'success': true, 'documentIds': results};
  } catch (e) {
    if (e is HttpsError) rethrow;
    logError('Failed to setup ASC API Key', null, e);
    throw InternalError('Failed to setup ASC API Key: $e');
  }
}

/// Generates a 2048-bit RSA private key using `openssl` subprocess.
Future<String> _generateRsaPrivateKey() async {
  final result = await Process.run('openssl', [
    'genpkey',
    '-algorithm',
    'RSA',
    '-pkeyopt',
    'rsa_keygen_bits:2048',
  ]);

  if (result.exitCode != 0) {
    throw InternalError('openssl failed: ${result.stderr}');
  }

  return result.stdout as String;
}
