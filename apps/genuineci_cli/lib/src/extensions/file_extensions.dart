import 'dart:io';
import 'dart:math';

extension AtomicFileExtension on File {
  Future<void> writeAsStringAtomic(
    String content, {
    bool chmod600 = false,
  }) async {
    final dir = parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final random = Random();
    File? tempFile;
    while (tempFile == null) {
      final candidate = File(
        '$path.tmp.${DateTime.now().microsecondsSinceEpoch}.${random.nextInt(1 << 32)}',
      );
      try {
        await candidate.create(exclusive: true);
        tempFile = candidate;
      } on PathExistsException {
        // Collision occurred; retry with a new unique path.
      }
    }

    try {
      await tempFile.writeAsString(content, flush: true);
      if (chmod600 && !Platform.isWindows) {
        await Process.run('chmod', ['600', tempFile.path]);
        final result = await Process.run('chmod', ['600', tempFile.path]);
        if (result.exitCode != 0) {
          throw ProcessException(
            'chmod',
            ['600', tempFile.path],
            result.stderr.toString(),
            result.exitCode,
          );
        }
      }
      await tempFile.writeAsString(content, flush: true);
      await tempFile.rename(path);
      if (chmod600 && !Platform.isWindows) {
        await Process.run('chmod', ['600', path]);
        final result = await Process.run('chmod', ['600', path]);
        if (result.exitCode != 0) {
          throw ProcessException(
            'chmod',
            ['600', path],
            result.stderr.toString(),
            result.exitCode,
          );
        }
      }
    } catch (_) {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }
}
