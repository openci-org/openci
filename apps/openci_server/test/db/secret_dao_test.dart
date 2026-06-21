import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/secret/secret_table.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.teams)
        .insert(
          DriftTeam(
            id: 'team-123',
            name: 'Test Team',
            installationIds: const [],
            aiEnabled: false,
            runNumber: 1,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('SecretDao', () {
    test('Can insert, get, and delete secrets', () async {
      final now = DateTime.now().toUtc();
      final secret = DriftSecret(
        name: 'API_KEY',
        teamId: 'team-123',
        encryptedValue: 'encrypted_value_123',
        createdAt: now,
        updatedAt: now,
      );

      await db.secretDao.insertOrUpdateSecret(secret);

      // Get secrets for team
      final list = await db.secretDao.getSecretsForTeam('team-123');
      expect(list, hasLength(1));
      expect(list.first.name, 'API_KEY');

      // Get single secret
      final retrieved = await db.secretDao.getSecret('team-123', 'API_KEY');
      expect(retrieved, isNotNull);
      expect(retrieved!.encryptedValue, 'encrypted_value_123');

      // Delete secret
      final deletedCount = await db.secretDao.deleteSecret(
        'team-123',
        'API_KEY',
      );
      expect(deletedCount, 1);

      final retrievedAfterDelete = await db.secretDao.getSecret(
        'team-123',
        'API_KEY',
      );
      expect(retrievedAfterDelete, isNull);
    });

    test(
      'insertOrUpdateSecret preserves createdAt and updates updatedAt and value on conflict',
      () async {
        final fiveMinutesAgo = DateTime.now().toUtc().subtract(
          const Duration(minutes: 5),
        );
        final originalSecret = DriftSecret(
          name: 'API_KEY',
          teamId: 'team-123',
          encryptedValue: 'old_value',
          createdAt: fiveMinutesAgo,
          updatedAt: fiveMinutesAgo,
        );

        // Insert original
        await db.secretDao.insertOrUpdateSecret(originalSecret);

        final now = DateTime.now().toUtc();
        final updatedSecret = DriftSecret(
          name: 'API_KEY',
          teamId: 'team-123',
          encryptedValue: 'new_value',
          createdAt: now, // different createdAt
          updatedAt: now,
        );

        // Upsert
        await db.secretDao.insertOrUpdateSecret(updatedSecret);

        // Retrieve and verify
        final retrieved = await db.secretDao.getSecret('team-123', 'API_KEY');
        expect(retrieved, isNotNull);
        expect(retrieved!.encryptedValue, equals('new_value'));

        // createdAt MUST remain fiveMinutesAgo (preserved)
        expect(
          retrieved.createdAt.difference(fiveMinutesAgo).inSeconds.abs(),
          lessThan(2),
        );

        // updatedAt MUST be updated to now
        expect(
          retrieved.updatedAt.difference(now).inSeconds.abs(),
          lessThan(2),
        );
      },
    );
  });
}
