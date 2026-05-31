import 'package:avf_dart/avf_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Apple Virtualization Framework Bindings Test', () {
    setUpAll(() {
      // macOS Virtualization.framework を動的ロードしてObjective-C runtimeにシンボルを登録する
      DynamicLibrary.open(
        '/System/Library/Frameworks/Virtualization.framework/Virtualization',
      );
    });

    test('VZVirtualMachine.getIsSupported returns a boolean value without throwing', () {
      final isSupported = VZVirtualMachine.getIsSupported();
      print('=== AVF VZVirtualMachine.isSupported: $isSupported ===');
      
      expect(isSupported, isA<bool>());
    });
  });
}
