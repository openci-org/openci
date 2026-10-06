import 'dart:ffi';

import 'package:genuineci_cli/src/asc/asc_release.dart';
import 'package:test/test.dart';

void main() {
  test('selects published assets for each supported OS and CPU', () {
    const targets = {
      Abi.macosArm64: 'macOS_arm64',
      Abi.macosX64: 'macOS_amd64',
      Abi.linuxArm64: 'linux_arm64',
      Abi.linuxX64: 'linux_amd64',
      Abi.windowsX64: 'windows_amd64',
    };
    for (final entry in targets.entries) {
      final release = AscRelease.forAbi(entry.key)!;
      expect(release.target, entry.value);
      expect(release.checksum, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(release.downloadUrl.scheme, 'https');
      expect(release.downloadUrl.host, 'github.com');
      expect(
        release.executableName,
        entry.key == Abi.windowsX64 ? 'asc.exe' : 'asc',
      );
    }
    expect(
      targets.keys.map((abi) => AscRelease.forAbi(abi)!.checksum).toSet(),
      hasLength(targets.length),
    );
  });

  test('does not fall back to an incompatible architecture', () {
    for (final abi in [Abi.windowsArm64, Abi.linuxIA32, Abi.androidArm64]) {
      expect(AscRelease.forAbi(abi), isNull);
    }
  });
}
