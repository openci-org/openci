import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

/// A fresh iOS Simulator owned by the workflow that created it.
class IosSimulator {
  IosSimulator._(this.id, this.name, this._processRunner);

  /// The device UDID, suitable for Flutter's or Patrol's `--device` argument.
  final String id;
  final String name;
  final SimulatorProcessRunner _processRunner;
  Future<void>? _disposal;

  /// Installs a built app bundle on this simulator, allowing up to five minutes.
  Future<void> installApp(Directory app) async {
    stdout.writeln('Installing app on iOS simulator $id.');
    final elapsed = Stopwatch()..start();
    await _simctl(
      _processRunner,
      ['install', id, app.absolute.path],
      timeout: const Duration(minutes: 5),
    );
    stdout.writeln('Installed app on iOS simulator $id in ${elapsed.elapsed}.');
  }

  /// Resolves the installed app's current data container.
  Future<Directory> appDataDirectory(String bundleId) async => Directory(
    (await _simctl(_processRunner, [
      'get_app_container',
      id,
      bundleId,
      'data',
    ])).trim(),
  );

  /// Shuts down and deletes only this simulator. Repeated calls are safe.
  ///
  /// A failed deletion can be retried by calling [dispose] again.
  Future<void> dispose() =>
      _disposal ??= _dispose().onError<Object>((error, stack) {
        _disposal = null;
        Error.throwWithStackTrace(error, stack);
      });

  Future<void> _dispose() async {
    try {
      await _simctl(_processRunner, ['shutdown', id]);
    } catch (_) {
      // Already stopped or partially booted devices can still be deleted.
    }
    await _simctl(_processRunner, ['delete', id]);
    stdout.writeln('Deleted iOS simulator $id.');
  }
}

/// Implementation of OpenCI.launchIosSimulator, with a testable process runner.
Future<IosSimulator> launchIosSimulator({
  String device = 'iPhone 17 Pro',
  String name = 'OpenCI Simulator',
  String? runtime,
  Duration bootTimeout = const Duration(minutes: 10),
  @visibleForTesting SimulatorProcessRunner processRunner = runSimulatorProcess,
}) async {
  for (final entry in {
    'device': device,
    'name': name,
    'runtime': runtime,
  }.entries) {
    if (entry.value != null && entry.value!.trim().isEmpty) {
      throw ArgumentError.value(entry.value, entry.key, 'Must not be empty.');
    }
  }
  if (bootTimeout <= Duration.zero) {
    throw ArgumentError.value(bootTimeout, 'bootTimeout', 'Must be positive.');
  }

  // Without a runtime, simctl selects the newest installed compatible one.
  final id = (await _simctl(processRunner, [
    'create',
    name,
    device,
    ?runtime,
  ])).trim();
  if (!RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(id)) {
    throw StateError('simctl create did not return a valid device UDID: $id');
  }

  final simulator = IosSimulator._(id, name, processRunner);
  stdout.writeln('Created iOS simulator $id ($device). Waiting for startup...');
  try {
    await _simctl(processRunner, [
      'bootstatus',
      id,
      '-b',
    ], timeout: bootTimeout);
    stdout.writeln('iOS simulator $id is ready.');
    return simulator;
  } catch (_) {
    try {
      await simulator.dispose();
    } catch (cleanupError) {
      stderr.writeln('Could not delete iOS simulator $id: $cleanupError');
    }
    rethrow;
  }
}

Future<String> _simctl(
  SimulatorProcessRunner run,
  List<String> arguments, {
  Duration timeout = const Duration(minutes: 1),
}) async {
  final commandArguments = ['simctl', ...arguments];
  final result = await run('xcrun', commandArguments, timeout: timeout);
  if (result.exitCode != 0) {
    throw ProcessException(
      'xcrun',
      commandArguments,
      '${result.stdout}\n${result.stderr}'.trim(),
      result.exitCode,
    );
  }
  return result.stdout as String;
}

typedef SimulatorProcessRunner =
    Future<ProcessResult> Function(
      String executable,
      List<String> arguments, {
      required Duration timeout,
    });

/// Runs a simulator command without a shell, killing it if it times out.
Future<ProcessResult> runSimulatorProcess(
  String executable,
  List<String> arguments, {
  required Duration timeout,
}) async {
  final process = await Process.start(executable, arguments);
  final output = StringBuffer();
  final errors = StringBuffer();
  final outSubscription = process.stdout
      .transform(const Utf8Decoder(allowMalformed: true))
      .listen(output.write);
  final errSubscription = process.stderr
      .transform(const Utf8Decoder(allowMalformed: true))
      .listen(errors.write);
  try {
    final results = await Future.wait<Object?>([
      process.exitCode,
      process.stdin.close(),
      outSubscription.asFuture<void>(),
      errSubscription.asFuture<void>(),
    ]).timeout(timeout);
    return ProcessResult(
      process.pid,
      results.first as int,
      output.toString(),
      errors.toString(),
    );
  } on TimeoutException {
    process.kill(ProcessSignal.sigkill);
    try {
      await process.exitCode.timeout(const Duration(seconds: 5));
    } catch (_) {
      // Preserve the timeout if the process cannot be reaped.
    }
    throw TimeoutException(
      '$executable ${arguments.join(' ')} timed out.\n$output$errors',
      timeout,
    );
  } finally {
    await outSubscription.cancel();
    await errSubscription.cancel();
  }
}
