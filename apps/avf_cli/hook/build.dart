import 'package:hooks/hooks.dart';
import 'package:pubspec_version_hook/pubspec_version_hook.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    await syncPubspecVersion(input, output);
  });
}
