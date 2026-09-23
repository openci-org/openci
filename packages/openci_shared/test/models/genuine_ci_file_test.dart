import 'dart:convert';

import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  test('GenuineCIFile preserves the workflow path and source text', () {
    const source = 'void main() {\n  print("CI: テスト");\n}\n';
    final json = {
      'name': 'ci.dart',
      'path': 'genuine_ci/workflows/ci.dart',
      'content': source,
    };

    final file = GenuineCIFile.fromJson(json);

    expect(file.name, 'ci.dart');
    expect(file.path, 'genuine_ci/workflows/ci.dart');
    expect(file.content, source);
    expect(jsonDecode(jsonEncode(file)), json);
  });
}
