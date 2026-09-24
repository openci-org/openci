import 'package:openci_cli/openci_cli.dart';
import 'package:test/test.dart';

void main() {
  late OpenCICommandRunner runner;

  setUp(() {
    runner = OpenCICommandRunner();
  });

  test('dev command is registered with name dev and valid description', () {
    final devCommand = runner.commands['dev'];
    expect(devCommand, isNotNull);
    expect(devCommand!.name, equals('dev'));
    expect(devCommand.description, isNotEmpty);
  });

  test('dev contains start subcommand', () {
    final startCommand = runner.commands['dev']!.subcommands['start'];
    expect(startCommand, isNotNull);
    expect(startCommand!.name, equals('start'));
    expect(startCommand.description, isNotEmpty);
  });
}
