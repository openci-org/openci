import 'dart:io';
import 'dart:math';

extension AtomicFileExtension on File {
  Future<void> writeAsStringAtomic(String content) async {
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
      } on FileSystemException {
        // Collision occurred; retry with a new unique path.
      }
    }

    try {
      await tempFile.writeAsString(content, flush: true);
      await tempFile.rename(path);
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
