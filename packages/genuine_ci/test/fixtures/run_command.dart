import 'dart:io';

import 'package:genuine_ci/genuine_ci.dart';

Future<void> main(List<String> arguments) =>
    runCommand(arguments.single, workingDirectory: Directory.current.path);
