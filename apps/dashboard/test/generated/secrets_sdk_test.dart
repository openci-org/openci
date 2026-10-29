import 'package:dashboard/generated/secrets/secrets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('secret metadata preserves Int64 timestamps without exposing paths', () {
    final data = GetSecretsData.fromJson({
      'secrets': [
        {
          'teamId': 'team',
          'name': 'TOKEN',
          'createdAt': '9007199254740992',
          'updatedAt': '9007199254740993',
        },
      ],
    });

    final secret = data.secrets.single;
    expect(secret.createdAt, BigInt.parse('9007199254740992'));
    expect(secret.updatedAt, BigInt.parse('9007199254740993'));
    expect(
      secret.toJson().keys,
      unorderedEquals([
        'teamId',
        'name',
        'createdAt',
        'updatedAt',
      ]),
    );
    expect(secret.toJson()['updatedAt'], '9007199254740993');
  });

  test(
    'an empty list and an absent server reference deserialize correctly',
    () {
      expect(GetSecretsData.fromJson({'secrets': []}).secrets, isEmpty);
      expect(
        GetSecretReferenceData.fromJson({
          'secretReference': null,
        }).secretReference,
        isNull,
      );
    },
  );
}
