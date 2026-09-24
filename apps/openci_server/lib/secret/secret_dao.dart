import 'package:drift/drift.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/secret/secret_table.dart';

part 'secret_dao.g.dart';

@DriftAccessor(tables: [Secrets])
class SecretDao extends DatabaseAccessor<AppDatabase> with _$SecretDaoMixin {
  SecretDao(super.attachedDatabase);

  Future<List<DriftSecret>> getSecretsForTeam(String teamId) {
    return (select(secrets)..where((t) => t.teamId.equals(teamId))).get();
  }

  Future<DriftSecret?> getSecret(String teamId, String name) {
    return (select(secrets)
          ..where((t) => t.teamId.equals(teamId) & t.name.equals(name)))
        .getSingleOrNull();
  }

  Future<void> insertOrUpdateSecret(DriftSecret secret) {
    return into(secrets).insert(
      secret,
      onConflict: DoUpdate(
        (old) => SecretsCompanion(
          encryptedValue: Value(secret.encryptedValue),
          updatedAt: Value(secret.updatedAt),
        ),
        target: [secrets.teamId, secrets.name],
      ),
    );
  }

  Future<int> deleteSecret(String teamId, String name) {
    return (delete(
      secrets,
    )..where((t) => t.teamId.equals(teamId) & t.name.equals(name))).go();
  }
}
