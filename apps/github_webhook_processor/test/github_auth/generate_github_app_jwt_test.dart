import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:github_webhook_processor/github_webhook_processor.dart';
import 'package:test/test.dart';

const testRsaPrivateKey = '''
-----BEGIN PRIVATE KEY-----
MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBANiAAR187atVXowj
f+vCsYaoXkXkaxt1TPYiEa6r8NY1no2sQUa1X281FhNdYFlsCjAot4OBgGKe6GHx
R/qL2ifaSReCAf8DpqDi6SMMOjg+Owrya44E0Ld/SEVHyDy8PnLTmI2ijydhptjK
slf33COCWnIE88OQutWM3/OyMkrRAgMBAAECgYEAg/2OMH8gmusiCEgATijVeGYf
i3bVwdjCwfBFXXtgCgiIkJDq/wPGmhMAUXAFNJ9EmtXIA/mo3vdIb6XdHyeyKKi9
LRly8gHlowdJ5HTbjrBCJlpPTG/Hxo1+3Q+W50240LyuZLByOy7AABr86bIq8Xxo
F4U13aHYhPkI15pvEt0CQQDuLZvZ1i7JZB/KfUhM3pgsnApFxRFcGCwOG7bVXAM5
+fkLnAENP/yWzawD/HOctDxzQ7qdcSWlx0Ux2Ww9n4nDAkEA6LMkhxcnVAM7y6aQ
u6eKcHSJxDmFbHJoxVyyVlVynL9qDgKTckZvvzLopgBo7VawsqyC0YV7XZTxgsvV
wzK72wJAJjBR6N+aqNfQ8RqdWRXnuF9clks+uVF23tw6uIMEUWtvLxlYYdN8oIFh
r1HvB5UujByz80KNEsOcqJ1/6XGHGQJBANzLXhVwOrjUeKA7Y4kq54jcivvNOHQ1
+oOJ+Q1B9oYUeaThfNYpT060F1urd+P7JZ3jYh078lpRQPdCQYn9UZECQENnF2pp
Gl92V3wIHINZYD6o97L+/6Cw3H7TvkikX3bQf1vKy4P7+rE89jEAgA0jrMWPu6WG
Vtdh93Euj6RHtUE=
-----END PRIVATE KEY-----
''';

void main() {
  group('generateGitHubAppJwt', () {
    test('generates valid JWT with expected claims', () {
      final beforeSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final token = generateGitHubAppJwt(
        appId: '12345',
        privateKeyPem: testRsaPrivateKey,
      );

      final afterSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      expect(token, isNotEmpty);

      // Unverified decode to inspect payload
      final jwt = JWT.decode(token);
      final payload = jwt.payload as Map<String, dynamic>;

      expect(payload['iss'], equals(12345));

      final iat = payload['iat'] as int;
      final exp = payload['exp'] as int;

      expect(iat, greaterThanOrEqualTo(beforeSeconds - 60));
      expect(iat, lessThanOrEqualTo(afterSeconds - 60));
      expect(exp - iat, equals(600)); // 10 minutes total validity
    });

    test('throws FormatException for non-integer appId', () {
      expect(
        () => generateGitHubAppJwt(
          appId: 'invalid-app-id',
          privateKeyPem: testRsaPrivateKey,
        ),
        throwsFormatException,
      );
    });
  });
}
