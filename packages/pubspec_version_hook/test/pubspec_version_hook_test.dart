import 'dart:io';

import 'package:pubspec_version_hook/pubspec_version_hook.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('pubspec_version_hook_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('successfully syncs version', () async {
    // 1. Create temporary pubspec.yaml
    final pubspecFile = File('${tempDir.path}/pubspec.yaml');
    await pubspecFile.writeAsString('''
name: my_test_package
version: 1.2.3-test
''');

    final dependencies = <Uri>[];

    // 2. Execute core sync logic
    await syncVersionCore(
      packageRoot: tempDir,
      outputRelativePath: 'lib/src/my_version.dart',
      variableName: 'myVersion',
      registerDependency: (uri) => dependencies.add(uri),
    );

    // 3. Verify dependency registration
    expect(dependencies, contains(pubspecFile.uri));

    // 4. Verify generated version.dart contents
    final versionFile = File('${tempDir.path}/lib/src/my_version.dart');
    expect(await versionFile.exists(), isTrue);

    final content = await versionFile.readAsString();
    expect(content, contains("const myVersion = '1.2.3-test';"));
  });

  test('throws if pubspec.yaml does not exist', () async {
    expect(
      () => syncVersionCore(
        packageRoot: tempDir,
        outputRelativePath: 'lib/src/my_version.dart',
        variableName: 'myVersion',
        registerDependency: (_) {},
      ),
      throwsException,
    );
  });

  test('throws if version field is missing', () async {
    final pubspecFile = File('${tempDir.path}/pubspec.yaml');
    await pubspecFile.writeAsString('''
name: my_test_package
''');

    expect(
      () => syncVersionCore(
        packageRoot: tempDir,
        outputRelativePath: 'lib/src/my_version.dart',
        variableName: 'myVersion',
        registerDependency: (_) {},
      ),
      throwsException,
    );
  });
}
