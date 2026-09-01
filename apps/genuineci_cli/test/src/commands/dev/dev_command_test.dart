import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:test/test.dart';

void main() {
  late CommandRunner<int> runner;

  setUp(() {
    runner = CommandRunner<int>('genuineci', 'CLI tool');
    runner.addCommand(DevCommand(logger: Logger.standard()));
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
