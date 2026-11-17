import 'package:flutter_test/flutter_test.dart';

import '../../tool/configure_google_sign_in.dart';

void main() {
  const options = '''
  static const FirebaseOptions ios = FirebaseOptions(
    iosClientId: '123-ios.apps.googleusercontent.com',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    iosClientId: '123-macos.apps.googleusercontent.com',
  );
  ''';

  test('native callback schemes use each platform OAuth client', () {
    for (final platform in ['ios', 'macos']) {
      final config = googleSignInXcconfig(options, platform);
      expect(
        config,
        contains(
          'OPENCI_GOOGLE_CLIENT_ID = 123-$platform.apps.googleusercontent.com',
        ),
      );
      expect(
        config,
        contains(
          'OPENCI_GOOGLE_REVERSED_CLIENT_ID = com.googleusercontent.apps.123-$platform',
        ),
      );
    }
  });

  test('release preparation fails when Google is not configured', () {
    expect(() => googleSignInXcconfig('', 'macos'), throwsStateError);
    expect(
      () =>
          googleSignInXcconfig(options.replaceAll('123-ios', 'invalid'), 'ios'),
      throwsStateError,
    );
  });
}
