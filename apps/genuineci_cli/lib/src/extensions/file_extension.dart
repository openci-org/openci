import 'dart:io';

extension AtomicFileExtension on File {
  Future<void> writeAsStringAtomic(String content) async {
    final dir = parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final tempFile = File('$path.tmp.${DateTime.now().microsecondsSinceEpoch}');
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
