# pubspec_version_hook

A Dart build hook utility (powered by Dart Native Assets) to automatically synchronize the version defined in `pubspec.yaml` to a Dart source file during the build process.

## Usage

1. Add `pubspec_version_hook` as a dependency in your `pubspec.yaml`:
   ```yaml
   dependencies:
     hooks: ^2.0.0
     pubspec_version_hook: ^0.1.0
   ```

2. Create a build hook at `hook/build.dart` in your package:
   ```dart
   import 'package:hooks/hooks.dart';
   import 'package:pubspec_version_hook/pubspec_version_hook.dart';

   void main(List<String> args) async {
     await build(args, (input, output) async {
       await syncPubspecVersion(input, output);
     });
   }
   ```

By default, this will read the version string from your `pubspec.yaml` and output it to `lib/src/version.dart` as a constant named `packageVersion`.

You can customize the output path and variable name:
```dart
await syncPubspecVersion(
  input,
  output,
  outputRelativePath: 'lib/version.g.dart',
  variableName: 'myCustomVersionConst',
);
```
