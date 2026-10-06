import 'dart:ffi';

// Release assets and SHA-256 values from:
// https://github.com/rorkai/App-Store-Connect-CLI/releases/tag/5.11.0
// Keep the version, checksums and license in sync when updating asc.
class AscRelease {
  static const version = '5.11.0';

  const AscRelease({required this.target, required this.checksum});

  final String target;
  final String checksum;

  bool get isWindows => target == 'windows_amd64';
  String get executableName => isWindows ? 'asc.exe' : 'asc';

  Uri get downloadUrl => Uri.https(
    'github.com',
    '/rorkai/App-Store-Connect-CLI/releases/download/'
        '$version/asc_${version}_$target${isWindows ? '.exe' : ''}',
  );

  static AscRelease? forAbi(Abi abi) => switch (abi) {
    Abi.macosArm64 => const AscRelease(
      target: 'macOS_arm64',
      checksum:
          '180f77a17dd81a4392bd4a8055d5544918961a0c3ea9bc184a1b16b8aaf1695e',
    ),
    Abi.macosX64 => const AscRelease(
      target: 'macOS_amd64',
      checksum:
          'f556769589bb9de8a10d711e4fe4b654203b316bd24cc4eaf9d765b955167287',
    ),
    Abi.linuxArm64 => const AscRelease(
      target: 'linux_arm64',
      checksum:
          'c0631fa59ed7401170768917c21ac4a6fe2838e69dc5a9d88dfa3658b847b9e9',
    ),
    Abi.linuxX64 => const AscRelease(
      target: 'linux_amd64',
      checksum:
          '7d32d4256d7b5f3aa5c89c7e0370c04e17586b75e345dca6fde36f6f005c7fd4',
    ),
    Abi.windowsX64 => const AscRelease(
      target: 'windows_amd64',
      checksum:
          '8532971abef309c537192418624383f50aed85a642eb2181945e085dc0f5ab3c',
    ),
    _ => null,
  };
}
