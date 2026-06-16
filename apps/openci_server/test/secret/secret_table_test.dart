import 'package:openci_server/secret/secret_table.dart';
import 'package:test/test.dart';

void main() {
  group('DriftSecret Custom Row Class Tests', () {
    test('toString() redacts encryptedValue', () {
      final now = DateTime.now();
      final secret = DriftSecret(
        name: 'MY_SECRET',
        teamId: 'team_1',
        encryptedValue: 'super_secret_raw_value',
        createdAt: now,
        updatedAt: now,
      );

      final str = secret.toString();
      expect(str, contains('[REDACTED]'));
      expect(str, isNot(contains('super_secret_raw_value')));
    });

    test('toJson() redacts encryptedValue', () {
      final now = DateTime.now();
      final secret = DriftSecret(
        name: 'MY_SECRET',
        teamId: 'team_1',
        encryptedValue: 'super_secret_raw_value',
        createdAt: now,
        updatedAt: now,
      );

      final json = secret.toJson();
      expect(json['encryptedValue'], equals('[REDACTED]'));
      expect(json['name'], equals('MY_SECRET'));
      expect(json['teamId'], equals('team_1'));
    });
  });
}
