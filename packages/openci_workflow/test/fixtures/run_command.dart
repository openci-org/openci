import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';

Future<void> main(List<String> arguments) =>
    runCommand(arguments.single, workingDirectory: Directory.current.path);
