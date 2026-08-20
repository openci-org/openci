import 'package:genuine_ci/genuine_ci.dart';
import 'package:test/test.dart';

void main() {
  group('CiTrigger', () {
    test('CiTrigger.push creates push trigger with branch', () {
      const trigger = CiTrigger.push(branch: 'develop');
      expect(trigger.branch, 'develop');
      expect(trigger, isA<CiTrigger>());
    });

    test('CiTrigger.pullRequest creates pullRequest trigger with branch', () {
      const trigger = CiTrigger.pullRequest(branch: 'main');
      expect(trigger.branch, 'main');
      expect(trigger, isA<CiTrigger>());
    });
  });
}
