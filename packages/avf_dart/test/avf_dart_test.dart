import 'package:avf_dart/avf_dart.dart';
import 'package:test/test.dart';

void main() {
  group('VirtualMachine API Test', () {
    test('defaultVmsDir returns a valid path', () {
      final path = VirtualMachine.defaultVmsDir;
      expect(path, isNotEmpty);
      expect(path, contains('avf_dart/vms'));
    });
  });
}
