import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:openci_workflow/src/ios_simulator.dart';
import 'package:test/test.dart';

const deviceId = '12345678-1234-1234-1234-123456789ABC';

void main() {
  group('launchIosSimulator', () {
    late FakeSimctl simctl;

    setUp(() => simctl = FakeSimctl());

    test(
      'uses the newest compatible runtime and waits for boot readiness',
      () async {
        final booted = Completer<ProcessResult>();
        simctl.responses['bootstatus'] = () => booted.future;
        var ready = false;
        final launch = launchIosSimulator(processRunner: simctl.run).then((
          value,
        ) {
          ready = true;
          return value;
        });

        await simctl.bootStarted.future;
        expect(ready, isFalse);
        expect(simctl.commands.first, [
          'create',
          'OpenCI Simulator',
          'iPhone 17 Pro',
        ]);
        expect(simctl.commands.last, ['bootstatus', deviceId, '-b']);
        expect(simctl.timeouts.last, const Duration(minutes: 10));

        booted.complete(ProcessResult(1, 0, '', ''));
        final simulator = await launch;
        expect(simulator.id, deviceId);
        expect(simulator.name, 'OpenCI Simulator');
        await simulator.dispose();
      },
    );

    test(
      'passes explicit device, runtime and name as literal arguments',
      () async {
        const name = r"Patrol's device; $(touch /tmp/should-not-exist)";
        final simulator = await launchIosSimulator(
          name: name,
          device: 'com.apple.CoreSimulator.SimDeviceType.iPhone-16',
          runtime: 'com.apple.CoreSimulator.SimRuntime.iOS-26-3',
          bootTimeout: const Duration(seconds: 45),
          processRunner: simctl.run,
        );
        expect(simctl.commands.first, [
          'create',
          name,
          'com.apple.CoreSimulator.SimDeviceType.iPhone-16',
          'com.apple.CoreSimulator.SimRuntime.iOS-26-3',
        ]);
        expect(simctl.timeouts.last, const Duration(seconds: 45));
        await simulator.dispose();
      },
    );

    test(
      'reports creation failures without touching other simulators',
      () async {
        simctl.responses['create'] = () async => ProcessResult(
          1,
          1,
          '',
          'No compatible runtime is installed.',
        );
        await expectLater(
          launchIosSimulator(processRunner: simctl.run),
          throwsA(
            isA<ProcessException>().having(
              (error) => error.message,
              'message',
              contains('No compatible runtime'),
            ),
          ),
        );
        expect(simctl.commands, hasLength(1));
      },
    );

    for (final invalidId in ['', 'all', 'booted', '$deviceId\nother output']) {
      test('rejects invalid create output: ${jsonEncode(invalidId)}', () async {
        simctl.responses['create'] = () async =>
            ProcessResult(1, 0, invalidId, '');
        await expectLater(
          launchIosSimulator(processRunner: simctl.run),
          throwsStateError,
        );
        expect(simctl.commands, hasLength(1));
      });
    }

    for (final failure in [
      ProcessException('xcrun', const [], 'Boot failed.', 1),
      TimeoutException('Boot timed out.'),
    ]) {
      test('cleans up its device after ${failure.runtimeType}', () async {
        simctl.responses['bootstatus'] = () async => throw failure;
        await expectLater(
          launchIosSimulator(processRunner: simctl.run),
          throwsA(same(failure)),
        );
        expect(simctl.commands.skip(2), [
          ['shutdown', deviceId],
          ['delete', deviceId],
        ]);
      });
    }

    test('preserves the boot failure if cleanup also fails', () async {
      final failure = TimeoutException('Boot timed out.');
      simctl.responses['bootstatus'] = () async => throw failure;
      simctl.responses['delete'] = () async =>
          ProcessResult(1, 2, '', 'Cannot delete.');
      await expectLater(
        launchIosSimulator(processRunner: simctl.run),
        throwsA(same(failure)),
      );
      expect(simctl.commands.last, ['delete', deviceId]);
    });

    test('rejects invalid options before creating a device', () async {
      for (final launch in [
        () => launchIosSimulator(device: ' ', processRunner: simctl.run),
        () => launchIosSimulator(name: '', processRunner: simctl.run),
        () => launchIosSimulator(runtime: '', processRunner: simctl.run),
        () => launchIosSimulator(
          bootTimeout: Duration.zero,
          processRunner: simctl.run,
        ),
        () => launchIosSimulator(
          bootTimeout: const Duration(seconds: -1),
          processRunner: simctl.run,
        ),
      ]) {
        await expectLater(launch(), throwsArgumentError);
      }
      expect(simctl.commands, isEmpty);
    });

    test('dispose is idempotent, including concurrent calls', () async {
      final simulator = await launchIosSimulator(processRunner: simctl.run);
      await Future.wait([simulator.dispose(), simulator.dispose()]);
      await simulator.dispose();
      expect(simctl.commands.skip(2), [
        ['shutdown', deviceId],
        ['delete', deviceId],
      ]);
    });

    for (final shutdownFailure in [
      ProcessResult(1, 149, '', 'Device is already shutdown.'),
      TimeoutException('Shutdown timed out.'),
    ]) {
      test('still deletes after shutdown failure: $shutdownFailure', () async {
        simctl.responses['shutdown'] = () async {
          if (shutdownFailure is ProcessResult) return shutdownFailure;
          throw shutdownFailure;
        };
        final simulator = await launchIosSimulator(processRunner: simctl.run);
        await simulator.dispose();
        expect(simctl.commands.last, ['delete', deviceId]);
      });
    }

    test('failed deletion is reported and can be retried', () async {
      final simulator = await launchIosSimulator(processRunner: simctl.run);
      simctl.responses['delete'] = () async =>
          ProcessResult(1, 1, '', 'Device is busy.');
      await expectLater(simulator.dispose(), throwsA(isA<ProcessException>()));
      simctl.responses.remove('delete');
      await simulator.dispose();
      await simulator.dispose();
      expect(
        simctl.commands.where((args) => args.first == 'delete'),
        hasLength(2),
      );
    });
  });

  group('runSimulatorProcess', () {
    late Directory temp;

    setUp(
      () async =>
          temp = await Directory.systemTemp.createTemp('openci-simctl-test-'),
    );
    tearDown(() async => temp.delete(recursive: true));

    test(
      'captures complete output, exit status and literal arguments',
      () async {
        final script = File('${temp.path}/child.dart');
        await script.writeAsString('''
import 'dart:convert';
import 'dart:io';
void main(List<String> args) {
  stdout.write(jsonEncode(args));
  stderr.write('simctl diagnostic');
  exitCode = 7;
}
''');
        const arguments = [
          'space in argument',
          r'$(touch ignored)',
          "single'quote",
        ];
        final result = await runSimulatorProcess(
          Platform.resolvedExecutable,
          [script.path, ...arguments],
          timeout: const Duration(seconds: 20),
        );
        expect(result.exitCode, 7);
        expect(jsonDecode(result.stdout as String), arguments);
        expect(result.stderr, 'simctl diagnostic');
      },
    );

    test('kills and reaps a timed-out child', () async {
      final script = File('${temp.path}/sleep.dart');
      await script.writeAsString('''
import 'dart:io';
Future<void> main() async {
  stdout.writeln('child-pid=\$pid');
  await Future<void>.delayed(const Duration(minutes: 1));
}
''');
      TimeoutException? timeout;
      try {
        await runSimulatorProcess(
          Platform.resolvedExecutable,
          [script.path],
          timeout: const Duration(seconds: 3),
        );
        fail('Expected timeout.');
      } on TimeoutException catch (error) {
        timeout = error;
      }
      final child = RegExp(r'child-pid=(\d+)').firstMatch(timeout.message!);
      expect(child, isNotNull);
      expect(
        Process.killPid(int.parse(child!.group(1)!), ProcessSignal.sigcont),
        isFalse,
      );
    });
  });
}

class FakeSimctl {
  final commands = <List<String>>[];
  final timeouts = <Duration>[];
  final responses = <String, Future<ProcessResult> Function()>{};
  final bootStarted = Completer<void>();

  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    required Duration timeout,
  }) async {
    expect(executable, 'xcrun');
    expect(arguments.first, 'simctl');
    final command = arguments.sublist(1);
    commands.add(command);
    timeouts.add(timeout);
    if (command.first == 'bootstatus') bootStarted.complete();
    final response = responses[command.first];
    if (response != null) return response();
    return ProcessResult(
      1,
      0,
      command.first == 'create' ? '$deviceId\n' : '',
      '',
    );
  }
}
