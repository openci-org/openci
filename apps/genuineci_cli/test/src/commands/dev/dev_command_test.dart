import 'package:args/command_runner.dart';
import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:test/test.dart';

void main() {
  late CommandRunner<int> runner;

  setUp(() {
    runner = CommandRunner<int>('genuineci', 'CLI tool');
    runner.addCommand(DevCommand());
  });

  test('dev command is registered with name dev and valid description', () {
    final devCommand = runner.commands['dev'];
    expect(devCommand, isNotNull);
    expect(devCommand!.name, equals('dev'));
    expect(devCommand.description, isNotEmpty);
  });
}
