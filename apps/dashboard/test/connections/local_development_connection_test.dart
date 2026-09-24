import 'package:dashboard/connections/local_development_connection.dart';
import 'package:flutter_test/flutter_test.dart';

LocalDevelopmentConnection? parse({
  String mode = 'true',
  String apiUrl = 'http://127.0.0.1:8080',
  String emulatorHost = '127.0.0.1',
  String emulatorPort = '9099',
}) => LocalDevelopmentConnection.parse(
  mode: mode,
  apiUrl: apiUrl,
  emulatorHost: emulatorHost,
  emulatorPort: emulatorPort,
);

void main() {
  test('local launch supplies demo options for every Dashboard platform', () {
    final local = parse()!;

    expect(local.profile.id, localDevelopmentProfileId);
    expect(local.profile.apiUrl, 'http://127.0.0.1:8080');
    expect(local.emulatorHost, '127.0.0.1');
    expect(local.emulatorPort, 9099);
    expect(local.profile.firebase.keys, {
      'web',
      'ios',
      'android',
      'macos',
    });
    for (final options in local.profile.firebase.values) {
      expect(options.projectId, 'demo-openci');
      expect(options.apiKey, isNotEmpty);
      expect(options.appId, isNotEmpty);
    }
  });

  test('normal launches do not create a local connection', () {
    expect(
      parse(mode: '', apiUrl: '', emulatorHost: '', emulatorPort: ''),
      isNull,
    );
    expect(
      parse(mode: 'false', apiUrl: '', emulatorHost: '', emulatorPort: ''),
      isNull,
    );
  });

  test('partial or invalid local settings fail without a Cloud fallback', () {
    expect(() => parse(mode: 'yes'), throwsStateError);
    expect(() => parse(mode: 'false'), throwsStateError);
    expect(() => parse(apiUrl: ''), throwsStateError);
    expect(
      () => parse(apiUrl: 'https://production.example.com'),
      throwsStateError,
    );
    expect(
      () => parse(apiUrl: 'http://localhost:8080/extra'),
      throwsStateError,
    );
    expect(() => parse(emulatorHost: ''), throwsStateError);
    expect(() => parse(emulatorHost: 'http://localhost'), throwsStateError);
    expect(() => parse(emulatorHost: 'localhost:9099'), throwsStateError);
    expect(() => parse(emulatorPort: ''), throwsStateError);
    expect(() => parse(emulatorPort: '0'), throwsStateError);
    expect(() => parse(emulatorPort: '65536'), throwsStateError);
  });

  test('device host overrides keep the same project', () {
    final android = parse(
      apiUrl: 'http://10.0.2.2:8080',
      emulatorHost: '10.0.2.2',
    )!;
    expect(android.profile.apiUrl, 'http://10.0.2.2:8080');
    expect(android.emulatorHost, '10.0.2.2');
    expect(android.profile.firebase['android']!.projectId, 'demo-openci');
  });
}
