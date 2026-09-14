import 'dart:convert';

import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('StepLog', () {
    for (final (description, message) in const [
      ('empty text', ''),
      ('multiline text', 'first\n\n日本語のログ\r\nlast\n'),
      ('JSON-looking text', ' {"stepOrder":1,"message":"確認中"}'),
    ]) {
      test('preserves $description through JSON serialization', () {
        final log = StepLog(message: message);

        expect(log.toJson(), {'message': message});

        final decoded = jsonDecode(jsonEncode(log)) as Map<String, Object?>;
        expect(StepLog.fromJson(decoded).message, message);
      });
    }
  });
}
