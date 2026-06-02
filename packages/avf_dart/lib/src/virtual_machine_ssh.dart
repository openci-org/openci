import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';

class VirtualMachineSsh {
  /// Executes a [command] on the guest VM via SSH, streaming standard output
  /// and standard error to the optional [onStdout] and [onStderr] callbacks.
  ///
  /// Returns the exit code of the command when it finishes.
  static Future<int> executeStream(
    String command, {
    required String? ipAddress,
    String username = 'admin',
    String? password,
    String? privateKeyPath,
    int port = 22,
    void Function(String data)? onStdout,
    void Function(String data)? onStderr,
  }) async {
    if (ipAddress == null) {
      throw StateError(
          'Cannot execute SSH command because the VM does not have an allocated IP address. Ensure the VM is booted successfully.');
    }

    final List<SSHKeyPair>? keyPairs;
    if (privateKeyPath != null) {
      final keyFile = File(privateKeyPath);
      if (!keyFile.existsSync()) {
        throw FileSystemException('Private key file not found', privateKeyPath);
      }
      final pem = await keyFile.readAsString();
      keyPairs = SSHKeyPair.fromPem(pem);
    } else {
      keyPairs = null;
    }

    final socket = await SSHSocket.connect(ipAddress, port).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TimeoutException('SSH socket connection timed out'),
    );
    final client = SSHClient(
      socket,
      username: username,
      onPasswordRequest: password != null ? () => password : null,
      identities: keyPairs,
    );
    await client.authenticated.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        socket.destroy();
        throw TimeoutException('SSH authentication timed out');
      },
    );

    try {
      final session = await client.execute(command);

      StreamSubscription<String>? stdoutSub;
      StreamSubscription<String>? stderrSub;

      if (onStdout != null) {
        stdoutSub = session.stdout
            .cast<List<int>>()
            .transform(utf8.decoder)
            .listen(onStdout);
      }
      if (onStderr != null) {
        stderrSub = session.stderr
            .cast<List<int>>()
            .transform(utf8.decoder)
            .listen(onStderr);
      }

      await session.done;

      await stdoutSub?.cancel();
      await stderrSub?.cancel();

      return session.exitCode ?? -1;
    } finally {
      client.close();
      await client.done;
    }
  }
}
