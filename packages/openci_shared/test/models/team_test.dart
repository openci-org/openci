import 'dart:convert';

import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('Team JSON', () {
    test('uses defaults when optional settings are omitted', () {
      final team = Team.fromJson(_teamJson());

      expect(team.id, 'team-1');
      expect(team.name, 'OpenCI');
      expect(team.members, ['user-1']);
      expect(team.installationIds, isEmpty);
      expect(team.runNumber, 1);
      expect(team.aiEnabled, isTrue);
      expect(team.toJson(), isNot(contains('githubBaseUrl')));
      expect(team.createdAt, DateTime.utc(2026, 9, 7));
      expect(team.updatedAt, DateTime.utc(2026, 9, 7, 0, 1));
    });

    test('preserves GitHub settings, run number, and disabled AI', () {
      final json = {
        ..._teamJson(),
        'installationIds': [12345, 67890],
        'runNumber': 42,
        'aiEnabled': false,
      };

      final team = Team.fromJson(json);

      expect(team.installationIds, [12345, 67890]);
      expect(team.runNumber, 42);
      expect(team.aiEnabled, isFalse);
      expect(jsonDecode(jsonEncode(team)), json);
    });

    test('ignores the removed GitHub URL in older responses', () {
      final team = Team.fromJson({
        ..._teamJson(),
        'githubBaseUrl': 'https://untrusted.example',
      });

      expect(team, Team.fromJson(_teamJson()));
      expect(team.toJson(), isNot(contains('githubBaseUrl')));
    });
  });
}

Map<String, Object?> _teamJson() => {
  'id': 'team-1',
  'name': 'OpenCI',
  'members': ['user-1'],
  'createdAt': '2026-09-07T00:00:00.000Z',
  'updatedAt': '2026-09-07T00:01:00.000Z',
};
